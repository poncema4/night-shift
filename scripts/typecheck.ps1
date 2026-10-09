# Type-check all game code against Roblox's real API (catches wrong property/method names without opening Studio).
# Untested on Windows by Claude (written on Linux): if it fails, paste the error.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$types = Join-Path $env:USERPROFILE "tools\globalTypes.d.luau"
if (-not (Test-Path $types)) {
  New-Item -ItemType Directory -Force (Split-Path $types) | Out-Null
  Invoke-WebRequest "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau" -OutFile $types
}
rojo sourcemap default.project.json -o sourcemap.json | Out-Null
$out = luau-lsp analyze --definitions=$types --sourcemap=sourcemap.json src 2>&1 | Where-Object { $_ -notmatch '^\[(INFO|WARN)\]' }
$out | ForEach-Object { Write-Host $_ }
if ($out -match "TypeError|SyntaxError") { exit 1 }
