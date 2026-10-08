#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/battery-util.sh"
source "$SCRIPT_DIR/level-color.sh"
source "$SCRIPT_DIR/nerd-font.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
bat="${data%% *}"
raw_status="${data##* }"
[[ -z "$bat" ]] && exit 1

case "${1:-}" in
  --display)
    idx=$(( (bat - 1) / 10 ))

    if [ "$raw_status" = "fully-charged" ]; then
      icon="$(nerd_font_icon battery.full)"
    elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
      icon="$(nerd_font_icon "battery.charging.$idx")"
    else
      icon="$(nerd_font_icon "battery.discharging.$idx")"
    fi

    if [[ "$("$SCRIPT_DIR/layout.sh" size)" != wide ]]; then
      case "$raw_status" in
        charging | pending-charge | fully-charged) text="$(nerd_font_icon battery.full)" ;;
        *) text="$icon" ;;
      esac
    else
      text="$icon $bat%$(nerd_font_icon plug)"
    fi

    printf '%s%s\033[0m' "$(level_color "$bat")" "$text"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
  *) usage ;;
esac
