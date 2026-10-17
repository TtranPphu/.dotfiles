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
  local data bat raw_status idx icon text

  data=$("$script_dir/battery-util.sh") || exit 1
  bat="${data%% *}"
  raw_status="${data##* }"
  [[ -z "$bat" ]] && exit 1

  idx=$(( (bat - 1) / 10 ))

  if [ "$raw_status" = "fully-charged" ]; then
    icon="$(nerd_font_icon battery.full)"
  elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
    icon="$(nerd_font_icon "battery.charging.$idx")"
  else
    icon="$(nerd_font_icon "battery.discharging.$idx")"
  fi

  if [[ "$size" != wide ]]; then
    case "$raw_status" in
      fully-charged)             icon="$(nerd_font_icon battery.full)"; icon="${icon% }" ;;
      charging | pending-charge) icon="$(nerd_font_icon battery.charging.medium)" ;;
      *)                         icon="$(nerd_font_icon "battery.discharging.$idx")"; icon="${icon% }" ;;
    esac
    text="$icon"
  else
    text="$icon$bat$(nerd_font_icon percent)"
  fi

  printf '%s%s\033[0m' "$(level_color "$bat")" "$text"
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
