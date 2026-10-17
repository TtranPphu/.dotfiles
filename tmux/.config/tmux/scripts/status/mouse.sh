#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/mouse-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/layout.sh"

data=$("$UTIL") || exit 1
cap="${data%% *}"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

idx=$(( (cap - 1) / 10 ))

if [[ "$(layout_size_fast)" == wide ]]; then
  printf '#[fg=brightblack,bold,bg=%s]▏%s%s%s▕#[default]' "${colors[$idx]}" "$(nerd_font_icon mouse)" "$cap" "$(nerd_font_icon percent)"
else
  icon="$(nerd_font_icon mouse)"; icon="${icon% }"
  printf '#[fg=brightblack,bold,bg=%s]▏%s▕#[default]' "${colors[$idx]}" "$icon"
fi
