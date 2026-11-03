#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="DisplayNap"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building $APP_NAME for macOS..."

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Compile Swift binary
swiftc -O "$DIR/Sources/main.swift" -o "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "$DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Ad-hoc code sign so macOS gatekeeper accepts it cleanly
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "==> Successfully created $APP_DIR"
echo "==> You can run it now with: open '$APP_DIR'"
