#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone module
if [[ "${1:-}" == --guard ]]; then
  width=${STATUS_WIDTH:-999}
  [[ $width -ge 144 ]] || exit 1
  exit 0
fi

settings_file="$HOME/.claude/settings.json"
cache="$HOME/.local/state/starship/deepseek-balance.json"
cache_ttl=300

# Only show when deepseek is the active provider
grep -q 'deepseek.com' "$settings_file" 2>/dev/null || exit 1

refresh_cache() {
  local token
  local keys_file="$HOME/.config/keys.zsh"
  [ -f "$keys_file" ] && source "$keys_file"
  local local_keys="$HOME/.config/keys.local.zsh"
  [ -f "$local_keys" ] && source "$local_keys"
  token="${DEEPSEEK_API_KEY:-}" || return 1
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

render() {
  local balance=$1 width=${STATUS_WIDTH:-999}
  if (( width < 144 )); then
    printf '#[fg=brightblack,bold,bg=blue] %d #[default]' "${balance%.*}"
  else
    printf '#[fg=brightblack,bold,bg=blue]  %.2f #[default]' "$balance"
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
