#!/bin/bash

# Starship custom module: combined LLM account balance (medium terminals)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "--guard" ]; then
  [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
  "$SCRIPT_DIR/layout.sh" is medium || exit 1
  TOTAL=$("$SCRIPT_DIR/llm-quota-util.sh" --total) || exit 1
  awk -v v="${TOTAL:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  exit 0
fi

TOTAL=$("$SCRIPT_DIR/llm-quota-util.sh" --total) || exit 1
awk -v v="${TOTAL:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf "%s" "$TOTAL"
