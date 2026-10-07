#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

shell="${STARSHIP_SHELL:-unknown-shell}"
icon="$(nerd_font_icon "shell.$shell")"
if [[ -n "$icon" ]]; then
  printf '%s %s\n' "$icon" "$shell"
else
  printf '%s\n' "$shell"
fi
