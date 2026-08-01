#!/bin/bash

# Starship custom module: DeepSeek account balance
set -euo pipefail

WIDTH="${COLUMNS:-$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2)}"
WIDTH="${WIDTH:-999}"

# Exit 0 only when wide enough for the standalone module
if [ "${1:-}" = "--guard" ]; then
  [ "$WIDTH" -ge 144 ] || exit 1
  exit 0
fi

# Only show when deepseek is the active provider
if ! grep -q 'deepseek.com' "$HOME/.claude/settings.json" 2>/dev/null; then
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BALANCE=$("$SCRIPT_DIR/llm-quota-util.sh" --get deepseek) || exit 1
printf " %.2f" "$BALANCE"
