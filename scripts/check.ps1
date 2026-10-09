# Everything that can be verified without Roblox Studio. Same checks as CI.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"
New-Item -ItemType Directory -Force -Path build | Out-Null
selene generate-roblox-std
selene src tests; if ($LASTEXITCODE) { exit 1 }
stylua --check src tests; if ($LASTEXITCODE) { exit 1 }
lune run tests/run; if ($LASTEXITCODE) { exit 1 }
rojo build -o build/NightShift.rbxl; if ($LASTEXITCODE) { exit 1 }
Write-Host "ALL CHECKS PASSED"
