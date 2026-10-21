#!/usr/bin/env bash
# Level ramp: ten catalog colors, red (0) at the low end, green (9) at the top.
# Sourced by the status and prompt scripts; the colors live in color.csv.

_level_color_dir="$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")"
# shellcheck source=/dev/null
source "$_level_color_dir/color.sh"

_level_index() {
  local idx=$(( (${1:-0} - 1) / 10 ))
  (( idx < 0 )) && idx=0
  (( idx > 9 )) && idx=9
  printf '%s' "$idx"
}

# Takes a 0-100 value (battery percent, or an RTT level x10): 100 is green, 1 is red.
level_hex() {
  color_get "level.$(_level_index "${1:-0}")"
}

level_rgb() {
  local hex
  hex=$(level_hex "$@")
  printf '%d;%d;%d' "0x${hex:1:2}" "0x${hex:3:2}" "0x${hex:5:2}"
}

level_color() {
  printf '\033[38;2;%sm' "$(level_rgb "$@")"
}
