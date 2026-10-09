#!/usr/bin/env bash
# Laptop: show the latest Studio Output that the Windows PC pushed.
set -euo pipefail
cd "$(dirname "$0")/.."
git fetch -q origin studio-logs
git show origin/studio-logs:studio.log
