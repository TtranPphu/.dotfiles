#!/bin/bash

# Starship custom module: Kimi account balance
set -euo pipefail

KEYS_FILE="$HOME/.config/keys.zsh"
[ -f "$KEYS_FILE" ] && source "$KEYS_FILE"
LOCAL_KEYS="$HOME/.config/keys.local.zsh"
[ -f "$LOCAL_KEYS" ] && source "$LOCAL_KEYS"
TOKEN="${KIMI_API_KEY:-}"

STATE_DIR="$HOME/.local/state/starship"
STATE_FILE="$STATE_DIR/kimi-balance.json"
CACHE_TTL=300

refresh_cache() {
  mkdir -p "$STATE_DIR"
  local tmp
  tmp=$(mktemp) || return 1
  curl -sfL -X GET 'https://api.moonshot.ai/v1/users/me/balance' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $TOKEN" 2>/dev/null |
    jq '{total_balance: (.data.available_balance | tonumber), last_update: (now | floor)}' >"$tmp" &&
    mv "$tmp" "$STATE_FILE" ||
    rm -f "$tmp"
}

WIDTH="${COLUMNS:-$(stty size < /dev/tty 2>/dev/null | cut -d' ' -f2)}"
WIDTH="${WIDTH:-999}"

render() {
  local balance=$1
  if (( WIDTH < 144 )); then
    printf "%s" "${balance%.*}"
  else
    printf " %.2f" "$balance"
  fi
}

if [ -f "$STATE_FILE" ]; then
  BALANCE=$(jq -r '.total_balance // empty' "$STATE_FILE" 2>/dev/null) || BALANCE=""
  CACHE_TIME=$(jq -r '.last_update // 0' "$STATE_FILE" 2>/dev/null) || CACHE_TIME=0
  NOW=$(date +%s)
  AGE=$((NOW - CACHE_TIME))

  if [ -n "$BALANCE" ]; then
    if [ "$AGE" -ge "$CACHE_TTL" ]; then
      refresh_cache &>/dev/null &
    fi
    render "$BALANCE"
    exit 0
  fi
fi

# No valid cache — block on refresh so the module appears on first invocation
refresh_cache 2>/dev/null || true
BALANCE=$(jq -r '.total_balance // empty' "$STATE_FILE" 2>/dev/null) || BALANCE=""
if [ -n "$BALANCE" ]; then
  render "$BALANCE"
  exit 0
fi
exit 1
