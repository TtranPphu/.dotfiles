#!/bin/bash

# Starship custom module: DeepSeek account balance (wide terminals)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/icons.sh"

if [ "${1:-}" = "--guard" ]; then
  [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
  "$SCRIPT_DIR/layout.sh" is wide || exit 1
  "$SCRIPT_DIR/llm-quota-util.sh" --configured deepseek || exit 1
  BALANCE=$("$SCRIPT_DIR/llm-quota-util.sh" --get deepseek) || exit 1
  awk -v v="${BALANCE:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  exit 0
fi

"$SCRIPT_DIR/llm-quota-util.sh" --configured deepseek || exit 1
BALANCE=$("$SCRIPT_DIR/llm-quota-util.sh" --get deepseek) || exit 1
awk -v v="${BALANCE:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf "%s %s%.2f" "$(icon deepseek)" "$(icon money)" "$BALANCE"
