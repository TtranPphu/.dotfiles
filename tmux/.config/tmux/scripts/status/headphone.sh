#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/headphone-util.sh"

data=$("$UTIL") || exit 1
left="${data%% *}"
rest="${data#* }"
right="${rest%% *}"
case_bat="${rest##* }"
[[ -z "$left" ]] && exit 1

# Pick first non-zero battery value
val="$left"
[[ "$val" -eq 0 && "$right" -gt 0 ]] && val="$right"
[[ "$val" -eq 0 && "$case_bat" -gt 0 ]] && val="$case_bat"
[[ "$val" -eq 0 ]] && exit 1

colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

idx=$(( (val - 1) / 10 ))
[[ idx -ge 0 ]] && [[ idx -lt 10 ]] || idx=0

WIDE_ICON='󱡏'
NARROW_ICON='󰎇'

if [[ $(tmux display -p '#{window_width}' 2>/dev/null || echo 120) -lt 120 ]]; then
  printf '#[fg=brightblack,bold,bg=%s] %s #[default]' "${colors[$idx]}" "$NARROW_ICON"
else
  printf '#[fg=brightblack,bold,bg=%s] %s %s #[default]' "${colors[$idx]}" "$WIDE_ICON" "$val"
fi
