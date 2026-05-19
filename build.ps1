$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
dub build --build=release
dub run --config=struct-test --build=release
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'scripts\test-all.ps1')
