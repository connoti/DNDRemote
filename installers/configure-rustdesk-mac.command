#!/bin/zsh
# DirectNorth Remote Access — macOS configuration helper
# Downloads the official RustDesk app, installs it, and configures it.

set -euo pipefail

KEY="${RUSTDESK_SERVER_KEY:-}"
if [[ -z "$KEY" ]]; then
  read -rs 'KEY?Enter the DirectNorth RustDesk server key: '
  print
fi
if [[ ! "$KEY" =~ '^[A-Za-z0-9+/]{43}=$' ]]; then
  print -u2 'Expected a base64-encoded RustDesk server public key.'
  exit 2
fi

VERSION="1.4.9"
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  ASSET="rustdesk-${VERSION}-aarch64.dmg"
else
  ASSET="rustdesk-${VERSION}-x86_64.dmg"
fi

if [[ ! -d "/Applications/RustDesk.app" ]]; then
  WORK_DIR="$(mktemp -d)"
  DMG="$WORK_DIR/$ASSET"
  MOUNT="$WORK_DIR/mount"
  mkdir -p "$MOUNT"
  curl -fL "https://github.com/rustdesk/rustdesk/releases/download/${VERSION}/${ASSET}" -o "$DMG"
  hdiutil attach "$DMG" -nobrowse -mountpoint "$MOUNT" >/dev/null
  osascript -e "do shell script \"/usr/bin/ditto '$MOUNT/RustDesk.app' '/Applications/RustDesk.app'\" with administrator privileges"
  hdiutil detach "$MOUNT" -quiet
  rm -rf "$WORK_DIR"
fi

osascript -e 'tell application "RustDesk" to quit' >/dev/null 2>&1 || true
sleep 2

CONFIG_DIR="$HOME/Library/Preferences/com.carriez.RustDesk"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/RustDesk2.toml" <<EOF
rendezvous_server = 'remote.directnorth.digital:21116'
nat_type = 1
serial = 0

[options]
custom-rendezvous-server = 'remote.directnorth.digital'
key = '$KEY'
EOF

open -a RustDesk
osascript -e 'display dialog "RustDesk is configured for DirectNorth Remote Access. Allow the requested Screen Recording and Input Monitoring permissions, then share the RustDesk ID shown in the app." buttons {"OK"} default button "OK" with icon note'
