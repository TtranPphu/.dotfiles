#!/usr/bin/env bash
# Terminal capability + icon catalog.
#
#   icons mode [socket]   -> "nerd" | "plain"
#   icons get KEY [mode]  -> glyph for KEY in the resolved mode
#
# Sourced from bash it also defines:
#   icons_mode            -> "nerd" | "plain"
#   icon KEY              -> glyph for KEY
#
# Mode resolution: $DOTFILES_ICONS=nerd|plain wins; "auto"/unset detects.
# Plain when any attached SSH client is not in the allowlist
# (~/.config/dotfiles/icons-hosts, override $DOTFILES_ICONS_HOSTS).
# The catalog lives next to this file (icons.tsv): key<TAB>nerd<TAB>plain.
set -u

_icons_self="$(readlink -f "${BASH_SOURCE[0]}")"
_icons_dir="$(dirname -- "$_icons_self")"
_icons_catalog="${DOTFILES_ICONS_CATALOG:-$_icons_dir/icons.tsv}"
_icons_mode_cache=""

icons_mode() {
  local mode="${DOTFILES_ICONS:-}"
  case "$mode" in
    nerd | plain)
      printf '%s' "$mode"
      return 0
      ;;
  esac

  local hosts="${DOTFILES_ICONS_HOSTS:-${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/icons-hosts}"
  local sock="${1:-${ICON_SOCKET:-}}"

  is_allowlisted() {
    local ip="$1"
    [ -n "$ip" ] && [ -f "$hosts" ] || return 1
    awk -v ip="$ip" '
      { sub(/#.*/, "") }
      { for (i = 1; i <= NF; i++) if ($i == ip) found = 1 }
      END { exit !found }
    ' "$hosts"
  }

  local conn="" pid line
  if command -v tmux >/dev/null 2>&1; then
    local tmux_cmd=(tmux)
    [ -n "$sock" ] && tmux_cmd=(tmux -S "$sock")
    for pid in $("${tmux_cmd[@]}" list-clients -F '#{client_pid}' 2>/dev/null); do
      line=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^SSH_CONNECTION=//p')
      [ -n "$line" ] || continue
      if is_allowlisted "${line%% *}"; then
        continue
      fi
      printf plain
      return 0
    done
  fi

  conn="${SSH_CONNECTION:-${SSH_CLIENT:-}}"
  if [ -n "$conn" ] && ! is_allowlisted "${conn%% *}"; then
    printf plain
  else
    printf nerd
  fi
}

icon() {
  [ -n "$_icons_mode_cache" ] || _icons_mode_cache="$(icons_mode "${ICON_SOCKET:-}")"
  awk -F'\t' -v k="$1" -v m="$_icons_mode_cache" '$1 == k { print (m == "plain" ? $3 : $2) }' "$_icons_catalog"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    mode) shift; icons_mode "$@" ;;
    get) icon "${2:?usage: icons get KEY}" ;;
    *)
      echo "usage: icons mode [socket] | icons get KEY" >&2
      exit 2
      ;;
  esac
fi
