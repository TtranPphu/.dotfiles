#!/usr/bin/env bash

LEVEL_COLORS=(
  "247;118;142" "242;129;134" "238;141;127" "233;152;119" "229;163;112"
  "224;175;104" "208;183;105" "191;191;105" "175;198;106" "158;206;106"
)

_level_index() {
  local idx=$(( (${1:-0} - 1) / 10 ))
  (( idx < 0 )) && idx=0
  (( idx > 9 )) && idx=9
  printf '%s' "$idx"
}

# Takes a 0-100 value (battery percent, or an RTT level x10): 100 is green, 1 is red.
level_color() {
  printf '\033[38;2;%sm' "${LEVEL_COLORS[$(_level_index "${1:-0}")]}"
}

level_rgb() {
  printf '%s' "${LEVEL_COLORS[$(_level_index "${1:-0}")]}"
}

level_hex() {
  local r g b
  IFS=';' read -r r g b <<< "$(level_rgb "${1:-0}")"
  printf '#%02x%02x%02x' "$r" "$g" "$b"
}
