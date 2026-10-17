#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/keyboard-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/layout.sh"

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

if [[ "$(layout_size_fast)" == wide ]]; then
  printf '#[fg=brightblack,bold,bg=%s]▏%s%s%s▕#[default]' "${colors[$idx_left]}" "$(nerd_font_icon keyboard)" "$left" "$(nerd_font_icon percent)"
  printf '#[fg=brightblack,bold,bg=%s]▏%s%s%s▕#[default]' "${colors[$idx_right]}" "$(nerd_font_icon keyboard)" "$right" "$(nerd_font_icon percent)"
else
  icon="$(nerd_font_icon keyboard)"; icon="${icon% }"
  printf '#[fg=brightblack,bold,bg=%s]▏%s▕#[default]' "${colors[$idx_left]}" "$icon"
  printf '#[fg=brightblack,bold,bg=%s]▏%s▕#[default]' "${colors[$idx_right]}" "$icon"
fi
