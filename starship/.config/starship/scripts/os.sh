#!/usr/bin/env bash
# OS segment, rendered through the two-pass cache (cache.sh): the prompt only
# reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/nerd-font.sh"

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
  printf '%s┊' "${icon% }"
}

case "${1:-}" in
  --display | "")
    cache_file=$(starship_cache_path os)
    cache_display "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  --refresh)
    cache_refresh "${2:?}" render
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    size=$("$script_dir/layout.sh" size 2>/dev/null) || size=medium
    [ "$size" = narrow ] && exit 1
    cache_file=$(starship_cache_path os "$(starship_cache_client)")
    cache_gate "$cache_file" 600 "$0" --refresh "$cache_file"
    ;;
  *) exit 2 ;;
esac
