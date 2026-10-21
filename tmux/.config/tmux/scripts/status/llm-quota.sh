#!/usr/bin/env bash
# Combined LLM pill: opencode monthly quota + the combined dollar balance,
# colored by opencode's rolling bucket. Shown at medium; wide shows the
# separate opencode/deepseek/kimi pills instead.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icon.sh"
source "$script_dir/level-color.sh"

# Exit 0 only when medium or wide enough for the combined pill
if [[ "${1:-}" == --guard ]]; then
  "$script_dir/layout.sh" is medium || exit 1
  exit 0
fi

values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
read -r rolling _ monthly <<<"$values"
total=$("$script_dir/llm-quota-util.sh" --total) || exit 1
awk -v v="${total:-0}" 'BEGIN { exit !(v > 0) }' || exit 1

# Rolling quota drives the pill color: same colors and 10% buckets as
# opencode-quota.sh so the gradients line up.
[[ "${rolling:-}" =~ ^-?[0-9]+$ ]] || rolling=0

icon_opencode="$(nerd_font_icon opencode)"
icon_percent="$(nerd_font_icon percent)"
icon_usd="$(nerd_font_icon usd)"
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_ink="$(color_get ink)"
bg_rolling="$(level_hex "$rolling")"
style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_ink" "$bg_rolling")
reset='#[default]'

out="$icon_head$icon_opencode$monthly$icon_percent $icon_usd$total$icon_flat"
printf '%s%s%s' "$style" "$out" "$reset"
