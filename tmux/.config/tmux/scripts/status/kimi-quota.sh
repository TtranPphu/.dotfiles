#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/layout.sh" is wide || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icons.sh"
balance=$("$script_dir/llm-quota-util.sh" --get kimi) || exit 1
awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf '#[fg=#000000,bold,bg=cyan]▏%s %s%.2f▕#[default]' "$(icon kimi)" "$(icon money)" "$balance"
