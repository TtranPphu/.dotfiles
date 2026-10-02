#!/usr/bin/env bash
set -euo pipefail

pct=$'\uf295'
icon=$'\U000F11D8'

# Exit 0 only when medium or wide enough for the quota pill
if [[ "${1:-}" == --guard ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  "$script_dir/layout.sh" is narrow && exit 1
  "$script_dir/opencode-quota-util.sh" --values >/dev/null || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
read -r rolling weekly monthly <<<"$values"

size=$("$script_dir/layout.sh" size)
[[ "$size" == narrow ]] && exit 1
if [[ "$size" == wide ]]; then
  out="$icon $rolling$pct/$weekly$pct/$monthly$pct"
else
  out="$icon $monthly$pct"
fi
printf '#[fg=#000000,bold,bg=black]▏#[fg=white,bold,bg=black]%s#[fg=#000000,bold,bg=black]▕#[default]' "$out"
