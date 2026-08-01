#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-util.sh"

data=$("$UTIL") || exit 1
left="${data%% *}"
right="${data##* }"
[[ -z "$left" ]] && exit 1

colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

idx_left=$(( (left - 1) / 10 ))
idx_right=$(( (right - 1) / 10 ))

[[ idx_left  -ge 0 ]] && [[ idx_left  -lt 10 ]] || idx_left=0
[[ idx_right -ge 0 ]] && [[ idx_right -lt 10 ]] || idx_right=0

if [[ $(tmux display -p '#{window_width}' 2>/dev/null || echo 144) -lt 144 ]]; then
  printf '#[fg=brightblack,bold,bg=%s]  #[default]' "${colors[$idx_left]}"
  printf '#[fg=brightblack,bold,bg=%s]  #[default]' "${colors[$idx_right]}"
else
  printf '#[fg=brightblack,bold,bg=%s]  %s #[default]' "${colors[$idx_left]}" "$left"
  printf '#[fg=brightblack,bold,bg=%s]  %s #[default]' "${colors[$idx_right]}" "$right"
fi
