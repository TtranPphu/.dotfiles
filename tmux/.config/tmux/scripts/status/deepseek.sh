#!/usr/bin/env bash
set -euo pipefail

settings_file="$HOME/.claude/settings.json"
cache="$HOME/.local/state/starship/deepseek-balance.json"
cache_ttl=300

refresh_cache() {
  local token
  token=$(grep -oP '"ANTHROPIC_AUTH_TOKEN"\s*:\s*"\K[^"]+' "$settings_file" 2>/dev/null) || return 1
  mkdir -p "$(dirname "$cache")"
  local tmp
  tmp=$(mktemp) || return 1
  curl -sfL -X GET 'https://api.deepseek.com/user/balance' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $token" 2>/dev/null |
    jq '{total_balance: (.balance_infos[0].total_balance | tonumber), last_update: (now | floor)}' >"$tmp" &&
    mv "$tmp" "$cache" ||
    rm -f "$tmp"
}

if [[ -f $cache ]]; then
  balance=$(jq -r '.total_balance // empty' "$cache" 2>/dev/null) || balance=""
  cache_time=$(jq -r '.last_update // 0' "$cache" 2>/dev/null) || cache_time=0
  now=$(date +%s)
  age=$((now - cache_time))

  if [[ -n "$balance" ]]; then
    if (( age >= cache_ttl )); then
      refresh_cache &>/dev/null &
    fi
    printf '#[fg=brightblack,bold,bg=blue]  %.2f ' "$balance"
    exit 0
  fi
fi

# No valid cache — block on refresh so the module appears on first invocation
refresh_cache 2>/dev/null || true
balance=$(jq -r '.total_balance // empty' "$cache" 2>/dev/null) || balance=""
if [[ -n "$balance" ]]; then
  printf '#[fg=brightblack,bold,bg=blue]  %.2f ' "$balance"
  exit 0
fi
exit 1
