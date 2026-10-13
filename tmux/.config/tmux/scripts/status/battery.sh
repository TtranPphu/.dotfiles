#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/battery-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"

data=$("$UTIL") || exit 1
cap="${data%% *}"
raw_status="${data##* }"
[[ -z "$cap" || ! "$cap" =~ ^[0-9]+$ ]] && exit 1

idx=$(( (cap - 1) / 10 ))

colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)

if [[ "${raw_status:-}" == "fully-charged" ]]; then
  icon="$(nerd_font_icon battery.full)"
elif [[ "${raw_status:-}" == "charging" || "${raw_status:-}" == "pending-charge" ]]; then
  icon="$(nerd_font_icon "battery.charging.$idx")"
else
  icon="$(nerd_font_icon "battery.discharging.$idx")"
fi
color="${colors[$idx]}"

if "$SCRIPT_DIR/layout.sh" is wide; then
  printf '#[fg=brightblack,bold,bg=%s]▏%s%s%s▕#[default]' "$color" "$icon" "$cap" "$(nerd_font_icon percent)"
else
  case "$raw_status" in
    fully-charged)             icon="$(nerd_font_icon battery.full.medium)" ;;
    charging | pending-charge) icon="$(nerd_font_icon battery.charging.medium)" ;;
    *)                         icon="$(nerd_font_icon "battery.discharging.$idx.medium")" ;;
  esac
  printf '#[fg=brightblack,bold,bg=%s]▏%s▕#[default]' "$color" "$icon"
fi
