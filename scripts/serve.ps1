# Pull the latest code and start the Rojo live-sync server for Roblox Studio.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"
git pull --ff-only
rojo serve
