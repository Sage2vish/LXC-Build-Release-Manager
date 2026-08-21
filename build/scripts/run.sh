#!/bin/bash
# Builds the app and launches it, so what you see running is what you just built.
#
# Any copy already running is quit first — otherwise `open` just brings the old one
# to the front and the build looks like it changed nothing.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

APP=".derivedData/Build/Products/Debug/LXC-Build-Release-Manager.app"

xcodebuild \
  -project LXC-Build-Release-Manager.xcodeproj \
  -scheme LXC-Build-Release-Manager \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .derivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet \
  build

killall LXC-Build-Release-Manager 2>/dev/null || true
open "$APP"
echo "Running $APP"
