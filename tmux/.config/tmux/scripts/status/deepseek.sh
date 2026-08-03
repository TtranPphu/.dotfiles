#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  width=${STATUS_WIDTH:-999}
  [[ $width -ge 144 ]] || exit 1
  exit 0
fi

# Only show when deepseek is the active provider
settings_file="$HOME/.claude/settings.json"
grep -q 'deepseek.com' "$settings_file" 2>/dev/null || exit 1

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
printf '#[fg=#000000,bold,bg=blue]  %.2f #[default]' "$balance"
