$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$projectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$nodeExe = Join-Path $projectDir 'runtime\node.exe'
if (-not (Test-Path -LiteralPath $nodeExe -PathType Leaf)) {
    $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($nodeCommand) { $nodeExe = $nodeCommand.Source }
}
if (-not (Test-Path -LiteralPath $nodeExe -PathType Leaf)) {
    [System.Windows.Forms.MessageBox]::Show('Node.js is missing. Install Node.js 18 or newer to run CS2 Discord RPC.', 'CS2 Discord RPC') | Out-Null
    exit 1
}

$created = $false
$mutex = [System.Threading.Mutex]::new($true, 'Local\CS2DiscordRpcTray', [ref]$created)
if (-not $created) {
    $mutex.Dispose()
    exit 0
}

$logsDir = Join-Path $projectDir 'logs'
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
$script:rpcProcess = $null
$script:trayToken = ''
$script:stopping = $false

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = New-Object System.Drawing.Icon((Join-Path $projectDir 'assets\tray.ico'))
$tray.Text = 'CS2 Discord RPC'
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$statusItem = $menu.Items.Add('Starting RPC...')
$statusItem.Enabled = $false
$restartItem = $menu.Items.Add('Restart RPC')
$logsItem = $menu.Items.Add('Open logs')
$null = $menu.Items.Add('-')
$exitItem = $menu.Items.Add('Exit')
$tray.ContextMenuStrip = $menu
$context = New-Object System.Windows.Forms.ApplicationContext

function Start-Rpc {
    if ($script:rpcProcess -and -not $script:rpcProcess.HasExited) { return }
    $script:trayToken = [guid]::NewGuid().ToString('N')
    $env:CS2_RPC_TRAY_TOKEN = $script:trayToken
    try {
        $script:rpcProcess = Start-Process -FilePath $nodeExe -ArgumentList 'src\main.js' `
            -WorkingDirectory $projectDir -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $logsDir 'app.log') `
            -RedirectStandardError (Join-Path $logsDir 'error.log')
        $statusItem.Text = 'RPC running'
        $tray.Text = 'CS2 Discord RPC - running'
    } catch {
        $statusItem.Text = 'RPC failed to start'
        $tray.Text = 'CS2 Discord RPC - stopped'
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'CS2 Discord RPC') | Out-Null
    } finally {
        Remove-Item Env:CS2_RPC_TRAY_TOKEN -ErrorAction SilentlyContinue
    }
}

function Stop-Rpc {
    if (-not $script:rpcProcess -or $script:rpcProcess.HasExited) { return }
    try {
        $port = 31982
        $configPath = Join-Path $projectDir 'config.json'
        if (Test-Path -LiteralPath $configPath) {
            $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            if ($config.port) { $port = [int]$config.port }
        }
        Invoke-WebRequest -UseBasicParsing -Method Post -Uri "http://127.0.0.1:$port/quit" `
            -Headers @{ 'X-Tray-Token' = $script:trayToken } -TimeoutSec 2 | Out-Null
    } catch { }
    if (-not $script:rpcProcess.WaitForExit(3000)) {
        Stop-Process -Id $script:rpcProcess.Id -Force -ErrorAction SilentlyContinue
        $script:rpcProcess.WaitForExit(1000) | Out-Null
    }
}

$restartItem.add_Click({
    Stop-Rpc
    Start-Rpc
})
$logsItem.add_Click({ Invoke-Item -LiteralPath $logsDir })
$exitItem.add_Click({
    $script:stopping = $true
    $context.ExitThread()
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000
$timer.add_Tick({
    if (-not $script:stopping -and $script:rpcProcess -and $script:rpcProcess.HasExited) {
        $statusItem.Text = 'RPC stopped'
        $tray.Text = 'CS2 Discord RPC - stopped'
    }
})

try {
    Start-Rpc
    $tray.Visible = $true
    $timer.Start()
    [System.Windows.Forms.Application]::Run($context)
} finally {
    $timer.Stop()
    Stop-Rpc
    $tray.Visible = $false
    $timer.Dispose()
    $tray.Dispose()
    $menu.Dispose()
    $context.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
