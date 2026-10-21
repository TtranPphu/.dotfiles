#!/usr/bin/env bash
# OS segment: gate + live render. os-util is a single /etc/os-release read.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/icon.sh"

  local key icon
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
  # One space between the icon and the separator, regardless of whether the
  # catalog value carries its own trailing space.
  printf '%s ┊' "${icon% }"
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
