#!/usr/bin/env bash
set -euo pipefail

cache="$HOME/.local/state/starship/kimi-balance.json"
cache_ttl=300

refresh_cache() {
  local token
  local keys_file="$HOME/.config/keys.zsh"
  [ -f "$keys_file" ] && source "$keys_file"
  local local_keys="$HOME/.config/keys.local.zsh"
  [ -f "$local_keys" ] && source "$local_keys"
  token="${KIMI_API_KEY:-}" || return 1
  mkdir -p "$(dirname "$cache")"
  local tmp
  tmp=$(mktemp) || return 1
  curl -sfL -X GET 'https://api.moonshot.ai/v1/users/me/balance' \
    -H 'Accept: application/json' \
    -H "Authorization: Bearer $token" 2>/dev/null |
    jq '{total_balance: (.data.available_balance | tonumber), last_update: (now | floor)}' >"$tmp" &&
    mv "$tmp" "$cache" ||
    rm -f "$tmp"
}

render() {
  local balance=$1 width=${STATUS_WIDTH:-999}
  if (( width < 120 )); then
    printf '#[fg=brightblack,bold,bg=cyan] %d #[default]' "${balance%.*}"
  else
    printf '#[fg=brightblack,bold,bg=cyan]  %.2f #[default]' "$balance"
  fi
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
    render "$balance"
    exit 0
  fi
fi

# No valid cache — block on refresh so the module appears on first invocation
refresh_cache 2>/dev/null || true
balance=$(jq -r '.total_balance // empty' "$cache" 2>/dev/null) || balance=""
if [[ -n "$balance" ]]; then
  render "$balance"
  exit 0
fi
exit 1
