#!/usr/bin/env bash
# Terminal font capability + icon catalog.
#
#   icon.sh mode [socket] [pid]      -> "nerd" | "lame"
#   icon.sh type [socket] [pid]      -> resolved type (lame|nerd|mono)
#   icon.sh client-id [socket] [pid] -> client identifier (SSH client IP, else "local")
#   icon.sh state-file        -> path to the client state file
#   icon.sh lookup <id>       -> stored type (lame|nerd|mono) or empty
#   icon.sh store <id> <type> -> record a type for a client id
#   icon.sh get KEY           -> glyph for KEY in the resolved type
#
# Sourced from bash it also defines nerd_font_mode / nerd_font_type /
# nerd_font_client_id / nerd_font_lookup / nerd_font_store / icon KEY.
#
# Resolution: $DOTFILES_NERD_FONT=nerd|mono|lame wins;
# otherwise the client's stored type in the state file; unknown clients resolve
# to "lame" until the shell setup prompt records a choice. A pid pins the
# lookup to that tmux client's environment, so each rendering client
# resolves its own type. State lines are id<TAB>type. The catalog is next to this file (icon.csv) with a matching
# header line and a dummy column after every value column: space-filled after
# the icon columns, empty after lame (the parser reads the odd columns):
# key;nerd;mono;lame. Empty mono cells fall back to the nerd column
# (same codepoints).
set -u

_nerd_font_self="$(readlink -f "${BASH_SOURCE[0]}")"
_nerd_font_dir="$(dirname -- "$_nerd_font_self")"
_nerd_font_catalog="${DOTFILES_NERD_FONT_CATALOG:-$_nerd_font_dir/icon.csv}"
_nerd_font_type_cache=""

# The fetch-cache engine (next to this file) caches the resolved client type.
[ -f "$_nerd_font_dir/fetch-cache.sh" ] && source "$_nerd_font_dir/fetch-cache.sh"

nerd_font_state_file() {
  printf '%s' "${DOTFILES_NERD_FONT_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/nerd-font-clients}"
}

nerd_font_client_id() {
  local sock="${1:-${NERD_FONT_SOCKET:-}}" pid="${2:-}" conn="" line

  clients_conn() {
    command -v tmux >/dev/null 2>&1 || return 1
    local tc=(tmux) p l
    [ -n "$sock" ] && tc=(tmux -S "$sock")
    for p in $("${tc[@]}" list-clients -F '#{client_pid}' 2>/dev/null); do
      l=$(tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | sed -n 's/^SSH_CONNECTION=//p')
      [ -n "$l" ] && { printf '%s' "$l"; return 0; }
    done
    return 1
  }

  # A rendering client's pid is authoritative: read its own environment.
  if [ -n "$pid" ]; then
    conn=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^SSH_CONNECTION=//p')
    if [ -n "$conn" ]; then printf '%s' "${conn%% *}"; else printf local; fi
    return 0
  fi

  if [ -n "$sock" ]; then
    # Called for a specific tmux server (status scripts): trust its clients.
    conn=$(clients_conn) || conn=""
  else
    # Interactive shell / prompt: our own connection wins, else this tmux's clients.
    conn="${SSH_CONNECTION:-${SSH_CLIENT:-}}"
    [ -z "$conn" ] && { conn=$(clients_conn) || conn=""; }
  fi

  if [ -n "$conn" ]; then printf '%s' "${conn%% *}"; else printf local; fi
}

nerd_font_lookup() {
  local f; f=$(nerd_font_state_file)
  [ -f "$f" ] || return 0
  awk -v id="$1" '$1 == id { t = $2 } END { if (t != "") print t }' "$f"
}

nerd_font_store() {
  local id="$1" type="$2" f tmp
  f=$(nerd_font_state_file)
  mkdir -p "$(dirname -- "$f")"
  tmp="$f.$$.tmp"
  if [ -f "$f" ]; then awk -v id="$id" '$1 != id' "$f" >"$tmp"; else : >"$tmp"; fi
  printf '%s\t%s\n' "$id" "$type" >>"$tmp"
  mv "$tmp" "$f"
}

# Normalize a stored/override value to the current type vocabulary.
nerd_font_type_normalize() {
  case "$1" in
    lame | nerd | mono) printf '%s' "$1" ;;
  esac
}

nerd_font_type_to_mode() {
  case "$1" in
    lame) printf lame ;;
    nerd | mono) printf nerd ;;
    *) printf lame ;;
  esac
}

# Live client resolution (no cache): the override wins, else the per-client
# type from the state file. Used by the `type` CLI (the setter path resolves
# live) and by the cache's refresher.
nerd_font_type_live() {
  local sock="${1:-}" pid="${2:-}" type
  type=$(nerd_font_type_normalize "${DOTFILES_NERD_FONT:-}")
  [ -n "$type" ] && { printf '%s' "$type"; return 0; }
  type=$(nerd_font_type_normalize "$(nerd_font_lookup "$(nerd_font_client_id "$sock" "$pid")")")
  printf '%s' "${type:-lame}"
}

# _nerd_font_cache_key <sock> <pid> <var> — set <var> to the cache key for the
# resolved type: the tmux status key shape plus the client identity (the SSH
# client's address, else "local"). The identity comes from the environment
# only — the tmux-client scan the live resolution falls back to is the ~9 ms
# cost this cache exists to avoid, so it is not run for the key (a local
# prompt sharing its tmux server with an attached SSH client can therefore
# read that client's entry).
_nerd_font_cache_key() {
  local conn="${SSH_CONNECTION:-${SSH_CLIENT:-}}" id
  id="${conn%% *}"
  printf -v "$3" 'nerd-font-type.%s.%s.%s.%s' \
    "${1//[^a-zA-Z0-9]/_}" "${2:-none}" "${DOTFILES_NERD_FONT:-auto}" "${id:-local}"
}

# Cached client resolution: the type only changes when the client's font
# config does, so it is cached as fetched data (fetch-cache.sh, 600 s — the
# same key shape and TTL as the tmux status cache) and refreshed in the
# background; a stale entry is served as-is and a cold miss resolves live once
# and stores. This keeps a module's icon lookup a file read instead of the
# ~10 ms tmux-client scan.
nerd_font_type_cached() {
  local sock="${1:-}" pid="${2:-}" key file value
  _nerd_font_cache_key "$sock" "$pid" key
  file=$(fetch_cache_path "$key")
  if fetch_read "$file" 600 "$_nerd_font_self" --cache-type "$sock" "$pid"; then
    return 0
  fi
  value=$(nerd_font_type_live "$sock" "$pid")
  fetch_cache_store "$file" "$value"
  printf '%s' "$value"
}

# Store the live type for the cached key (the detached refresher's entry).
nerd_font_type_cache_store() {
  local sock="${1:-}" pid="${2:-}" key
  _nerd_font_cache_key "$sock" "$pid" key
  fetch_refresh "$(fetch_cache_path "$key")" nerd_font_type_live "$sock" "$pid"
}

# Resolved type: the override wins (the setter path resolves live and exports
# it), else the cached client type.
nerd_font_type() {
  local sock="${1:-${NERD_FONT_SOCKET:-}}" pid="${2:-}" type
  type=$(nerd_font_type_normalize "${DOTFILES_NERD_FONT:-}")
  [ -n "$type" ] && { printf '%s' "$type"; return 0; }
  if [ -n "${_nerd_font_self:-}" ] && command -v fetch_cache_path >/dev/null 2>&1; then
    nerd_font_type_cached "$sock" "$pid"
  else
    nerd_font_type_live "$sock" "$pid"
  fi
}

nerd_font_mode() {
  nerd_font_type_to_mode "$(nerd_font_type "$@")"
}

nerd_font_icon() {
  local col
  [ -n "$_nerd_font_type_cache" ] || _nerd_font_type_cache="$(nerd_font_type "${NERD_FONT_SOCKET:-}")"
  case "$_nerd_font_type_cache" in
    mono) col=5 ;;
    lame) col=7 ;;
    *) col=3 ;;
  esac
  awk -F';' -v k="$1" -v c="$col" 'NR > 1 && $1 == k { v = $c; if (v == "" && c == 5) v = $3; print v }' "$_nerd_font_catalog"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    mode) shift; nerd_font_mode "$@" ;;
    type) shift; nerd_font_type_live "${1:-}" "${2:-}" ;;
    --cache-type) shift; nerd_font_type_cache_store "${1:-}" "${2:-}" ;;
    client-id) shift; nerd_font_client_id "${1:-}" "${2:-}" ;;
    state-file) nerd_font_state_file ;;
    lookup) nerd_font_lookup "${2:?usage: icon.sh lookup ID}" ;;
    store) nerd_font_store "${2:?usage: icon.sh store ID TYPE}" "${3:?usage: icon.sh store ID TYPE}" ;;
    get) nerd_font_icon "${2:?usage: icon.sh get KEY}" ;;
    *)
      echo "usage: icon.sh mode|type|client-id|state-file|lookup|store|get ..." >&2
      exit 2
      ;;
  esac
fi
