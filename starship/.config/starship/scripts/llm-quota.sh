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
TOTAL=$("$SCRIPT_DIR/llm-quota-util.sh" --total) || exit 1
printf "%s" "$TOTAL"
