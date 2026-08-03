#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Only shown when the status line is too narrow for separate kimi/deepseek modules
if [[ "${1:-}" == --guard ]]; then
  width=${STATUS_WIDTH:-999}
  (( width < 144 )) || exit 1
  exit 0
fi

total=$("$script_dir/llm-quota-util.sh" --total) || exit 1
printf '#[fg=#000000,bold,bg=magenta] %.2f #[default]' "$total"
