#!/bin/bash
# Debug build of the app.
#
# This repository is its own test subject: open it in LXC Build Release Manager and this script
# appears as a runnable command, exactly like any other project's build scripts.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

xcodebuild \
  -project LXC-Build-Release-Manager.xcodeproj \
  -scheme LXC-Build-Release-Manager \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
