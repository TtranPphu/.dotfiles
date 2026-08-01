#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  width=${STATUS_WIDTH:-999}
  [[ $width -ge 144 ]] || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
balance=$("$script_dir/llm-quota-util.sh" --get kimi) || exit 1
printf '#[fg=brightblack,bold,bg=cyan]  %.2f #[default]' "$balance"
