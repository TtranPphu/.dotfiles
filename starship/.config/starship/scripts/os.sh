#!/usr/bin/env bash
# OS segment: gate + live render. os-util is a single /etc/os-release read.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/icon.sh"
  source "$script_dir/color.sh"

  local key icon sep fg_os text style reset
  case "$("$script_dir/os-util.sh")" in
    alpine)       key=os.alpine ;;
    amzn)         key=os.amzn ;;
    android)      key=os.android ;;
    arch)         key=os.arch ;;
    artix)        key=os.artix ;;
    omarchy)      key=os.omarchy ;;
    centos)       key=os.centos ;;
    darwin)       key=os.darwin ;;
    debian)       key=os.debian ;;
    fedora)       key=os.fedora ;;
    gentoo)       key=os.gentoo ;;
    manjaro)      key=os.manjaro ;;
    mint)         key=os.mint ;;
    nixos)        key=os.nixos ;;
    opensuse*)    key=os.opensuse ;;
    raspbian)     key=os.raspbian ;;
    rhel)    key=os.rhel ;;
    redhat)  key=os.redhat ;;
    rocky)        key=os.rocky ;;
    sles)         key=os.opensuse ;;
    ubuntu)       key=os.ubuntu ;;
    *)            key=os.linux ;;
  esac
  icon=$(nerd_font_icon "$key")
  sep=$(nerd_font_icon separator.light)
  # Starship foreground (no background); an unknown OS key renders bold only.
  fg_os=$(color_ansi "$key.starship") || fg_os=""
  # The brand foreground wraps the icon only: reset it before the separator,
  # which keeps the bold style. One space between them, regardless of whether
  # the catalog value carries its own trailing space.
  text="${icon% }"$'\033[39m'" $sep"
  style=$'\033[1m'"$fg_os"
  reset=$'\033[0m'
  printf '%s%s%s' "$style" "$text" "$reset"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = narrow ] && exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
