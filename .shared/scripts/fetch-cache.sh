#!/usr/bin/env bash
# Fetch cache for the starship and tmux utils (sourced, not executed).
#
# Two modes:
#  - TTL cache (battery, BT devices, quotas): the read path never waits — it
#    prints the cached value immediately and, when the entry is missing, empty
#    or older than the TTL, spawns a detached refresh (the same util with
#    --refresh) that fetches the real value into the cache.
#  - Live-with-timeout (git, language): the value is fetched live on every
#    call, bounded by FETCH_LIVE_TIMEOUT; a timeout or fetch failure falls
#    back to the last known good value (see fetch_live below).
#
# The refresher is setsid-detached with stdin/stdout/stderr on /dev/null: it
# does not hold starship's output pipe open and survives starship's timeout
# kill. A non-blocking flock keeps at most one refresh per cache file running.
# Entries are "<unix-ts>\n<value>" (the value may be multi-line), written
# atomically (tmp + mv).
#
# Files live in ${XDG_STATE_HOME:-$HOME/.local/state}/starship — the directory
# the quota and ssh-quality utils already cache in. Keys carry only what the
# fetched value depends on (name + cwd hash for cwd-dependent fetches): layout
# and client identity gate rendering, not fetching.
set -u

FETCH_CACHE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/starship"

# fetch_cache_path <name> [<extra>] -> cache file path. <extra> is sanitized;
# it carries the fetch-relevant key (cwd hash), never layout or client tokens.
fetch_cache_path() {
  local name=$1 extra=${2:-}
  extra="${extra//[^a-zA-Z0-9]/_}"
  printf '%s/%s%s.cache' "$FETCH_CACHE_DIR" "$name" "${extra:+.$extra}"
}

# fetch_cache_cwd — stable short key for the current directory (cwd-dependent
# fetches): a builtin rolling hash, so nothing forks.
fetch_cache_cwd() {
  local h=0 i c
  for ((i = 0; i < ${#PWD}; i++)); do
    printf -v c '%d' "'${PWD:i:1}"
    h=$(( (h * 31 + c) & 0x7fffffff ))
  done
  printf '%s' "$h"
}

# _fetch_cache_value <file> <var> — set <var> to the stored value (everything
# after the first line; multi-line values survive).
_fetch_cache_value() {
  local content
  content=$(<"$1")
  case "$content" in
    *$'\n'*) content=${content#*$'\n'} ;;
    *) content= ;;
  esac
  printf -v "$2" '%s' "$content"
}

# fetch_read <file> <ttl> <refresh-cmd...>
# Print the cached value (stale is fine), spawn the refresh command detached
# when the entry is missing, empty or older than <ttl>, and exit 1 when there
# is nothing to show yet.
fetch_read() {
  local file=$1 ttl=$2 ts value now
  shift 2
  if [ -f "$file" ]; then
    IFS= read -r ts <"$file" || true
    _fetch_cache_value "$file" value
    [ -n "$value" ] && printf '%s' "$value"
    case "${ts:-}" in '' | *[!0-9]*) ts=0 ;; esac
    now=$(printf '%(%s)T' -1)
    if [ -z "$value" ] || [ "$((now - ts))" -ge "$ttl" ]; then
      fetch_spawn "$@"
    fi
    [ -n "$value" ] || return 1
    return 0
  fi
  fetch_spawn "$@"
  return 1
}

# fetch_display <name> <ttl> [<extra>] — the util-facing read path: resolve the
# cache file for <name> and serve it, spawning this util's --refresh on a miss,
# empty or stale entry.
fetch_display() {
  local name=$1 ttl=$2 extra=${3:-} file
  file=$(fetch_cache_path "$name" "$extra")
  fetch_read "$file" "$ttl" "$0" --refresh "$file"
}

# fetch_has_value <file> — exit 0 when the entry holds a non-empty value.
fetch_has_value() {
  local value
  [ -f "$1" ] || return 1
  _fetch_cache_value "$1" value
  [ -n "$value" ]
}

# fetch_spawn <cmd...> — run the refresher detached in a new session with
# stdio on /dev/null, so the caller returns immediately and the child survives
# starship's timeout kill.
fetch_spawn() {
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" </dev/null >/dev/null 2>&1 &
  else
    "$@" </dev/null >/dev/null 2>&1 &
  fi
}

# fetch_refresh <file> <fetch-fn> [args...] — run the fetch function, then
# store its output atomically; a non-blocking flock drops concurrent
# refreshes. Called from a util's --refresh path (the detached child).
fetch_refresh() {
  local file=$1 fn=$2 value ts tmp
  shift 2
  [ -d "$FETCH_CACHE_DIR" ] || mkdir -p "$FETCH_CACHE_DIR"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$file.lock"
    flock -n 9 || return 0
  fi
  value=$("$fn" "$@") || value=""
  ts=$(printf '%(%s)T' -1)
  tmp="$file.$$"
  printf '%s\n' "$ts" >"$tmp" && printf '%s\n' "$value" >>"$tmp" && mv -f "$tmp" "$file" || rm -f "$tmp"
}

# ---------------------------------------------------------------------------
# Live fetch with a timeout and a last-known-good fallback.
#
# Used by the utils that must be current on every render (git, language): the
# value is fetched live, bounded by FETCH_LIVE_TIMEOUT, and stored on success;
# a timed-out or failed fetch falls back to the last known good value, which
# the caller renders dimmed with the stale marker.
#
# Util contract:
#   <util>          -> live fetch, bounded by FETCH_LIVE_TIMEOUT:
#                      exit 0: live value printed (and stored)
#                      exit 3: live timed out/failed; the last known good
#                              value is printed instead (stale)
#                      exit 1: nothing to show (no repo / no languages, or a
#                              timeout with no cached value)
#   <util> --fresh  -> internal: the unbounded probe (run under the timeout)
FETCH_LIVE_TIMEOUT=0.1

# fetch_cache_store <file> <value> — write "<ts>\n<value>" atomically.
fetch_cache_store() {
  local file=$1 value=$2 ts tmp
  [ -d "$FETCH_CACHE_DIR" ] || mkdir -p "$FETCH_CACHE_DIR"
  ts=$(printf '%(%s)T' -1)
  tmp="$file.$$"
  printf '%s\n' "$ts" >"$tmp" && printf '%s\n' "$value" >>"$tmp" && mv -f "$tmp" "$file" || rm -f "$tmp"
}

# fetch_live <file> <fresh-cmd...> — see the util contract above.
fetch_live() {
  local file=$1 rc=0 value
  shift
  if command -v timeout >/dev/null 2>&1; then
    value=$(timeout "$FETCH_LIVE_TIMEOUT" "$@") || rc=$?
  else
    value=$("$@") || rc=$?
  fi
  if [ "$rc" -eq 0 ]; then
    fetch_cache_store "$file" "$value"
    printf '%s' "$value"
    return 0
  fi
  if [ "$rc" -eq 1 ]; then
    return 1
  fi
  _fetch_cache_value "$file" value
  [ -n "$value" ] || return 1
  printf '%s' "$value"
  return 3
}
