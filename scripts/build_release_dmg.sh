#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="AmbientSync"
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")}"
DIST_DIR="${DIST_DIR:-$ROOT/dist}"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
APP_DIR="$ROOT/${APP_NAME}.app"

rm -rf "$DIST_DIR"
mkdir -p "$DMG_ROOT"

INSTALL_APP=0 "$ROOT/build_app.sh"

ditto "$APP_DIR" "$DMG_ROOT/${APP_NAME}.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

echo "Built DMG: $DMG_PATH"
