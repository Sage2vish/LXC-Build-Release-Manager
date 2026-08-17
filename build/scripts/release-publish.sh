#!/bin/bash
# Release build, staged .dmg, and a GitHub Release carrying it — the feed the in-app updater
# reads. Needs the GitHub CLI, authenticated. Pass --prerelease to publish to the Beta channel.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
exec ./Support/build-release/scripts/release.sh --publish "$@"
