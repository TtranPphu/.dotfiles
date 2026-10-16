#!/usr/bin/env bash
# OS segment, rendered through the two-pass cache (cache.sh): the prompt only
# reads the cache; a detached refresher renders into it when stale.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/cache.sh"

render() {
  source "$script_dir/nerd-font.sh"

  case "$("$script_dir/os-util.sh")" in
    alpine)       echo "$(nerd_font_icon os.alpine)┊" ;;
    amzn)         echo "$(nerd_font_icon os.amzn)┊" ;;
    android)      echo "$(nerd_font_icon os.android)┊" ;;
    arch)         echo "$(nerd_font_icon os.arch)┊" ;;
    artix)        echo "$(nerd_font_icon os.artix)┊" ;;
    omarchy)      echo "$(nerd_font_icon os.omarchy)┊" ;;
    centos)       echo "$(nerd_font_icon os.centos)┊" ;;
    darwin)       echo "$(nerd_font_icon os.darwin)┊" ;;
    debian)       echo "$(nerd_font_icon os.debian)┊" ;;
    fedora)       echo "$(nerd_font_icon os.fedora)┊" ;;
    gentoo)       echo "$(nerd_font_icon os.gentoo)┊" ;;
    manjaro)      echo "$(nerd_font_icon os.manjaro)┊" ;;
    mint)         echo "$(nerd_font_icon os.mint)┊" ;;
    nixos)        echo "$(nerd_font_icon os.nixos)┊" ;;
    opensuse*)    echo "$(nerd_font_icon os.opensuse)┊" ;;
    raspbian)     echo "$(nerd_font_icon os.raspbian)┊" ;;
    rhel)    echo "$(nerd_font_icon os.rhel)┊" ;;
    redhat)  echo "$(nerd_font_icon os.redhat)┊" ;;
    rocky)        echo "$(nerd_font_icon os.rocky)┊" ;;
    sles)         echo "$(nerd_font_icon os.opensuse)┊" ;;
    ubuntu)       echo "$(nerd_font_icon os.ubuntu)┊" ;;
    *)            echo "$(nerd_font_icon os.linux)┊" ;;
  esac
}

case "${1:-}" in
  --display | "")
    cache_file=$(starship_cache_path os "$(starship_cache_client)")
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
