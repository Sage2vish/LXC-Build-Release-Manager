#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_RELEASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$BUILD_RELEASE_DIR/../.." && pwd)"
DERIVED_DATA_DIR="$PROJECT_ROOT/.derivedData-lxc-brm"
APP_NAME="LXC-BRM"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME.app"
STAGING_DIR="$BUILD_RELEASE_DIR/version/staging"
DMG_NAME="$APP_NAME-$(date +%Y-%m-%d).dmg"
DMG_PATH="$BUILD_RELEASE_DIR/version/$DMG_NAME"

echo "Building Release configuration for $APP_NAME"
xcodebuild \
  -project "$PROJECT_ROOT/LXC-BRM.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [ ! -d "$APP_PATH" ]; then
  echo "Expected app bundle not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

echo "Creating DMG at $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Release artifact staged at $DMG_PATH"
