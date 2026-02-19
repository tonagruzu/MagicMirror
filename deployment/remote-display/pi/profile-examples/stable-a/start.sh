#!/usr/bin/env bash
set -euo pipefail

# Stable-A: current Raspberry Pi local MagicMirror runtime
MM_LOCAL_PATH="${MM_LOCAL_PATH:-/home/pi/MagicMirror}"

cd "${MM_LOCAL_PATH}"
npm run start:x11
