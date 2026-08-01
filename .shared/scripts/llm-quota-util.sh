#!/usr/bin/env bash
set -euo pipefail

cache_dir="$HOME/.local/state/starship"
cache="$cache_dir/llm-quota.json"
lock="$cache_dir/llm-quota.lock"
ttl=300

usage() {
  echo "usage: llm-quota-util.sh --get kimi|deepseek|--total" >&2
  exit 1
}

load_keys() {
  local keys_file="$HOME/.config/keys.zsh"
  [ -f "$keys_file" ] && source "$keys_file"
  local local_keys="$HOME/.config/keys.local.zsh"
  [ -f "$local_keys" ] && source "$local_keys"
}

fetch_one() {
  # $1: kimi|deepseek — prints the balance or exits 1
  local provider=$1 token url filter tmp
  case "$provider" in
    kimi)
      token="${KIMI_API_KEY:-}"
      url='https://api.moonshot.ai/v1/users/me/balance'
      filter='.data.available_balance'
      ;;
    deepseek)
      token="${DEEPSEEK_API_KEY:-}"
      url='https://api.deepseek.com/user/balance'
      filter='.balance_infos[0].total_balance'
      ;;
    *) return 1 ;;
  esac
  [ -n "$token" ] || return 1
  tmp=$(mktemp) || return 1
  if curl -sfL -X GET "$url" \
      -H 'Accept: application/json' \
      -H "Authorization: Bearer $token" 2>/dev/null |
      jq -r "$filter | tonumber" 2>/dev/null >"$tmp"; then
    cat "$tmp"
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"
  return 1
}

write_cache() {
  # $1: kimi balance, $2: deepseek balance
  mkdir -p "$cache_dir"
  local tmp
  tmp=$(mktemp) || return 1
  jq -n --arg k "$1" --arg d "$2" --argjson t "$(date +%s)" \
    '{kimi: $k, deepseek: $d, last_update: $t}' >"$tmp" &&
    mv "$tmp" "$cache" ||
    rm -f "$tmp"
}

refresh() {
  # Fetch both balances and store, guarded by a lock so concurrent
  # modules trigger at most one network round-trip
  (
    mkdir "$lock" 2>/dev/null || exit 0
    local kimi="" deepseek=""
    kimi=$(fetch_one kimi) || kimi=""
    deepseek=$(fetch_one deepseek) || deepseek=""
    if [[ -n "$kimi" || -n "$deepseek" ]]; then
      write_cache "$kimi" "$deepseek"
    fi
    rmdir "$lock" 2>/dev/null || true
  )
}

get_balance() {
  # $1: kimi|deepseek — prints cached balance; refreshes as needed
  local key=$1 val ts now
  now=$(date +%s)
  if [[ -f $cache ]]; then
    ts=$(jq -r '.last_update // 0' "$cache" 2>/dev/null) || ts=0
    val=$(jq -r --arg k "$key" '.[$k] // empty' "$cache" 2>/dev/null) || val=""
    if (( now - ts < ttl )); then
      [[ -n "$val" ]] || return 1
      printf '%s' "$val"
      return 0
    fi
    refresh &>/dev/null &
    [[ -n "$val" ]] || return 1
    printf '%s' "$val"
    return 0
  fi
  # No cache — block on refresh so the module appears on first invocation
  refresh
  val=$(jq -r --arg k "$key" '.[$k] // empty' "$cache" 2>/dev/null) || val=""
  [[ -n "$val" ]] || return 1
  printf '%s' "$val"
  return 0
}

total() {
  local kimi="" deepseek=""
  kimi=$(get_balance kimi) || kimi=""
  deepseek=$(get_balance deepseek) || deepseek=""
  [[ -n "$kimi" || -n "$deepseek" ]] || return 1
  awk -v a="${kimi:-0}" -v b="${deepseek:-0}" 'BEGIN { printf "%.2f", a + b }'
}

load_keys
case "${1:-}" in
  --get) [ $# -eq 2 ] || usage; get_balance "$2" ;;
  --total) total ;;
  *) usage ;;
esac
