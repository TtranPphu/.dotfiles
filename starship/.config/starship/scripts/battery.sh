#!/usr/bin/env bash
# Battery segment: gate + live render; battery-util.sh owns the fetch cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$(layout_size_fast)}
  local data bat raw_status idx icon_battery icon_percent text fg_level

  data=$("$script_dir/battery-util.sh") || exit 1
  bat="${data%% *}"
  raw_status="${data##* }"
  [[ -z "$bat" ]] && exit 1

  idx=$(( (bat - 1) / 10 ))

  if [ "$raw_status" = "fully-charged" ]; then
    icon_battery="$(nerd_font_icon battery.full)"
  elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
    icon_battery="$(nerd_font_icon "battery.charging.$idx")"
  else
    icon_battery="$(nerd_font_icon "battery.discharging.$idx")"
  fi

  if [[ "$size" != wide ]]; then
    case "$raw_status" in
      fully-charged)             icon_battery="$(nerd_font_icon battery.full)"; icon_battery="${icon_battery% }" ;;
      charging | pending-charge) icon_battery="$(nerd_font_icon battery.charging.medium)" ;;
      *)                         icon_battery="$(nerd_font_icon "battery.discharging.$idx")"; icon_battery="${icon_battery% }" ;;
    esac
    text="$icon_battery"
  else
    icon_percent="$(nerd_font_icon percent)"
    text="$icon_battery$bat$icon_percent"
  fi

  fg_level=$(level_color "$bat")
  reset=$'\033[0m'
  printf '%s%s%s' "$fg_level" "$text" "$reset"
}

case "${1:-}" in
  --display)
    render "$(layout_size_fast)"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) usage ;;
esac
