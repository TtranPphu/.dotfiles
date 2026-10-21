#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/headphone-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/layout.sh"
source "$SCRIPT_DIR/level-color.sh"

data=$("$UTIL") || exit 1
[[ -z "$data" || "$data" -eq 0 ]] && exit 1
val="$data"

icon_wide="$(nerd_font_icon headphone)"
icon_medium="$(nerd_font_icon headphone.medium)"
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_muted="$(color_get muted)"
bg_level="$(level_hex "$val")"

style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_level")
reset='#[default]'

if [[ "$(layout_size_fast)" == wide ]]; then
  icon_percent="$(nerd_font_icon percent)"
  out="$icon_head$icon_wide$val$icon_percent$icon_flat"
else
  out="$icon_head$icon_medium$icon_flat"
fi
printf '%s%s%s' "$style" "$out" "$reset"
