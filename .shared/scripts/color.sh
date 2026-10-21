#!/usr/bin/env bash
# Color catalog: named colors for the shell status and prompt scripts.
#
#   color get KEY       -> raw value (a terminal color name, #rrggbb, or colourN;
#                          usable as is inside tmux styles)
#   color ansi KEY [bg] -> SGR sequence for the key (foreground by default)
#
# Sourced from bash it also defines color_get / color_ansi.
# The catalog is next to this file (color.csv) with the same layout as the icon
# catalog: the key in the first column and the value in the third (a dummy
# column keeps the values aligned).
set -u

_color_self="$(readlink -f "${BASH_SOURCE[0]}")"
_color_dir="$(dirname -- "$_color_self")"
_color_catalog="${DOTFILES_COLOR_CATALOG:-$_color_dir/color.csv}"

color_get() {
  awk -F';' -v k="$1" 'NR > 1 && $1 == k { print $3; exit }' "$_color_catalog"
}

# Terminal color names to SGR foreground codes.
_color_sgr() {
  case "$1" in
    black) printf 30 ;;
    red) printf 31 ;;
    green) printf 32 ;;
    yellow) printf 33 ;;
    blue) printf 34 ;;
    magenta) printf 35 ;;
    cyan) printf 36 ;;
    white) printf 37 ;;
    brightblack) printf 90 ;;
    brightred) printf 91 ;;
    brightgreen) printf 92 ;;
    brightyellow) printf 93 ;;
    brightblue) printf 94 ;;
    brightmagenta) printf 95 ;;
    brightcyan) printf 96 ;;
    brightwhite) printf 97 ;;
    *) return 1 ;;
  esac
}

color_ansi() {
  local key="$1" layer="${2:-fg}" v r g b code prefix
  v=$(color_get "$key")
  [ -n "$v" ] || return 1
  if [ "$layer" = bg ]; then prefix=48; else prefix=38; fi
  case "$v" in
    '#'*)
      if [ "${#v}" -ne 7 ]; then return 1; fi
      r=$((16#${v:1:2}))
      g=$((16#${v:3:2}))
      b=$((16#${v:5:2}))
      printf '\033[%s;2;%d;%d;%dm' "$prefix" "$r" "$g" "$b"
      ;;
    colour[0-9]*)
      printf '\033[%s;5;%sm' "$prefix" "${v#colour}"
      ;;
    *)
      code=$(_color_sgr "$v") || return 1
      if [ "$layer" = bg ]; then code=$((code + 10)); fi
      printf '\033[%sm' "$code"
      ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    get) shift; color_get "${1:?usage: color get KEY}" ;;
    ansi) shift; color_ansi "${1:?usage: color ansi KEY [bg]}" "${2:-fg}" ;;
    *)
      echo "usage: color get KEY | color ansi KEY [bg]" >&2
      exit 2
      ;;
  esac
fi
