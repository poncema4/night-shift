#!/usr/bin/env bash
# Same as logs.ps1, for a Linux/macOS machine that runs Studio (rare) or for testing the listener.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
exec lune run tools/logserver
