#!/usr/bin/env bash
# Terminal font capability + icon catalog.
#
#   nerd-font mode [socket]     -> "nerd" | "plain"
#   nerd-font client-id [socket]-> client identifier (SSH client IP, else "local")
#   nerd-font state-file        -> path to the client state file
#   nerd-font lookup <id>       -> stored type (nf2|nf3|plain) or empty
#   nerd-font store <id> <type> -> record a type for a client id
#   nerd-font get KEY [mode]    -> glyph for KEY in the resolved mode
#
# Sourced from bash it also defines nerd_font_mode / nerd_font_client_id / nerd_font_lookup /
# nerd_font_store / icon KEY.
#
# Resolution: $DOTFILES_NERD_FONT=nerd|plain wins; otherwise the client's stored
# type in the state file; unknown clients resolve to "plain" until the shell
# setup prompt records a choice. The catalog is next to this file (nerd-font.tsv):
# key<TAB>nerd<TAB>plain.
set -u

_nerd_font_self="$(readlink -f "${BASH_SOURCE[0]}")"
_nerd_font_dir="$(dirname -- "$_nerd_font_self")"
_nerd_font_catalog="${DOTFILES_NERD_FONT_CATALOG:-$_nerd_font_dir/nerd-font.tsv}"
_nerd_font_mode_cache=""

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

nerd_font_type_to_mode() {
  case "$1" in
    nf2 | nf3 | nerd) printf nerd ;;
    *) printf plain ;;
  esac
}

nerd_font_mode() {
  local mode="${DOTFILES_NERD_FONT:-}"
  case "$mode" in
    nerd | plain)
      printf '%s' "$mode"
      return 0
      ;;
  esac

  local sock="${1:-${NERD_FONT_SOCKET:-}}" id type
  id=$(nerd_font_client_id "$sock")
  type=$(nerd_font_lookup "$id")
  [ -n "$type" ] && { nerd_font_type_to_mode "$type"; return 0; }
  printf plain
}

nerd_font_icon() {
  [ -n "$_nerd_font_mode_cache" ] || _nerd_font_mode_cache="$(nerd_font_mode "${NERD_FONT_SOCKET:-}")"
  awk -F'\t' -v k="$1" -v m="$_nerd_font_mode_cache" '$1 == k { print (m == "plain" ? $3 : $2) }' "$_nerd_font_catalog"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    mode) shift; nerd_font_mode "$@" ;;
    client-id) shift; nerd_font_client_id "${1:-}" ;;
    state-file) nerd_font_state_file ;;
    lookup) nerd_font_lookup "${2:?usage: nerd-font lookup ID}" ;;
    store) nerd_font_store "${2:?usage: nerd-font store ID TYPE}" "${3:?usage: nerd-font store ID TYPE}" ;;
    get) nerd_font_icon "${2:?usage: nerd-font get KEY}" ;;
    *)
      echo "usage: nerd-font mode|client-id|state-file|lookup|store|get ..." >&2
      exit 2
      ;;
  esac
fi
