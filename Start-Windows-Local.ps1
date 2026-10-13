$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
Write-Host 'Offline mock sandbox. Real engine replay is available separately through WSL.'
Start-Process 'http://127.0.0.1:18080/doom-play/?relayer=http://127.0.0.1:18787'
node scripts/windows-local.mjs
