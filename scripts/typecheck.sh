#!/usr/bin/env bash
# Type-check all game code against Roblox's real API (catches wrong property/method names without opening Studio).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
types="${GLOBAL_TYPES:-$HOME/tools/globalTypes.d.luau}"
if [ ! -f "$types" ]; then
  mkdir -p "$(dirname "$types")"
  curl -sSL -o "$types" https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi
rojo sourcemap default.project.json -o sourcemap.json >/dev/null
luau-lsp analyze --definitions="$types" --sourcemap=sourcemap.json --ignore '**/Packages/**' src 2>&1 | grep -v "^\[INFO\]\|^\[WARN\]" | tee /tmp/typecheck.out
! grep -q "TypeError\|SyntaxError" /tmp/typecheck.out
