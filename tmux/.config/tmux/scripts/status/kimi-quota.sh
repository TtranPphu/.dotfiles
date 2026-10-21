#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/layout.sh" is wide || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"
source "$script_dir/color.sh"
balance=$("$script_dir/llm-quota-util.sh" --get kimi) || exit 1
awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
icon_head="$(nerd_font_icon separator.head)"
icon_kimi="$(nerd_font_icon kimi)"
icon_usd="$(nerd_font_icon usd)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_ink="$(color_get ink)"
bg_cyan="$(color_get cyan)"
style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_ink" "$bg_cyan")
reset='#[default]'
printf -v out '%s%s%.2f%s' "$icon_head" "$icon_kimi$icon_usd" "$balance" "$icon_flat"
printf '%s%s%s' "$style" "$out" "$reset"
