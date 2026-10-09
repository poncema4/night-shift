#!/usr/bin/env bash
# Run a Blender script headless: scripts/blender.sh art/blender/armchair.py
# Blender is a portable install in ~/tools (no sudo). Override with BLENDER=/path/to/blender.
set -euo pipefail
BLENDER="${BLENDER:-$HOME/tools/blender-4.5.14-linux-x64/blender}"
[ -x "$BLENDER" ] || { echo "Blender not found at $BLENDER (see art/README.md)"; exit 1; }
exec "$BLENDER" -b -P "$1"
