#!/usr/bin/env bash
# Combined LLM pill: opencode monthly quota + the combined dollar balance,
# colored by opencode's rolling bucket. Shown at medium; wide shows the
# separate opencode/deepseek/kimi pills instead.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"

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
colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)
[[ "${rolling:-}" =~ ^-?[0-9]+$ ]] || rolling=0
idx=$(( (rolling - 1) / 10 ))
(( idx < 0 )) && idx=0
(( idx > 9 )) && idx=9

out="$(nerd_font_icon opencode)$monthly$(nerd_font_icon percent) + $(nerd_font_icon usd)$total"
printf '#[fg=#000000,bold,bg=%s]▏%s▕#[default]' "${colors[$idx]}" "$out"
