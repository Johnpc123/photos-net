#!/bin/bash
# Double-clickable launcher for macOS family members.
# Opens Terminal and runs bin/photos-setup.sh.
cd "$(dirname "$0")"
bash bin/photos-setup.sh "$@"
echo
read -rp "Press Enter to close..."
