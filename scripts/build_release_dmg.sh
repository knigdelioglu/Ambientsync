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
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

ditto "$APP_DIR" "$DMG_ROOT/${APP_NAME}.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

hdiutil verify "$DMG_PATH"

# Validate the exact .app stored in the final disk image. This catches bundle
# layout/signature/resource failures that a checksum-only DMG verification misses.
MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ambientsync-dmg.XXXXXX")"
cleanup_mount() {
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
    rmdir "$MOUNT_DIR" >/dev/null 2>&1 || true
}
trap cleanup_mount EXIT

hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null
codesign --verify --deep --strict --verbose=2 "$MOUNT_DIR/${APP_NAME}.app"
"$MOUNT_DIR/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" --release-bundle-smoke
hdiutil detach "$MOUNT_DIR" >/dev/null
rmdir "$MOUNT_DIR"
trap - EXIT

echo "Built and verified DMG: $DMG_PATH"
