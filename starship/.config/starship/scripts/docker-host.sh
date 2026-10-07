#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

name="${CONTAINER_NAME:-${COMPOSE_SERVICE:-}}"
icon="$(nerd_font_icon docker)"
[[ -n "$icon" && -n "$name" ]] && name="$icon $name"
printf '%s\n' "$name"
