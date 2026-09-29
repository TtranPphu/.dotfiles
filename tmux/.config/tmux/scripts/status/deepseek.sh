#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  width=${STATUS_WIDTH:-999}
  [[ $width -ge 144 ]] || exit 1
  exit 0
fi

# Only show when deepseek is configured in opencode
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/llm-quota-util.sh" --configured deepseek || exit 1

balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf '#[fg=#000000,bold,bg=blue]▏󰫣 %.2f▕#[default]' "$balance"
