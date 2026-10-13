[CmdletBinding()]
param(
    [string]$EngineDirectory = "$env:USERPROFILE\Documents\DoomSol\Repositories\Browser-engine-and-deterministic-teacher\build-agent",
    [int]$Port = 18081
)
$ErrorActionPreference = 'Stop'
foreach ($name in @('index.html', 'index.js', 'index.wasm', 'index.data')) {
    if (-not (Test-Path -LiteralPath (Join-Path $EngineDirectory $name))) {
        throw "Missing $name. Supply -EngineDirectory pointing to your existing Dwasm browser build."
    }
}
Write-Host 'Real local Doom / FreeDoom gameplay. No blockchain connection.'
Write-Host 'Click the game to focus. Arrow keys move/turn, Ctrl fires, Space opens doors, Esc opens the menu.'
$url = "http://127.0.0.1:$Port/index.html?-warp&1&1&-skill&3"
Write-Host "Open: $url"
Write-Host 'If this port is already running, open the URL above. Otherwise keep this window open; Ctrl+C stops the server.'
node (Join-Path $PSScriptRoot 'scripts/play-local.mjs') $EngineDirectory $Port
