#!/usr/bin/env bash
# photos-setup.sh — one-shot installer for photos-net (Linux / macOS)
#
# Usage:
#   bash photos-setup.sh [--name <member-name>]
#   curl -fsSL <url>/photos-setup.sh | bash
#
# What it does:
#   1. Installs Syncthing via the native package manager
#   2. Creates ~/photos/<you>/ and ~/photos/network/ with the roster
#   3. Starts Syncthing as a user service (autostart, survives reboots)
#   4. Declares your folders via the Syncthing API
#   5. Installs the PiGallery2 gallery (container preferred, npm fallback)
#   6. Prints your device ID (and a QR code if qrencode is available)
#
# After it finishes: send your device ID to any existing member.
# They click "accept" once, the roster does the rest.

set -euo pipefail

MEMBER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name) MEMBER="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

OS="$(uname -s)"
case "$OS" in Linux|Darwin) ;; *) die "unsupported OS: $OS (use photos-setup.ps1 on Windows)" ;; esac

# ---------- member name ----------
if [ -z "$MEMBER" ]; then
  MEMBER="${USER:-$(hostname -s 2>/dev/null || hostname)}"
fi
MEMBER="$(printf '%s' "$MEMBER" | tr 'A-Z ' 'a-z-' | tr -cd 'a-z0-9-')"
[ -n "$MEMBER" ] || die "could not derive a member name — pass --name"
say "member name: $MEMBER"

PHOTOS_DIR="$HOME/photos"
ENV_DIR="$HOME/.config/photos-net"
mkdir -p "$ENV_DIR"
printf 'MEMBER=%s\nPHOTOS_DIR=%s\n' "$MEMBER" "$PHOTOS_DIR" > "$ENV_DIR/env"

# ---------- 1. install syncthing ----------
if command -v syncthing >/dev/null 2>&1; then
  say "syncthing already installed ($(syncthing --version 2>/dev/null | head -1 | awk '{print $2}'))"
else
  say "installing syncthing"
  if [ "$OS" = Linux ]; then
    if   command -v dnf    >/dev/null; then sudo dnf install -y syncthing
    elif command -v apt    >/dev/null; then sudo apt install -y syncthing
    elif command -v pacman >/dev/null; then sudo pacman -S --noconfirm syncthing
    elif command -v zypper >/dev/null; then sudo zypper install -y syncthing
    else die "no supported package manager found — install syncthing manually" ; fi
  else
    command -v brew >/dev/null || die "install Homebrew first: https://brew.sh"
    brew install syncthing
  fi
fi

# ---------- 2. folder layout ----------
mkdir -p "$PHOTOS_DIR/$MEMBER" "$PHOTOS_DIR/network"
if [ ! -f "$PHOTOS_DIR/network/members.txt" ]; then
  printf '# photos-net roster — <name> <device-id>\n' > "$PHOTOS_DIR/network/members.txt"
fi

# ---------- 3. start syncthing ----------
if [ "$OS" = Linux ]; then
  if ! systemctl --user is-active --quiet syncthing 2>/dev/null; then
    systemctl --user enable --now syncthing
  fi
  sudo loginctl enable-linger "$USER" 2>/dev/null || true
else
  brew services start syncthing >/dev/null 2>&1 || true
fi

# ---------- 4. wait for API, read identity ----------
if [ "$OS" = Linux ]; then ST_HOME="$HOME/.local/state/syncthing"; else ST_HOME="$HOME/Library/Application Support/Syncthing"; fi
CFG="$ST_HOME/config.xml"
for i in $(seq 1 30); do [ -f "$CFG" ] && break; sleep 1; done
[ -f "$CFG" ] || die "syncthing config not found at $CFG"

DEVICE_ID="$(grep -oP '(?<=<device id=")[^"]+' "$CFG" | head -1)"
API_KEY="$(grep -oP '(?<=<apikey>)[^<]+' "$CFG" | head -1)"
API="http://127.0.0.1:8384/rest"
printf 'DEVICE_ID=%s\nAPI_KEY=%s\nAPI=%s\n' "$DEVICE_ID" "$API_KEY" "$API" >> "$ENV_DIR/env"
chmod 600 "$ENV_DIR/env"

st() { curl -sf -H "X-API-Key: $API_KEY" "$@"; }
st_post() { st -X POST -H 'Content-Type: application/json' "$@"; }

# ---------- 5. declare folders ----------
mkfolder() { # id path type
  st_post "$API/config/folders" -d "{\"id\":\"$1\",\"label\":\"$1\",\"path\":\"$2\",\"type\":\"$3\",\"fsWatcherEnabled\":true,\"rescanIntervalS\":60,\"versioning\":{\"type\":\"simple\",\"params\":{\"keep\":\"3\"}},\"devices\":[{\"deviceID\":\"$DEVICE_ID\"}]}" >/dev/null
}
st "$API/config/folders/photos-$MEMBER" >/dev/null 2>&1 || mkfolder "photos-$MEMBER" "$PHOTOS_DIR/$MEMBER" sendreceive
st "$API/config/folders/network"        >/dev/null 2>&1 || mkfolder "network"        "$PHOTOS_DIR/network"  sendreceive
say "folders declared: photos-$MEMBER (yours), network (roster)"

# ---------- 6. gallery ----------
GALLERY_PORT=8089
if command -v podman >/dev/null 2>&1; then
  say "installing PiGallery2 (podman)"
  podman rm -f pigallery2 >/dev/null 2>&1 || true
  podman run -d --name pigallery2 -p "$GALLERY_PORT":80 \
    -v "$PHOTOS_DIR":/app/data/images:ro \
    -v pigallery2-config:/app/data/config \
    -v pigallery2-db:/app/data/db \
    --restart unless-stopped \
    docker.io/bpatrik/pigallery2:3.5.2 >/dev/null
elif command -v docker >/dev/null 2>&1; then
  say "installing PiGallery2 (docker)"
  docker rm -f pigallery2 >/dev/null 2>&1 || true
  docker run -d --name pigallery2 -p "$GALLERY_PORT":80 \
    -v "$PHOTOS_DIR":/app/data/images:ro \
    -v pigallery2-config:/app/data/config \
    -v pigallery2-db:/app/data/db \
    --restart unless-stopped \
    bpatrik/pigallery2:3.5.2 >/dev/null
elif command -v npm >/dev/null 2>&1; then
  say "installing PiGallery2 (npm)"
  npm install -g pigallery2
  warn "start it with:  pigallery2 --config-path=$ENV_DIR/pigallery2.json  (see docs/)"
else
  warn "no podman/docker/npm found — gallery skipped; install one and re-run, or just use Syncthing alone"
fi

# ---------- 7. identity out ----------
echo
say "DONE. Your device ID — send this to any existing member in the group chat:"
echo
printf '    %s\n' "$DEVICE_ID"
echo
if command -v qrencode >/dev/null 2>&1; then qrencode -t ANSIUTF8 "$DEVICE_ID"; fi
say "gallery: http://localhost:$GALLERY_PORT   syncthing gui: http://localhost:8384"
say "once a member accepts you, their photos will appear under $PHOTOS_DIR/<name>/"
