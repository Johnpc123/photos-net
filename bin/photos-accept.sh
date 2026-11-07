#!/usr/bin/env bash
# photos-accept — the existing member's one-step "let them in".
# Accepts every pending device, then shares ALL our folders with them.
# Run it when someone new posts their ID / you see the connect prompt.
#
# Usage: photos-accept [--watch]   (--watch keeps running, accepts as they arrive)

set -euo pipefail
. "$HOME/.config/photos-net/env" 2>/dev/null || { echo "run photos-setup.sh first"; exit 1; }

st()  { curl -sf -H "X-API-Key: $API_KEY" "$@"; }
stp() { st -X POST -H 'Content-Type: application/json' "$@"; }
stx() { st -X PATCH -H 'Content-Type: application/json' "$@"; }

accept_pending() {
  ids="$(st "$API/cluster/pending/devices" | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin).keys()))' 2>/dev/null)"
  [ -n "$ids" ] || return 0
  for dev in $ids; do
    stp "$API/config/devices" -d "{\"deviceID\":\"$dev\",\"addresses\":[\"dynamic\"]}" >/dev/null
    echo "accepted device ${dev:0:7}…"
  done
  share_all "$ids"
}

share_all() { # add new devices to every folder we participate in
  for dev in $1; do
    for f in $(st "$API/config/folders" | python3 -c 'import json,sys; print(" ".join(x["id"] for x in json.load(sys.stdin)))' 2>/dev/null); do
      devs="$(st "$API/config/folders/$f" | python3 -c 'import json,sys; d=json.load(sys.stdin); ds=[x["deviceID"] for x in d["devices"]]; ds.append("'$dev'") if "'$dev'" not in ds else None; import json as j; print(j.dumps([{"deviceID":x} for x in ds]))' 2>/dev/null)"
      [ -n "$devs" ] && [ "$devs" != "null" ] && stx "$API/config/folders/$f" -d "{\"devices\":$devs}" >/dev/null && echo "shared $f -> ${dev:0:7}…"
    done
  done
}

accept_pending
if [ "${1:-}" = "--watch" ]; then
  echo "watching for new devices…"
  while sleep 15; do accept_pending; done
else
  echo "done. (re-run anytime, or 'photos-accept --watch' to auto-accept)"
fi
