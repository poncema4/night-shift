#!/usr/bin/env bash
# Everything that can be verified without Roblox Studio. Same checks as CI.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
mkdir -p build
selene src tests
stylua --check src tests
lune run tests/run
rojo build -o build/NightShift.rbxl
echo "ALL CHECKS PASSED"
