#!/bin/bash

# Starship custom module: DeepSeek account balance
set -euo pipefail

# COLUMNS is usually not exported and starship runs without a controlling tty,
# so only probe stty when stdin really is a terminal. Referring to /dev/tty
# directly would make the redirect itself fail and abort under set -e, which
# made the 999 fallback below unreachable.
WIDTH="${COLUMNS:-}"
if [ -z "$WIDTH" ] && [ -t 0 ]; then
  WIDTH=$(stty size | cut -d' ' -f2 || true)
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
