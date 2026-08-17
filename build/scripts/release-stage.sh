#!/bin/bash
# Release build, staged .app, and a version-named .dmg under Support/build-release/version/.
# Nothing is published; see release-publish.sh for that.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
exec ./Support/build-release/scripts/release.sh
