$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $projectDir 'dist'
$payloadPath = Join-Path $distDir 'payload.zip'
$installerPath = Join-Path $distDir 'CS2-Discord-RPC-Setup.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw 'The Windows .NET Framework C# compiler was not found.'
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null
$payloadFiles = @(
    (Join-Path $projectDir 'assets'),
    (Join-Path $projectDir 'src'),
    (Join-Path $projectDir 'Setup.cmd'),
    (Join-Path $projectDir 'start.cmd'),
    (Join-Path $projectDir 'README.md'),
    (Join-Path $projectDir 'package.json')
)
foreach ($file in $payloadFiles) {
    if (-not (Test-Path -LiteralPath $file)) { throw "Missing payload item: $file" }
}

try {
    Compress-Archive -LiteralPath $payloadFiles -DestinationPath $payloadPath -CompressionLevel Optimal -Force
    & $compiler /nologo /target:exe /platform:anycpu "/out:$installerPath" "/resource:$payloadPath,Payload.zip" /reference:System.IO.Compression.dll (Join-Path $projectDir 'Installer.cs')
    if ($LASTEXITCODE -ne 0) { throw "C# compilation failed with exit code $LASTEXITCODE" }
} finally {
    if (Test-Path -LiteralPath $payloadPath) { Remove-Item -LiteralPath $payloadPath -Force }
}

$hash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash
Write-Host "Built: $installerPath"
Write-Host "SHA-256: $hash"
