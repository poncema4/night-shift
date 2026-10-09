#!/usr/bin/env bash
# Start the Rojo live-sync server (use on the machine that runs Roblox Studio).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
git pull --ff-only
exec rojo serve
