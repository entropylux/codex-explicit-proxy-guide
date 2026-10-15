[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$ProxyPort = 7890
)

$ErrorActionPreference = 'Stop'
$client = [System.Net.Sockets.TcpClient]::new()
try {
    $task = $client.ConnectAsync('127.0.0.1', $ProxyPort)
    if (-not $task.Wait(5000)) { throw 'Local proxy connection timed out.' }
    $task.GetAwaiter().GetResult()
} finally {
    $client.Dispose()
}

$codexDir = Join-Path $env:USERPROFILE '.codex'
$envFile = Join-Path $codexDir '.env'
$proxyUrl = "http://127.0.0.1:$ProxyPort"
New-Item -ItemType Directory -Path $codexDir -Force | Out-Null

$lines = @()
if (Test-Path -LiteralPath $envFile) {
    $backup = "$envFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
    Copy-Item -LiteralPath $envFile -Destination $backup -ErrorAction Stop
    Write-Host 'Existing configuration backed up beside the original file.'
    $lines = @(Get-Content -LiteralPath $envFile -Encoding UTF8 | Where-Object {
        $_ -notmatch '^\s*(HTTP_PROXY|HTTPS_PROXY|ALL_PROXY|NO_PROXY)\s*='
    })
}
$lines = @($lines) + @(
    "HTTP_PROXY=$proxyUrl"
    "HTTPS_PROXY=$proxyUrl"
    "ALL_PROXY=$proxyUrl"
    'NO_PROXY=localhost,127.0.0.1,::1'
)
[System.IO.File]::WriteAllText(
    $envFile,
    (($lines -join "`r`n") + "`r`n"),
    [System.Text.UTF8Encoding]::new($false)
)
Write-Host 'Codex proxy configuration saved. Fully quit and restart Codex.'
