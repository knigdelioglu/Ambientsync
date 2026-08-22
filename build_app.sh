#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AmbientSync"
BUILD_DIR="$ROOT/.build"
APP_DIR="$ROOT/$APP_NAME.app"
INSTALL_DIR="/Applications/$APP_NAME.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

rm -rf "$APP_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BIN_DIR" "$RES_DIR"

swift build -c release --package-path "$ROOT"

cp "$ROOT/.build/release/$APP_NAME" "$BIN_DIR/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"
chmod +x "$BIN_DIR/$APP_NAME"

rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"

echo "Built: $APP_DIR"
echo "Installed: $INSTALL_DIR"
