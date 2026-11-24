#!/bin/zsh
# This wrapper keeps the customer-facing DMG simple while the shared
# installer performs the download, installation, and DirectNorth setup.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/configure-rustdesk-mac.command"
