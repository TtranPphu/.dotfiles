#!/bin/bash

# Starship custom module: combined LLM account balance on narrow terminals
set -euo pipefail

WIDTH="${COLUMNS:-$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2)}"
WIDTH="${WIDTH:-999}"

# Exit 0 only when narrow enough and a total exists, so the module is skipped
# cleanly instead of rendering its format's literal space around empty output.
if [ "${1:-}" = "--guard" ]; then
  [ "$WIDTH" -lt 144 ] || exit 1
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  TOTAL=$("$SCRIPT_DIR/llm-quota-util.sh" --total) || exit 1
  awk -v v="${TOTAL:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  exit 0
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TOTAL=$("$SCRIPT_DIR/llm-quota-util.sh" --total) || exit 1
awk -v v="${TOTAL:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf "%s" "$TOTAL"
