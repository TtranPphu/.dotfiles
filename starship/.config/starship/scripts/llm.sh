#!/bin/bash

# Starship custom module: combined LLM account balance on narrow terminals
set -euo pipefail

WIDTH="${COLUMNS:-$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2)}"
WIDTH="${WIDTH:-999}"

if [ "${1:-}" = "--guard" ]; then
  [ "$WIDTH" -lt 144 ] || exit 1
  exit 0
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/kimi.sh" >/dev/null 2>&1 || true
"$SCRIPT_DIR/deepseek.sh" >/dev/null 2>&1 || true

STATE_DIR="$HOME/.local/state/starship"
KIMI=$(jq -r '.total_balance // empty' "$STATE_DIR/kimi-balance.json" 2>/dev/null) || KIMI=""
DEEPSEEK=$(jq -r '.total_balance // empty' "$STATE_DIR/deepseek-balance.json" 2>/dev/null) || DEEPSEEK=""

if [ -z "$KIMI" ] && [ -z "$DEEPSEEK" ]; then
  exit 1
fi

TOTAL=$(awk -v a="${KIMI:-0}" -v b="${DEEPSEEK:-0}" 'BEGIN { printf "%.2f", a + b }')
printf "󰭦 %s" "$TOTAL"
