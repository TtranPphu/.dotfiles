#!/usr/bin/env bash
# Prerequisite cache for the tmux status scripts (sourced, not executed).
#
# The status scripts render live on every redraw; only slow, rarely-changing
# prerequisites are cached here: the per-client nerd-font type (a ~10 ms tmux
# client scan) and catalog glyphs. cache_cmd reads the cached stdout of a
# command with bash builtins and spawns a detached refresh when the entry is
# missing or older than its TTL; the spawned child runs this file with --cmd.
#
# The refresher is setsid-detached with stdin/stdout/stderr on /dev/null: it
# does not hold tmux's output pipe open and survives the status command
# exiting. Entries are "<unix-ts>\t<value>", written atomically (tmp + mv).
#
# Files live in $XDG_RUNTIME_DIR/tmux-status (fallback $XDG_CACHE_HOME, then
# ~/.cache) — never /tmp.

_CACHE_SH="${BASH_SOURCE[0]}"
CACHE_DIR="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/tmux-status"

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
  cache_cmd "$CACHE_DIR/$key.out" 600 "$dir/icon.sh" type "$socket" "$pid"
  STATUS_NERD_FONT_TYPE=$CACHED_VALUE
}

# status_nerd_font_glyph <dir> <key> — set STATUS_NERD_FONT_GLYPH to the icon
# for <key> in the already-resolved type, from a loose cache. Needs
# STATUS_NERD_FONT_TYPE and DOTFILES_NERD_FONT exported so the refresher
# resolves the same type; saves sourcing icon.sh and its per-icon awk on
# the live display path.
status_nerd_font_glyph() {
  local dir=$1 key=$2
  cache_cmd "$CACHE_DIR/nerd-font-glyph.${STATUS_NERD_FONT_TYPE:-none}.${key//[^a-zA-Z0-9]/_}.out" 600 \
    "$dir/icon.sh" get "$key"
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
