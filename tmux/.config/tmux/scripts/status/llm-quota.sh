#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Only shown when the status line is too narrow for separate kimi/deepseek modules
guard() {
  local width=${STATUS_WIDTH:-999}
  (( width < 144 ))
}

if [[ "${1:-}" == --guard ]]; then
  if guard; then exit 0; else exit 1; fi
fi

# Keep the per-provider caches fresh; their own output is discarded here
"$script_dir/kimi.sh" >/dev/null 2>&1 || true
"$script_dir/deepseek.sh" >/dev/null 2>&1 || true

cache_dir="$HOME/.local/state/starship"
kimi=$(jq -r '.total_balance // empty' "$cache_dir/kimi-balance.json" 2>/dev/null) || kimi=""
deepseek=$(jq -r '.total_balance // empty' "$cache_dir/deepseek-balance.json" 2>/dev/null) || deepseek=""

if [[ -z "$kimi" && -z "$deepseek" ]]; then
  exit 1
fi

total=$(awk -v a="${kimi:-0}" -v b="${deepseek:-0}" 'BEGIN { printf "%.2f", a + b }')
printf '#[fg=brightblack,bold,bg=magenta] %.2f #[default]' "$total"
