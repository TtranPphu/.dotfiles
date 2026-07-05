#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/mouse-util.sh"

data=$("$UTIL") || exit 1
cap="${data%% *}"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

idx=$(( (cap - 1) / 10 ))

if [[ ${COLUMNS:-$(tput cols 2>/dev/null || echo 80)} -lt 80 ]]; then
  printf '#[fg=brightblack,bold,bg=%s] 󰍽 #[default]' "${colors[$idx]}"
else
  printf '#[fg=brightblack,bold,bg=%s] 󰍽 %s #[default]' "${colors[$idx]}" "$cap"
fi
