#!/bin/bash
# Full unit-test suite. Prints the pass/fail summary rather than the whole xcodebuild transcript.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

set +e
xcodebuild \
  -project LXC-Build-Release-Manager.xcodeproj \
  -scheme LXC-Build-Release-Manager \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | grep -E "Test Case .* (passed|failed)|Executed [0-9]+ test|error:|TEST (SUCCEEDED|FAILED)"
status=${PIPESTATUS[0]}
set -e
exit "$status"
