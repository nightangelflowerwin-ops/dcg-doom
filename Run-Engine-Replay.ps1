$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$linuxRoot = (wsl wslpath -a $PSScriptRoot).Trim()
if ($LASTEXITCODE -ne 0) { throw 'WSL could not translate the checkout path.' }
Write-Host 'Running the real Doom engine for 35 ticks in WSL (headless replay).'
$command = 'cd "$1" && mkdir -p out/local && .cache/doom-scratch/doom-src/linuxdoom-1.10/doom-headless -headless -iwad .cache/doom-scratch/doom-wad/share/doom/doom1.wad -demo DEMO1 --max-tics 35 -frames out/local/frames.jsonl -state-hashes out/local/state-hashes.jsonl'
wsl -e sh -c $command replay $linuxRoot
if ($LASTEXITCODE -ne 0) { throw 'Engine replay failed. See WINDOWS-LOCAL.md for the build step.' }
Write-Host 'Replay completed. Results: out/local/frames.jsonl and out/local/state-hashes.jsonl'
