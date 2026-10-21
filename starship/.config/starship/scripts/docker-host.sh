#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

name="${CONTAINER_NAME:-${COMPOSE_SERVICE:-}}"
icon_docker="$(nerd_font_icon docker)"
text="$name"
[[ -n "$icon_docker" && -n "$name" ]] && text="$icon_docker$name"
# An empty name renders nothing: exit non-zero so the module is hidden and its
# format's literal space does not leak into the prompt.
[ -n "$text" ] || exit 1
printf '%s\n' "$text"
