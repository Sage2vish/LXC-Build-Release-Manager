#!/bin/bash
# Rebuild the macOS app icon set from the design source.
#
# Run it after changing the artwork in Support/context/concepts-designs/AppIcons/.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
exec python3 Support/build-release/scripts/make-app-icon.py "$@"
