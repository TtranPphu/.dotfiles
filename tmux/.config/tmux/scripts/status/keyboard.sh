#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-util.sh"
source "$SCRIPT_DIR/icon.sh"
source "$SCRIPT_DIR/layout.sh"
source "$SCRIPT_DIR/level-color.sh"

data=$("$UTIL") || exit 1
left="${data%% *}"
right="${data##* }"
[[ -z "$left" ]] && exit 1

icon_keyboard="$(nerd_font_icon keyboard)"
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_muted="$(color_get muted)"
bg_left="$(level_hex "$left")"
bg_right="$(level_hex "$right")"

style_left=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_left")
style_right=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_right")
reset='#[default]'

if [[ "$(layout_size_fast)" == wide ]]; then
  icon_percent="$(nerd_font_icon percent)"
  out_left="$icon_head$icon_keyboard$left$icon_percent$icon_flat"
  out_right="$icon_head$icon_keyboard$right$icon_percent$icon_flat"
else
  icon_keyboard="${icon_keyboard% }"
  out_left="$icon_head$icon_keyboard$icon_flat"
  out_right="$icon_head$icon_keyboard$icon_flat"
fi
printf '%s%s%s' "$style_left" "$out_left" "$reset"
printf '%s%s%s' "$style_right" "$out_right" "$reset"
