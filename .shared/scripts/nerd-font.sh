#!/usr/bin/env bash
# Terminal font capability + icon catalog.
#
#   nerd-font mode [socket]     -> "nerd" | "lame"
#   nerd-font type [socket]     -> resolved type (lame|nerd|nerd-v2|nerd-mono)
#   nerd-font client-id [socket]-> client identifier (SSH client IP, else "local")
#   nerd-font state-file        -> path to the client state file
#   nerd-font lookup <id>       -> stored type (lame|nerd|nerd-v2|nerd-mono,
#                                  legacy nf2|nf3|plain) or empty
#   nerd-font store <id> <type> -> record a type for a client id
#   nerd-font get KEY           -> glyph for KEY in the resolved type
#
# Sourced from bash it also defines nerd_font_mode / nerd_font_type /
# nerd_font_client_id / nerd_font_lookup / nerd_font_store / icon KEY.
#
# Resolution: $DOTFILES_NERD_FONT=nerd|lame wins (legacy plain means lame);
# otherwise the client's stored type in the state file; unknown clients resolve
# to "lame" until the shell setup prompt records a choice. State lines are
# id<TAB>type. The catalog is next to this file (nerd-font.csv):
# key;lame;nerd;nerd-v2;nerd-mono, with a matching header line. Empty nerd-v2
# or nerd-mono cells fall back to the nerd column (same codepoints).
set -u

_nerd_font_self="$(readlink -f "${BASH_SOURCE[0]}")"
_nerd_font_dir="$(dirname -- "$_nerd_font_self")"
_nerd_font_catalog="${DOTFILES_NERD_FONT_CATALOG:-$_nerd_font_dir/nerd-font.csv}"
_nerd_font_type_cache=""

nerd_font_state_file() {
  printf '%s' "${DOTFILES_NERD_FONT_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/nerd-font-clients}"
}

nerd_font_client_id() {
  local sock="${1:-${NERD_FONT_SOCKET:-}}" conn="" pid line

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
# Legacy: nf3 -> nerd, nf2 -> nerd-v2, plain -> lame.
nerd_font_type_normalize() {
  case "$1" in
    nf3) printf nerd ;;
    nf2) printf nerd-v2 ;;
    plain) printf lame ;;
    lame | nerd | nerd-v2 | nerd-mono) printf '%s' "$1" ;;
  esac
}

nerd_font_type_to_mode() {
  case "$1" in
    lame | plain) printf lame ;;
    nf2 | nf3 | nerd | nerd-v2 | nerd-mono) printf nerd ;;
    *) printf lame ;;
  esac
}

# Resolved type: override wins, else the client's stored type, else lame.
nerd_font_type() {
  local sock="${1:-${NERD_FONT_SOCKET:-}}" type
  type=$(nerd_font_type_normalize "${DOTFILES_NERD_FONT:-}")
  [ -n "$type" ] && { printf '%s' "$type"; return 0; }
  type=$(nerd_font_type_normalize "$(nerd_font_lookup "$(nerd_font_client_id "$sock")")")
  printf '%s' "${type:-lame}"
}

nerd_font_mode() {
  nerd_font_type_to_mode "$(nerd_font_type "$@")"
}

nerd_font_icon() {
  local col
  [ -n "$_nerd_font_type_cache" ] || _nerd_font_type_cache="$(nerd_font_type "${NERD_FONT_SOCKET:-}")"
  case "$_nerd_font_type_cache" in
    lame) col=2 ;;
    nerd-v2) col=4 ;;
    nerd-mono) col=5 ;;
    *) col=3 ;;
  esac
  awk -F';' -v k="$1" -v c="$col" 'NR > 1 && $1 == k { v = $c; if (v == "" && c > 3) v = $3; print v }' "$_nerd_font_catalog"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    mode) shift; nerd_font_mode "$@" ;;
    type) shift; nerd_font_type "$@" ;;
    client-id) shift; nerd_font_client_id "${1:-}" ;;
    state-file) nerd_font_state_file ;;
    lookup) nerd_font_lookup "${2:?usage: nerd-font lookup ID}" ;;
    store) nerd_font_store "${2:?usage: nerd-font store ID TYPE}" "${3:?usage: nerd-font store ID TYPE}" ;;
    get) nerd_font_icon "${2:?usage: nerd-font get KEY}" ;;
    *)
      echo "usage: nerd-font mode|type|client-id|state-file|lookup|store|get ..." >&2
      exit 2
      ;;
  esac
fi
