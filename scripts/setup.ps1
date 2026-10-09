# One-time setup on Windows (PowerShell): installs Rokit if missing, every tool in rokit.toml, and the Rojo Studio plugin.
# Run from the repo folder:  powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"

if (-not (Get-Command rokit -ErrorAction SilentlyContinue)) {
	Write-Host "==> Installing Rokit"
	Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
	$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"
}

Write-Host "==> Trusting and installing tools from rokit.toml"
rokit trust rojo-rbx/rojo lune-org/lune Kampfkarren/selene JohnnyMorganz/StyLua UpliftGames/wally Sleitnick/rbxcloud
rokit install

Write-Host "==> Installing the Rojo plugin into Roblox Studio (close Studio first)"
rojo plugin install

New-Item -ItemType Directory -Force -Path build | Out-Null
Write-Host ""
Write-Host "Done. Open a NEW PowerShell window, then run: scripts\serve.ps1"
Write-Host "In Studio: open a Baseplate, Plugins > Rojo > Connect."
