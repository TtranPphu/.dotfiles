#!/usr/bin/env bash
# OpenCode Go quota.
#
# The cache stores the raw API "used" percentages, so existing caches remain
# valid. --values prints the remaining percent (100 - used) for each window.
set -euo pipefail

cache_dir="$HOME/.local/state/starship"
cache="$cache_dir/opencode-quota.json"
lock="$cache_dir/opencode-quota.lock"
ttl=300

usage() {
  echo "usage: opencode-quota-util.sh --values" >&2
  echo "  cache holds used percent; --values prints remaining percent" >&2
  exit 1
}

load_keys() {
  local keys_file="$HOME/.config/keys.zsh"
  [ -f "$keys_file" ] && source "$keys_file"
  local local_keys="$HOME/.config/keys.local.zsh"
  [ -f "$local_keys" ] && source "$local_keys"
}

fetch_values() {
  # Prints used "rolling weekly monthly" percentages or exits 1
  local token tmp out
  token="${OPENCODE_API_KEY:-}"
  [ -n "$token" ] || return 1
  mkdir -p "$cache_dir"
  tmp=$(mktemp "$cache_dir/opencode-quota.XXXXXX") || return 1
  if curl -sfL --max-time 5 -X GET 'https://opencode.ai/zen/go/v1/usage' \
      -H 'Accept: application/json' \
      -H "Authorization: Bearer $token" 2>/dev/null |
      jq -r '[.usage.rolling.percent, .usage.weekly.percent, .usage.monthly.percent] | map(tonumber) | join(" ")' 2>/dev/null >"$tmp"; then
    out=$(cat "$tmp")
    if [[ -n "$out" ]]; then
      printf '%s' "$out"
      rm -f "$tmp"
      return 0
    fi
  fi
  rm -f "$tmp"
  return 1
}

write_cache() {
  # $1: rolling used %, $2: weekly used %, $3: monthly used %
  mkdir -p "$cache_dir"
  local tmp
  tmp=$(mktemp "$cache_dir/opencode-quota.XXXXXX") || return 1
  jq -n --argjson r "$1" --argjson w "$2" --argjson m "$3" --argjson t "$(date +%s)" \
    '{rolling: $r, weekly: $w, monthly: $m, last_update: $t}' >"$tmp" &&
    mv "$tmp" "$cache" ||
    rm -f "$tmp"
}

refresh() {
  # Fetch usage and store, guarded by an flock so concurrent modules trigger
  # at most one network round-trip. flock (unlike a mkdir lock) is released
  # automatically if the process dies, so it can never go stale.
  mkdir -p "$cache_dir"
  (
    exec 9>"$lock"
    flock -n 9 || exit 0
    local values r w m
    values=$(fetch_values) || values=""
    if [[ -n "$values" ]]; then
      read -r r w m <<<"$values"
      if [[ -n "$r" && -n "$w" && -n "$m" ]]; then
        write_cache "$r" "$w" "$m" || true
      fi
    fi
  )
}

refresh_async() {
  # Stale-while-revalidate: fetch in a detached background process so callers
  # return immediately. stdout/stderr are discarded so the background job does
  # not hold the caller's pipe open (starship would otherwise wait for EOF).
  refresh >/dev/null 2>&1 & disown
}

cached_values() {
  # Prints remaining "rolling weekly monthly" percent from the used cache;
  # exits 1 when unavailable
  local r w m
  r=$(jq -r '.rolling // empty' "$cache" 2>/dev/null) || return 1
  w=$(jq -r '.weekly // empty' "$cache" 2>/dev/null) || return 1
  m=$(jq -r '.monthly // empty' "$cache" 2>/dev/null) || return 1
  [[ -n "$r" && -n "$w" && -n "$m" ]] || return 1
  printf '%s %s %s' "$((100 - r))" "$((100 - w))" "$((100 - m))"
}

get_values() {
  # Prints remaining "rolling weekly monthly" immediately; when the cache is
  # stale, revalidates in the background and serves the stale values meanwhile
  local ts now
  now=$(date +%s)
  if [[ -f $cache ]]; then
    ts=$(jq -r '.last_update // 0' "$cache" 2>/dev/null) || ts=0
    if (( now - ts >= ttl )); then
      refresh_async
    fi
    cached_values
    return 0
  fi
  # No cache — refresh in the background; the module appears on a later prompt
  refresh_async
  return 1
}

load_keys
case "${1:-}" in
  --values) get_values ;;
  *) usage ;;
esac
