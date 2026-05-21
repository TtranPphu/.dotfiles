#!/bin/bash

set -euo pipefail

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
ULTRAWIDE_COLUMN_WIDTH=0.6
DEFAULT_COLUMN_WIDTH=0.8

apply_column_width() {
  local monitor width height column_width

  monitor="$(hyprctl -j monitors | jq -r '
    map(select(.disabled != true))
    | (map(select(.focused == true))[0] // .[0] // empty)
    | if . == null then empty else "\(.width) \(.height)" end
  ')"

  if [[ -z "$monitor" ]]; then
    return
  fi

  read -r width height <<< "$monitor"
  column_width="$DEFAULT_COLUMN_WIDTH"

  # Treat 21:9-class displays as ultrawide and use narrower scrolling columns.
  if (( width * 10 >= height * 21 )); then
    column_width="$ULTRAWIDE_COLUMN_WIDTH"
  fi

  hyprctl keyword scrolling:column_width "$column_width" >/dev/null
}

apply_column_width

if [[ ! -S "$SOCKET" ]]; then
  exit 0
fi

socat -U - "UNIX-CONNECT:$SOCKET" | while read -r event; do
  case "$event" in
    focusedmon\>\>*|focusedmonv2\>\>*|monitoradded\>\>*|monitoraddedv2\>\>*|monitorremoved\>\>*|monitorremovedv2\>\>*)
      apply_column_width
      ;;
  esac
done
