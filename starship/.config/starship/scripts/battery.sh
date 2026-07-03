#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/battery-util.sh"

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

    printf '%s %s' "$icon" "$bat"
    ;;
  --guard)
    [[ $# -lt 2 ]] && usage
    lvl="$2"
    idx=$(( (bat - 1) / 10 ))
    [ "$idx" -eq "$lvl" ]
    ;;
  *) usage ;;
esac
