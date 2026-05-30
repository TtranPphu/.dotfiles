#!/bin/bash

set -x

# Starship custom module: DeepSeek account balance
set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"
TOKEN=$(grep -oP '"ANTHROPIC_AUTH_TOKEN"\s*:\s*"\K[^"]+' "$SETTINGS_FILE" 2>/dev/null) || exit 1

STATE_DIR="$HOME/.local/state/starship"
STATE_FILE="$STATE_DIR/deepseek-balance.json"
CACHE_TTL=300

refresh_cache() {
  mkdir -p "$STATE_DIR"
  local tmp
  tmp=$(mktemp) || return 1
  curl -sfL -X GET 'https://api.deepseek.com/user/balance' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $TOKEN" 2>/dev/null \
    | jq '{total_balance: (.balance_infos[0].total_balance | tonumber), last_update: (now | floor)}' > "$tmp" \
    && mv "$tmp" "$STATE_FILE" \
    || rm -f "$tmp"
}

if [ -f "$STATE_FILE" ]; then
  BALANCE=$(jq -r '.total_balance // empty' "$STATE_FILE" 2>/dev/null) || BALANCE=""
  CACHE_TIME=$(jq -r '.last_update // 0' "$STATE_FILE" 2>/dev/null) || CACHE_TIME=0
  NOW=$(date +%s)
  AGE=$((NOW - CACHE_TIME))

  if [ "$AGE" -ge "$CACHE_TTL" ]; then
    refresh_cache &>/dev/null &
  fi

  if [ -n "$BALANCE" ]; then
    printf "\$%.2f" "$BALANCE"
    exit 0
  fi
fi

refresh_cache &>/dev/null &
exit 1
