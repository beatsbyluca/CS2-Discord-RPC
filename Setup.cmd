@echo off
setlocal
cd /d "%~dp0"
set "CS2_RPC_SETUP_FILE=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$source = Get-Content -LiteralPath $env:CS2_RPC_SETUP_FILE -Raw; $marker = '# ' + 'POWERSHELL_START'; $start = $source.LastIndexOf($marker); if ($start -lt 0) { throw 'Missing setup payload' }; & ([scriptblock]::Create($source.Substring($start + $marker.Length)))"
if errorlevel 1 (
    echo.
    echo Setup did not finish. Press any key to close this window.
    pause >nul
)
exit /b %errorlevel%
# POWERSHELL_START
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$projectDir = Split-Path -Parent $env:CS2_RPC_SETUP_FILE
$configPath = Join-Path $projectDir 'config.json'
$gsiFileName = 'gamestate_integration_discord_presence.cfg'
$defaultApplicationId = '1553835774737252462'
$defaultImageBaseUrl = 'https://raw.githubusercontent.com/beatsbyluca/CS2-Discord-RPC/refs/heads/main/assets'

function Show-Step([int]$number, [string]$title) {
    Write-Host ''
    Write-Host "[$number/4] $title" -ForegroundColor Cyan
    Write-Host ('-' * 56)
}

function Read-YesNo([string]$prompt, [bool]$defaultYes = $true) {
    $suffix = if ($defaultYes) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = (Read-Host "$prompt $suffix").Trim().ToLowerInvariant()
        if (-not $answer) { return $defaultYes }
        if ($answer -in @('y', 'yes')) { return $true }
        if ($answer -in @('n', 'no')) { return $false }
        Write-Host 'Please enter Y or N.' -ForegroundColor Yellow
    }
}

function Find-Node {
    $runtimeNode = Join-Path $projectDir 'runtime\node.exe'
    $candidates = @($runtimeNode)
    $systemNode = Get-Command node.exe -ErrorAction SilentlyContinue
    if ($systemNode) { $candidates += $systemNode.Source }
    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try {
            $version = (& $candidate --version 2>$null).Trim()
            if ($version -match '^v(\d+)\.' -and [int]$Matches[1] -ge 18) {
                return [pscustomobject]@{ Path = $candidate; Version = $version }
            }
        } catch { }
    }
    return $null
}

function Install-PortableNode {
    $runtimeDir = Join-Path $projectDir 'runtime'
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    $zipPath = Join-Path $runtimeDir 'node-download.zip'
    $nodePath = Join-Path $runtimeDir 'node.exe'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Host 'Finding the current Node.js LTS release...'
    $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
    $release = $releases | Where-Object { $_.lts -and $_.files -contains 'win-x64-zip' } | Select-Object -First 1
    if (-not $release) { throw 'Could not find a Windows x64 Node.js LTS release.' }
    $archiveName = "node-$($release.version)-win-x64.zip"
    $baseUrl = "https://nodejs.org/dist/$($release.version)"
    Write-Host "Downloading Node.js $($release.version) from nodejs.org..."
    try {
        $checksums = (Invoke-WebRequest -Uri "$baseUrl/SHASUMS256.txt" -UseBasicParsing).Content
        $pattern = '^([a-fA-F0-9]{64})\s+' + [regex]::Escape($archiveName) + '$'
        $expected = $null
        foreach ($line in ($checksums -split "`n")) {
            if ($line.Trim() -match $pattern) { $expected = $Matches[1].ToLowerInvariant(); break }
        }
        if (-not $expected) { throw 'The Node.js release checksum is missing.' }
        Invoke-WebRequest -Uri "$baseUrl/$archiveName" -OutFile $zipPath -UseBasicParsing
        $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected) { throw 'The Node.js download failed its SHA-256 check.' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $entry = $archive.Entries | Where-Object { $_.FullName -eq "node-$($release.version)-win-x64/node.exe" } | Select-Object -First 1
            if (-not $entry) { throw 'node.exe is missing from the downloaded archive.' }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $nodePath, $true)
        } finally {
            $archive.Dispose()
        }
    } finally {
        if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    }
    return $nodePath
}

function Find-Cs2ConfigDirectories {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { return @() }
    $libraries = @($steam)
    $libraryFile = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $libraryFile) {
        foreach ($line in (Get-Content -LiteralPath $libraryFile)) {
            if ($line -match '^\s*"path"\s+"([^"]+)"') {
                $libraries += $Matches[1].Replace('\\', '\')
            }
        }
    }
    $found = @()
    foreach ($library in ($libraries | Select-Object -Unique)) {
        $candidate = Join-Path $library 'steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg'
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $found += (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $found
}

try {
    Clear-Host
    Write-Host 'CS2 Discord RPC Setup' -ForegroundColor Green
    Write-Host 'This wizard sets up CS2, Discord Rich Presence, and a desktop shortcut.'
    Write-Host "Project folder: $projectDir"

    Show-Step 1 'Check Node.js'
    $node = Find-Node
    if ($node) {
        Write-Host "Found Node.js $($node.Version) at $($node.Path)"
    } else {
        Write-Host 'Node.js 18 or newer is not installed.'
        Write-Host 'Setup can download a portable LTS copy from nodejs.org into this folder.'
    }

    Show-Step 2 'Find Counter-Strike 2'
    $candidates = @(Find-Cs2ConfigDirectories)
    $cs2CfgDir = $null
    if ($candidates.Count -gt 0) {
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            Write-Host "  $($i + 1). $($candidates[$i])"
        }
        while (-not $cs2CfgDir) {
            $choice = (Read-Host 'Choose a number, or M to enter a path manually [1]').Trim()
            if (-not $choice) { $choice = '1' }
            if ($choice -match '^[mM]$') { break }
            $selected = 0
            if ([int]::TryParse($choice, [ref]$selected) -and $selected -ge 1 -and $selected -le $candidates.Count) {
                $cs2CfgDir = $candidates[$selected - 1]
            } else { Write-Host 'Choose one of the listed numbers or M.' -ForegroundColor Yellow }
        }
    }
    while (-not $cs2CfgDir) {
        $manual = (Read-Host 'Enter the full path to the CS2 game\csgo\cfg folder').Trim().Trim('"')
        if (Test-Path -LiteralPath $manual -PathType Container) {
            $cs2CfgDir = (Resolve-Path -LiteralPath $manual).Path
        } else { Write-Host 'That folder does not exist. Try again.' -ForegroundColor Yellow }
    }

    Show-Step 3 'Choose the Discord Application ID'
    $existingConfig = $null
    if (Test-Path -LiteralPath $configPath) {
        try { $existingConfig = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json } catch { }
    }
    $suggestedId = if ([string]$existingConfig.discordApplicationId -match '^\d{17,20}$') {
        [string]$existingConfig.discordApplicationId
    } else { $defaultApplicationId }
    Write-Host 'Press Enter to use the shared CS2 Discord RPC application.'
    Write-Host 'You can enter your own Application ID if you prefer a different activity name.'
    $applicationId = $null
    while (-not $applicationId) {
        $entered = (Read-Host "Application ID [$suggestedId]").Trim()
        if (-not $entered) { $entered = $suggestedId }
        if ($entered -match '^\d{17,20}$') { $applicationId = $entered }
        else { Write-Host 'An Application ID must contain 17 to 20 digits.' -ForegroundColor Yellow }
    }

    Show-Step 4 'Review and install'
    Write-Host "CS2 config: $cs2CfgDir"
    Write-Host "Discord Application ID: $applicationId"
    Write-Host "Node.js: $(if ($node) { $node.Path } else { 'Download portable LTS from nodejs.org' })"
    Write-Host "Log folder: $(Join-Path $projectDir 'logs')"
    if (-not (Read-YesNo 'Install now?')) { Write-Host 'Setup cancelled.'; exit 0 }

    if (-not $node) {
        $nodePath = Install-PortableNode
        $node = Find-Node
        if (-not $node) { throw "Downloaded Node.js could not start: $nodePath" }
    }
    $port = if ($existingConfig -and [int]$existingConfig.port -ge 1 -and [int]$existingConfig.port -le 65535) {
        [int]$existingConfig.port
    } else { 31982 }
    $config = [ordered]@{
        discordApplicationId = $applicationId
        port = $port
        imageBaseUrl = $defaultImageBaseUrl
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json -Depth 3) + [Environment]::NewLine, $utf8)
    $logsDir = Join-Path $projectDir 'logs'
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    $gsi = @"
"CS2 Discord Presence"
{
    "uri" "http://127.0.0.1:$port/"
    "timeout" "5.0"
    "buffer" "0.1"
    "throttle" "1.0"
    "heartbeat" "30.0"
    "data"
    {
        "map" "1"
        "player_id" "1"
    }
}
"@
    $gsiPath = Join-Path $cs2CfgDir $gsiFileName
    [System.IO.File]::WriteAllText($gsiPath, $gsi, (New-Object System.Text.ASCIIEncoding))
    if (Read-YesNo 'Create a desktop shortcut?') {
        $shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'CS2 Discord RPC.lnk'
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $projectDir 'start.cmd'
        $shortcut.WorkingDirectory = $projectDir
        $shortcut.IconLocation = Join-Path $projectDir 'assets\tray.ico'
        $shortcut.Description = 'Start CS2 Discord RPC'
        $shortcut.Save()
        Write-Host "Shortcut created: $shortcutPath"
    }
    Write-Host ''
    Write-Host 'Setup complete.' -ForegroundColor Green
    Write-Host 'Restart CS2 if it is already open, then double-click start.cmd or the desktop shortcut.'
    Write-Host "Logs will be written to $logsDir"
} catch {
    Write-Host ''
    Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
