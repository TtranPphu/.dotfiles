#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icons.sh"

# Only shown when the status line is too narrow for separate kimi/deepseek modules
if [[ "${1:-}" == --guard ]]; then
  "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/layout.sh" is medium || exit 1
  exit 0
fi

total=$("$script_dir/llm-quota-util.sh" --total) || exit 1
awk -v v="${total:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf '#[fg=#000000,bold,bg=magenta]▏%s%.2f▕#[default]' "$(icon money)" "$total"
