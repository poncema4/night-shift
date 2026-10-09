#!/usr/bin/env bash
# One-time setup on Linux/macOS: installs Rokit (if missing) and every tool in rokit.toml.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"

if ! command -v rokit >/dev/null 2>&1; then
	echo "==> Installing Rokit"
	curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
	export PATH="$HOME/.rokit/bin:$PATH"
fi

echo "==> Trusting and installing tools from rokit.toml"
rokit trust rojo-rbx/rojo lune-org/lune Kampfkarren/selene JohnnyMorganz/StyLua UpliftGames/wally Sleitnick/rbxcloud
rokit install

echo "==> Generating the Roblox standard library for the linter"
selene generate-roblox-std

mkdir -p build
echo
echo "Done. Add this to your shell profile if 'rojo' is not found in new terminals:"
echo '  export PATH="$HOME/.rokit/bin:$PATH"'
echo "Next: scripts/check.sh to verify, scripts/serve.sh to sync with Studio."
