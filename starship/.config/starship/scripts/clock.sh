#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/nerd-font.sh"

hour=$((10#$(date +%-I)))
time="$(date +'%I:%M %p')"
icon="$(nerd_font_icon "clock.$hour")"
if [[ -n "$icon" ]]; then
  printf '%s %s\n' "$icon" "$time"
else
  printf '%s\n' "$time"
fi
