#!/usr/bin/env bash
# Compatibility shim for older entry points. Remove after callers are updated.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/install_wayland_sway.sh" "$@"
