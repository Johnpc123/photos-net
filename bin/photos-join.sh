#!/usr/bin/env bash
# photos-join — join photos-net via one bootstrap peer ID.
# Adds the peer, waits for the 'network' roster folder offer, accepts it,
# then imports every device listed in members.txt.
#
# Usage: photos-join [<bootstrap-device-id>]
#        (prompts if not given; run photos-setup.sh first)

set -euo pipefail
. "$HOME/.config/photos-net/env" 2>/dev/null || { echo "run photos-setup.sh first"; exit 1; }

st()  { curl -sf -H "X-API-Key: $API_KEY" "$@"; }
stp() { st -X POST -H 'Content-Type: application/json' "$@"; }

BOOT="${1:-}"
[ -z "$BOOT" ] && read -rp "paste an existing member's device ID: " BOOT
[ -n "$BOOT" ] || { echo "no ID given"; exit 1; }

echo "adding bootstrap peer ${BOOT:0:7}…"
stp "$API/config/devices" -d "{\"deviceID\":\"$BOOT\",\"addresses\":[\"dynamic\"]}" >/dev/null

echo "waiting for the 'network' folder offer (the other member must accept you)…"
for i in $(seq 1 120); do
  st "$API/cluster/pending/folders" | grep -q '"network"' && break
  sleep 2
done
st "$API/cluster/pending/folders" | grep -q '"network"' || { echo "timed out — is the other member online and did they accept?"; exit 1; }

mkdir -p "$PHOTOS_DIR/network"
stp "$API/config/folders" -d "{\"id\":\"network\",\"label\":\"network\",\"path\":\"$PHOTOS_DIR/network\",\"type\":\"sendreceive\",\"fsWatcherEnabled\":true,\"rescanIntervalS\":30,\"devices\":[{\"deviceID\":\"$BOOT\"},{\"deviceID\":\"$DEVICE_ID\"}]}" >/dev/null

echo "waiting for members.txt to sync…"
for i in $(seq 1 60); do [ -s "$PHOTOS_DIR/network/members.txt" ] && break; sleep 2; done
[ -s "$PHOTOS_DIR/network/members.txt" ] || { echo "roster hasn't synced yet — check back shortly"; exit 1; }

# import every roster device we don't already know
added=0
while read -r name dev _; do
  case "$name" in ''|\#*) continue ;; esac
  [ "$dev" = "$DEVICE_ID" ] && continue
  st "$API/config/devices/$dev" >/dev/null 2>&1 && continue
  stp "$API/config/devices" -d "{\"deviceID\":\"$dev\",\"name\":\"$name\",\"addresses\":[\"dynamic\"]}" >/dev/null
  echo "added member device: $name"
  added=$((added+1))
done < "$PHOTOS_DIR/network/members.txt"

# append our own line to the roster if missing
grep -q "$DEVICE_ID" "$PHOTOS_DIR/network/members.txt" || echo "$MEMBER $DEVICE_ID" >> "$PHOTOS_DIR/network/members.txt"

echo
echo "join requested. Each existing member will now get one 'accept device' prompt."
echo "When they accept, their photo folders arrive under $PHOTOS_DIR/ — accept any"
echo "remaining folder offers in the Syncthing GUI (http://localhost:8384) as"
echo "RECEIVE ONLY, or just re-run this script after the offers appear."
echo "added $added member device(s) from the roster."
