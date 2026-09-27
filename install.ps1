param([string]$Cs2CfgDir)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Cs2CfgDir) {
    $steamRoot = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steamRoot) { throw 'Steam nicht gefunden. Bitte -Cs2CfgDir angeben.' }
    $libraries = @($steamRoot)
    $libraryFile = Join-Path $steamRoot 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $libraryFile) {
        foreach ($line in (Get-Content -LiteralPath $libraryFile)) {
            if ($line -match '^\s*"path"\s+"([^"]+)"') {
                $libraries += $Matches[1].Replace('\\', '\')
            }
        }
    }
    foreach ($library in ($libraries | Select-Object -Unique)) {
        $candidate = Join-Path $library 'steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg'
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $Cs2CfgDir = $candidate
            break
        }
    }
}
if (-not (Test-Path -LiteralPath $Cs2CfgDir -PathType Container)) {
    throw 'CS2-Konfigurationsordner nicht gefunden. Bitte -Cs2CfgDir angeben.'
}

$configPath = Join-Path $projectDir 'config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    Copy-Item -LiteralPath (Join-Path $projectDir 'config.example.json') -Destination $configPath
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$port = [int]$config.port
if ($port -lt 1 -or $port -gt 65535) { throw 'Ungültiger Port in config.json' }

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
$target = Join-Path $Cs2CfgDir 'gamestate_integration_discord_presence.cfg'
Set-Content -LiteralPath $target -Value $gsi -Encoding ascii
Write-Host "GSI eingerichtet: $target"
Write-Host "Discord Application ID in $configPath eintragen, dann start.cmd ausführen."
Write-Host 'Falls CS2 schon läuft: Spiel neu starten.'
