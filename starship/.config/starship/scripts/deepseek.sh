#!/bin/bash

# Starship custom module: DeepSeek account balance
set -euo pipefail

# Width decides which modules render: combined below 144 columns, per-provider
# above. COLUMNS is rarely exported, and the controlling terminal is the right
# source rather than stdin, which starship does not attach to a tty. The probe
# is wrapped so its failure cannot abort under set -e before the fallback.
WIDTH="${COLUMNS:-}"
if [ -z "$WIDTH" ]; then
  WIDTH=$( { stty size < /dev/tty 2>/dev/null; } 2>/dev/null | cut -d' ' -f2 || true)
fi
WIDTH="${WIDTH:-999}"

# Exit 0 only when wide enough, provider configured, and funded, so the module
# is skipped cleanly instead of rendering its format's literal space around
# empty output.
if [ "${1:-}" = "--guard" ]; then
  [ "$WIDTH" -ge 144 ] || exit 1
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  "$SCRIPT_DIR/llm-quota-util.sh" --configured deepseek || exit 1
  BALANCE=$("$SCRIPT_DIR/llm-quota-util.sh" --get deepseek) || exit 1
  awk -v v="${BALANCE:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  exit 0
fi

# Only show when deepseek is configured in opencode
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/llm-quota-util.sh" --configured deepseek || exit 1

BALANCE=$("$SCRIPT_DIR/llm-quota-util.sh" --get deepseek) || exit 1
awk -v v="${BALANCE:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
printf "󰫣 %.2f" "$BALANCE"
