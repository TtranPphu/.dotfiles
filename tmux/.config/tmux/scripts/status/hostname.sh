#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/hostname-util.sh"
QUALITY="$SCRIPT_DIR/ssh-quality-util.sh"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/icon.sh"
source "$SCRIPT_DIR/layout.sh"

socket_path="${1:-}"
current_session="${2:-}"
size=$(layout_size_fast)
[[ $size == narrow ]] && exit 1

host_name=$("$UTIL") || exit 1
[[ -z "$host_name" ]] && exit 1

# Strip domain for display
if [[ "$host_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$host_name" == *:* ]]; then
  display_host="$host_name"
else
  display_host="${host_name%%.*}"
fi

icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
icon_tail="$(nerd_font_icon separator.tail)"
fg_muted="$(color_get muted)"

# Over SSH the pill background shows the connection quality (10 = green, 1 = red);
# medium drops the name, narrow (handled above) hides the pill. Foreground matches
# the battery-family pills (muted over the same ramp).
if level=$("$QUALITY" level "$socket_path" "$current_session" 2>/dev/null); then
  ramp=$((level * 10))
  icon_signal=$("$QUALITY" signal "$socket_path" "$current_session" 2>/dev/null)
  bg_quality="$(level_hex "$ramp")"
  style=$(printf '#[fg=%s,bg=%s]' "$fg_muted" "$bg_quality")
  reset='#[default]'
  if [[ $size == wide ]]; then
    out="$icon_head$icon_signal $display_host$icon_flat"
  elif [[ "$(nerd_font_type)" == nerd ]]; then
    out="$icon_head$icon_signal$icon_tail"
  else
    out="$icon_head$icon_signal$icon_tail"
  fi
  printf '%s%s%s' "$style" "$out" "$reset"
  exit 0
fi

# Local pill only in wide, neutral style like the pane-id/session pills.
[[ $size == wide ]] || exit 1
fg_blue="$(color_get blue)"
style=$(printf '#[fg=%s,bg=%s,bold]' "$fg_muted" "$fg_blue")
reset='#[default]'
out="$icon_head$display_host$icon_flat"
printf '%s%s%s' "$style" "$out" "$reset"
