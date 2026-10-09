# Windows PC: forward Studio's server Output to GitHub so Claude can read errors. Leave running while you playtest.
# Needs Studio > Home > Game Settings > Security > Allow HTTP Requests = ON (per place).
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$env:Path = "$env:USERPROFILE\.rokit\bin;$env:Path"
lune run tools/logserver
