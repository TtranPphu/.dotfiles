#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/battery-util.sh"
source "$SCRIPT_DIR/icon.sh"
source "$SCRIPT_DIR/layout.sh"
source "$SCRIPT_DIR/level-color.sh"

data=$("$UTIL") || exit 1
cap="${data%% *}"
raw_status="${data##* }"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

idx=$(( (cap - 1) / 10 ))

if [[ "${raw_status:-}" == "fully-charged" ]]; then
  icon_battery="$(nerd_font_icon battery.full)"
elif [[ "${raw_status:-}" == "charging" || "${raw_status:-}" == "pending-charge" ]]; then
  icon_battery="$(nerd_font_icon "battery.charging.$idx")"
else
  icon_battery="$(nerd_font_icon "battery.discharging.$idx")"
fi
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_muted="$(color_get muted)"
bg_level="$(level_hex "$cap")"

style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_muted" "$bg_level")
reset='#[default]'

if [[ "$(layout_size_fast)" == wide ]]; then
  icon_percent="$(nerd_font_icon percent)"
  out="$icon_head$icon_battery$cap$icon_percent$icon_flat"
else
  case "$raw_status" in
    fully-charged)             icon_battery="$(nerd_font_icon battery.full)"; icon_battery="${icon_battery% }" ;;
    charging | pending-charge) icon_battery="$(nerd_font_icon battery.charging.medium)" ;;
    *)                         icon_battery="$(nerd_font_icon "battery.discharging.$idx")"; icon_battery="${icon_battery% }" ;;
  esac
  out="$icon_head$icon_battery$icon_flat"
fi
printf '%s%s%s' "$style" "$out" "$reset"
