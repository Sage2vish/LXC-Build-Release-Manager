#!/bin/bash
# Recount every plan and rewrite the generated tables in Support/worklog/BRM-Plan-todo.md.
# Run it after ticking anything off; CI runs the same script with --check.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
exec python3 Support/build-release/scripts/update-plan-index.py "$@"
