#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AmbientSync"
APP_DIR="$ROOT/$APP_NAME.app"
INSTALL_DIR="/Applications/$APP_NAME.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
INSTALL_APP="${INSTALL_APP:-1}"

rm -rf "$APP_DIR"
mkdir -p "$BIN_DIR" "$RES_DIR"

swift build -c release --package-path "$ROOT"
BIN_PATH="$(swift build -c release --show-bin-path --package-path "$ROOT")"

cp "$BIN_PATH/$APP_NAME" "$BIN_DIR/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"
chmod +x "$BIN_DIR/$APP_NAME"

# Bundle.module in the SwiftPM executable resolves package resources from a
# sibling bundle at Bundle.main.bundleURL when the executable is wrapped in .app.
RESOURCE_BUNDLE="$(find "$BIN_PATH" -maxdepth 1 -type d -name "${APP_NAME}_*.bundle" -print -quit)"
if [[ -z "$RESOURCE_BUNDLE" ]]; then
    echo "Error: SwiftPM resource bundle was not produced." >&2
    exit 1
fi
cp -R "$RESOURCE_BUNDLE" "$APP_DIR/"

plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null
[[ -x "$BIN_DIR/$APP_NAME" ]]
[[ -d "$APP_DIR/$(basename "$RESOURCE_BUNDLE")" ]]

if [[ "$INSTALL_APP" == "1" ]]; then
    rm -rf "$INSTALL_DIR"
    ditto "$APP_DIR" "$INSTALL_DIR"
    echo "Installed: $INSTALL_DIR"
fi

echo "Built: $APP_DIR"
