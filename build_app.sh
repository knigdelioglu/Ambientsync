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

# A signed macOS .app must keep application resources under Contents/Resources.
# Do not place the SwiftPM resource bundle beside Contents at the .app root;
# codesign treats that layout as unsealed/invalid bundle content.
REFERENCE_NAME="Samsung_4C2D_76AB_reference.plist"
REFERENCE_SOURCE="$ROOT/Sources/AmbientSync/Resources/HiDPIOverrides/$REFERENCE_NAME"
HIDPI_RES_DIR="$RES_DIR/HiDPIOverrides"
mkdir -p "$HIDPI_RES_DIR"
cp "$REFERENCE_SOURCE" "$HIDPI_RES_DIR/$REFERENCE_NAME"

plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null
[[ -x "$BIN_DIR/$APP_NAME" ]]
[[ -f "$HIDPI_RES_DIR/$REFERENCE_NAME" ]]

# Apple Silicon requires signed executable code. In the absence of a configured
# Developer ID certificate, use an ad-hoc signature so the bundle itself is
# structurally valid and its code/resources are sealed consistently.
codesign --force --deep --sign - --timestamp=none "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

if [[ "$INSTALL_APP" == "1" ]]; then
    rm -rf "$INSTALL_DIR"
    ditto "$APP_DIR" "$INSTALL_DIR"
    echo "Installed: $INSTALL_DIR"
fi

echo "Built: $APP_DIR"
