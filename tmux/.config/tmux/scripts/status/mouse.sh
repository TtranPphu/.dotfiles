#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/mouse-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/layout.sh"
source "$SCRIPT_DIR/level-color.sh"

data=$("$UTIL") || exit 1
cap="${data%% *}"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

idx=$(( (cap - 1) / 10 ))
icon_mouse="$(nerd_font_icon mouse)"
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_muted="$(color_get muted)"
bg_level="$(level_hex "$cap")"

style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_level")
reset='#[default]'

if [[ "$(layout_size_fast)" == wide ]]; then
  icon_percent="$(nerd_font_icon percent)"
  out="$icon_head$icon_mouse$cap$icon_percent$icon_flat"
else
  icon_mouse="${icon_mouse% }"
  out="$icon_head$icon_mouse$icon_flat"
fi
printf '%s%s%s' "$style" "$out" "$reset"
