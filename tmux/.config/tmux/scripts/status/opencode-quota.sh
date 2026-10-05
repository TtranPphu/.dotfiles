#!/usr/bin/env bash
set -euo pipefail

pct=''
icon='󱇘 '

# Exit 0 only when medium or wide enough for the quota pill
if [[ "${1:-}" == --guard ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  "$script_dir/layout.sh" is narrow && exit 1
  "$script_dir/opencode-quota-util.sh" --values >/dev/null || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
read -r rolling _ monthly <<<"$values"

size=$("$script_dir/layout.sh" size)
[[ "$size" == narrow ]] && exit 1

# Rolling quota drives the pill color: low usage green, near limit red. The
# colors and 10% buckets mirror battery.sh so the gradients line up.
colors=(
  "#f7768e" "#f28186" "#ee8d7f" "#e99877" "#e5a370"
  "#e0af68" "#d0b769" "#bfbf69" "#afc66a" "#9ece6a"
)
[[ "${rolling:-}" =~ ^-?[0-9]+$ ]] || rolling=0
idx=$(( (rolling - 1) / 10 ))
(( idx < 0 )) && idx=0
(( idx > 9 )) && idx=9

out="$icon$monthly$pct"
printf '#[fg=#000000,bold,bg=%s]▏%s▕#[default]' "${colors[$idx]}" "$out"
