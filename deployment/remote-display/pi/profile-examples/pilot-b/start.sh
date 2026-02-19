#!/usr/bin/env bash
set -euo pipefail

# Pilot-B: Raspberry Pi as display-only Chromium kiosk for Windows-hosted MagicMirror
MM_HOST_URL="${MM_HOST_URL:-http://192.168.1.10:8080}"

/usr/bin/chromium-browser \
  --kiosk \
  --incognito \
  --check-for-update-interval=31536000 \
  --disable-features=TranslateUI \
  --noerrdialogs \
  --disable-session-crashed-bubble \
  --overscroll-history-navigation=0 \
  "${MM_HOST_URL}"
