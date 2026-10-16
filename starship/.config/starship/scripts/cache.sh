#!/usr/bin/env bash
# Two-pass cache for starship custom modules (sourced, not executed).
#
# The prompt must never wait: a module's display path only reads its cache
# file and, when the entry is missing or older than the module's TTL, spawns a
# detached refresh that renders the real value into the cache. The first pass
# after a miss shows nothing; the next prompt shows the value (one refresh
# stale is fine). All slow work — git, DBus, SSH, version probes, network —
# happens in the detached refresher.
#
# The refresher is setsid-detached with stdin/stdout/stderr on /dev/null: it
# does not hold starship's output pipe open and survives starship's timeout
# kill. A non-blocking flock keeps at most one refresh per cache file running.
# Entries are "<unix-ts>\t<value>", written atomically (tmp + mv).
#
# Files live in $XDG_RUNTIME_DIR/starship (fallback $XDG_CACHE_HOME, then
# ~/.cache) — never /tmp. Keys are sanitized to [A-Za-z0-9_]; compose them
# from starship_cache_client, starship_cache_cwd and, for modules whose
# output depends on it, the layout size.

# Cache directory, created on first use.
starship_cache_dir() {
  local dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/starship"
  [ -d "$dir" ] || mkdir -p "$dir"
  printf '%s' "$dir"
}

# Cheap per-terminal token: rendered icons depend on the resolved nerd-font
# type, which is per client. The refresher resolves the type fully; this token
# only keeps two clients from sharing a cache entry.
starship_cache_client() {
  printf '%s' "${DOTFILES_NERD_FONT:-auto}:${SSH_CONNECTION:-${SSH_CLIENT:-local}}:${NERD_FONT_SOCKET:-}"
}

# Stable short key for the current directory (cwd-dependent modules).
starship_cache_cwd() {
  local sum
  sum=$(printf '%s' "$PWD" | cksum)
  printf '%s' "${sum%% *}"
}

# starship_cache_path <name> [<key>] -> cache file path.
starship_cache_path() {
  local name=$1 key=${2:-} dir
  key="${key//[^a-zA-Z0-9]/_}"
  dir=$(starship_cache_dir)
  printf '%s/%s%s.out' "$dir" "$name" "${key:+.$key}"
}

# cache_display <file> <ttl> <refresh-cmd...>
# Print the cached value (stale is fine), spawn the refresh command detached
# when the entry is missing or older than <ttl>, and exit 1 when there is
# nothing to show yet.
cache_display() {
  local file=$1 ttl=$2 ts value now
  shift 2
  if [ -f "$file" ]; then
    IFS=$'\t' read -r ts value <"$file" || true
    printf '%s' "$value"
    case "${ts:-}" in '' | *[!0-9]*) ts=0 ;; esac
    now=$(printf '%(%s)T' -1)
    if [ "$((now - ts))" -ge "$ttl" ]; then
      cache_spawn "$@"
    fi
    [ -n "$value" ] || return 1
    return 0
  fi
  cache_spawn "$@"
  return 1
}

# cache_gate <file> <ttl> <refresh-cmd...>
# The guard half of the cache: exit 0 only when a non-empty value is cached,
# so the prompt skips the module instead of rendering its format around an
# empty output. Spawns the refresh detached when the entry is missing or older
# than <ttl> — the guard is what keeps the cache warm.
cache_gate() {
  local file=$1 ttl=$2 ts value now
  shift 2
  if [ -f "$file" ]; then
    IFS=$'\t' read -r ts value <"$file" || true
    case "${ts:-}" in '' | *[!0-9]*) ts=0 ;; esac
    now=$(printf '%(%s)T' -1)
    if [ "$((now - ts))" -ge "$ttl" ]; then
      cache_spawn "$@"
    fi
  else
    cache_spawn "$@"
  fi
  [ -n "$value" ] || return 1
  return 0
}

# cache_spawn <cmd...> — run the refresher detached in a new session with
# stdio on /dev/null, so the prompt returns immediately and the child survives
# starship's timeout kill.
cache_spawn() {
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" </dev/null >/dev/null 2>&1 &
  else
    "$@" </dev/null >/dev/null 2>&1 &
  fi
}

# cache_refresh <file> <render-fn> [args...] — run the render function, then
# store its output atomically; a non-blocking flock drops concurrent
# refreshes. Called from a module's --refresh path (the detached child).
cache_refresh() {
  local file=$1 fn=$2 value ts tmp
  shift 2
  starship_cache_dir >/dev/null
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$file.lock"
    flock -n 9 || return 0
  fi
  value=$("$fn" "$@") || value=""
  ts=$(printf '%(%s)T' -1)
  tmp="$file.$$"
  printf '%s\t%s\n' "$ts" "$value" >"$tmp" && mv -f "$tmp" "$file" || rm -f "$tmp"
}
