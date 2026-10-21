#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/layout.sh" is wide || exit 1
  exit 0
fi

# Only show when deepseek is configured in opencode
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"
source "$script_dir/color.sh"
"$script_dir/llm-quota-util.sh" --configured deepseek || exit 1

balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
icon_head="$(nerd_font_icon separator.head)"
icon_deepseek="$(nerd_font_icon deepseek)"
icon_usd="$(nerd_font_icon usd)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_ink="$(color_get ink)"
bg_blue="$(color_get blue)"
style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_ink" "$bg_blue")
reset='#[default]'
printf -v out '%s%s%.2f%s' "$icon_head" "$icon_deepseek$icon_usd" "$balance" "$icon_flat"
printf '%s%s%s' "$style" "$out" "$reset"
