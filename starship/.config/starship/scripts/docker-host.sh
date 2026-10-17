#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

name="${CONTAINER_NAME:-${COMPOSE_SERVICE:-}}"
icon="$(nerd_font_icon docker)"
[[ -n "$icon" && -n "$name" ]] && name="$icon$name"
# An empty name renders nothing: exit non-zero so the module is hidden and its
# format's literal space does not leak into the prompt.
[ -n "$name" ] || exit 1
printf '%s\n' "$name"
