#!/usr/bin/env bash
# Laptop: show the latest Studio Output that the Windows PC pushed to the separate night-shift-logs repo.
set -euo pipefail
cd "$(dirname "$0")/.."
repo="$(pwd)"
logs="${repo}-logs"
url="$(git remote get-url origin)"
url="${url%.git}-logs.git"
if [ ! -d "$logs/.git" ]; then
  git clone -q "$url" "$logs"
fi
git -C "$logs" fetch -q origin main
git -C "$logs" show origin/main:studio.log
