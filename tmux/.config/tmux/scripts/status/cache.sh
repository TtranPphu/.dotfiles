#!/usr/bin/env bash
# Two-pass cache for tmux status scripts (sourced, not executed).
#
# tmux re-runs status #() commands on redraws, not only on status-interval,
# so a status script must never block: the display path only reads its cache
# file and, when the entry is missing or older than the script's TTL, spawns
# a detached refresher that renders the real value into the cache. The first
# pass after a miss shows nothing (or a cheap fallback); a later redraw shows
# the value — one refresh stale is fine.
#
# The refresher is setsid-detached with stdin/stdout/stderr on /dev/null: it
# does not hold tmux's output pipe open and survives the status command
# exiting (tmux kills the job's process group on cleanup; a new session does
# not belong to it). A non-blocking flock keeps at most one refresh per cache
# file running. Entries are "<unix-ts>\t<value>", written atomically
# (tmp + mv).
#
# Files live in $XDG_RUNTIME_DIR/tmux-status (fallback $XDG_CACHE_HOME, then
# ~/.cache) — never /tmp. The display path uses bash builtins only (read,
# printf), so a warm redraw costs little more than bash startup.
#
# Usage in a status script:
#   script_dir=...; source "$script_dir/cache.sh"
#   render() { ...print the status text...; }          # runs in the refresher
#   key="name.${1:-}.${2:-}.${DOTFILES_NERD_FONT:-auto}"   # every arg that
#   key="${key//[^a-zA-Z0-9]/_}"                           # changes output
#   case "${1:-}" in
#     --refresh) cache_refresh "${2:?}" render "${@:3}" ;;
#     *) cache_display "$CACHE_DIR/$key.out" 60 \
#          "$0" --refresh "$CACHE_DIR/$key.out" "$@" ;;
#   esac
#
# cache_cmd caches the stdout of an external command the same way (used for
# the slow prerequisites, e.g. nerd-font type and layout size); the spawned
# child runs this file with --cmd, so cache.sh doubles as its own refresher.

_CACHE_SH="${BASH_SOURCE[0]}"
CACHE_DIR="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/tmux-status"

# cache_display <file> <ttl> <refresh-cmd...>
# Print the cached value (stale is fine), spawn the refresh command detached
# when the entry is missing or older than <ttl>, and return 1 when there is
# nothing to show yet.
cache_display() {
  local file=$1 ttl=$2 ts value now
  shift 2
  [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR"
  if [ -f "$file" ]; then
    IFS=$'\t' read -r ts value <"$file" || true
    printf '%s' "$value"
    case "${ts:-}" in '' | *[!0-9]*) ts=0 ;; esac
    printf -v now '%(%s)T' -1
    if [ "$((now - ts))" -ge "$ttl" ]; then
      cache_spawn "$@"
    fi
    [ -n "$value" ] || return 1
    return 0
  fi
  cache_spawn "$@"
  return 1
}

# cache_spawn <cmd...> — run the refresher detached in a new session with
# stdio on /dev/null, so the status command returns immediately and the child
# survives its parent's exit.
cache_spawn() {
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" </dev/null >/dev/null 2>&1 &
  else
    "$@" </dev/null >/dev/null 2>&1 &
  fi
}

# cache_refresh <file> <render-fn> [args...] — run the render function, then
# store its output atomically; a non-blocking flock drops concurrent
# refreshes. Called from a script's --refresh path (the detached child).
cache_refresh() {
  local file=$1 fn=$2 value ts tmp
  shift 2
  [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$file.lock"
    flock -n 9 || return 0
  fi
  value=$("$fn" "$@") || value=""
  printf -v ts '%(%s)T' -1
  tmp="$file.$$"
  printf '%s\t%s\n' "$ts" "$value" >"$tmp" && mv -f "$tmp" "$file" || rm -f "$tmp"
}

# cache_cmd <file> <ttl> <cmd...> — set CACHED_VALUE to the cached stdout of
# <cmd> (builtin read, a few ms warm); spawn a detached refresh when the entry
# is missing or older than <ttl>, and run <cmd> inline when nothing is cached
# yet so the first pass is still correct.
cache_cmd() {
  local file=$1 ttl=$2 ts value now
  shift 2
  [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR"
  if [ -f "$file" ]; then
    IFS=$'\t' read -r ts value <"$file" || true
    case "${ts:-}" in '' | *[!0-9]*) ts=0 ;; esac
    printf -v now '%(%s)T' -1
    if [ "$((now - ts))" -ge "$ttl" ]; then
      cache_spawn "$_CACHE_SH" --cmd "$file" "$@"
    fi
    CACHED_VALUE=$value
    return 0
  fi
  cache_spawn "$_CACHE_SH" --cmd "$file" "$@"
  CACHED_VALUE=$("$@") || CACHED_VALUE=""
}

# cache_refresh_cmd <file> <cmd...> — run <cmd>, then store its output
# atomically; a non-blocking flock drops concurrent refreshes. Called from
# the detached child (cache.sh --cmd ...).
cache_refresh_cmd() {
  local file=$1 value ts tmp
  shift
  [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$file.lock"
    flock -n 9 || return 0
  fi
  value=$("$@") || value=""
  printf -v ts '%(%s)T' -1
  tmp="$file.$$"
  printf '%s\t%s\n' "$ts" "$value" >"$tmp" && mv -f "$tmp" "$file" || rm -f "$tmp"
}

# status_nerd_font_type <dir> <socket> <client-pid> — set STATUS_NERD_FONT_TYPE
# from a loose cache: the type only changes when the client's font config
# does, and the key covers the arguments that change the answer. Falls back to
# the live resolution when nothing is cached yet.
status_nerd_font_type() {
  local dir=$1 socket=$2 pid=$3 key
  key="nerd-font-type.${socket//[^a-zA-Z0-9]/_}.${pid:-none}.${DOTFILES_NERD_FONT:-auto}"
  cache_cmd "$CACHE_DIR/$key.out" 600 "$dir/nerd-font.sh" type "$socket" "$pid"
  STATUS_NERD_FONT_TYPE=$CACHED_VALUE
}

# status_layout_size <dir> <width> — set STATUS_LAYOUT_SIZE from a loose cache:
# the size is a pure function of the width, the thresholds only change when
# the layout config does. Falls back to the live call when nothing is cached.
status_layout_size() {
  local dir=$1 width=$2
  cache_cmd "$CACHE_DIR/layout-size.${width//[^a-zA-Z0-9]/_}.out" 600 \
    "$dir/layout.sh" size "$width"
  STATUS_LAYOUT_SIZE=${CACHED_VALUE:-$("$dir/layout.sh" size "$width")}
}

# status_nerd_font_glyph <dir> <key> — set STATUS_NERD_FONT_GLYPH to the icon
# for <key> in the already-resolved type, from a loose cache. Needs
# STATUS_NERD_FONT_TYPE and DOTFILES_NERD_FONT exported so the refresher
# resolves the same type; saves sourcing nerd-font.sh and its per-icon awk on
# the live display path.
status_nerd_font_glyph() {
  local dir=$1 key=$2
  cache_cmd "$CACHE_DIR/nerd-font-glyph.${STATUS_NERD_FONT_TYPE:-none}.${key//[^a-zA-Z0-9]/_}.out" 600 \
    "$dir/nerd-font.sh" get "$key"
  STATUS_NERD_FONT_GLYPH=$CACHED_VALUE
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    --cmd) shift; cache_refresh_cmd "$@" ;;
    *)
      echo "usage: $0 --cmd <file> <command...>" >&2
      exit 2
      ;;
  esac
fi
