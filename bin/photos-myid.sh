#!/usr/bin/env bash
# photos-myid — show your device ID (and a QR code if qrencode is installed)
. "$HOME/.config/photos-net/env" 2>/dev/null || { echo "run photos-setup.sh first"; exit 1; }
echo "$DEVICE_ID"
command -v qrencode >/dev/null 2>&1 && qrencode -t ANSIUTF8 "$DEVICE_ID" || true
