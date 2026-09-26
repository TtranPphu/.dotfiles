#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/battery-util.sh"
source "$SCRIPT_DIR/level-color.sh"

usage() { exit 1; }

[[ $# -lt 1 ]] && usage

data=$("$UTIL") || exit 1
bat="${data%% *}"
raw_status="${data##* }"
[[ -z "$bat" ]] && exit 1

case "${1:-}" in
  --display)
    charging=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
    discharging=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

    idx=$(( (bat - 1) / 10 ))

    if [ "$raw_status" = "fully-charged" ]; then
      icon="󰂄"
    elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
      icon="${charging[$idx]}"
    else
      icon="${discharging[$idx]}"
    fi

    if [[ $(stty size < /dev/tty 2>/dev/null | cut -d" " -f2 || echo 144) -lt 144 ]]; then
      text="$icon"
    else
      text="$icon $bat"$'\uf295'
    fi

    printf '%s%s\033[0m' "$(level_color "$bat")" "$text"
    ;;
  --guard)
    exit 0
    ;;
  *) usage ;;
esac
