#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"

case "${1:-}" in
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
esac

case "$("$UTIL")" in
  alpine)       echo "$(nerd_font_icon os.alpine) ┊" ;;
  amzn)         echo "$(nerd_font_icon os.amzn) ┊" ;;
  android)      echo "$(nerd_font_icon os.android) ┊" ;;
  arch|artix)   echo "$(nerd_font_icon os.arch) ┊" ;;
  centos)       echo "$(nerd_font_icon os.centos) ┊" ;;
  darwin)       echo "$(nerd_font_icon os.darwin) ┊" ;;
  debian)       echo "$(nerd_font_icon os.debian) ┊" ;;
  fedora)       echo "$(nerd_font_icon os.fedora) ┊" ;;
  gentoo)       echo "$(nerd_font_icon os.gentoo) ┊" ;;
  manjaro)      echo "$(nerd_font_icon os.manjaro) ┊" ;;
  mint)         echo "$(nerd_font_icon os.mint) ┊" ;;
  nixos)        echo "$(nerd_font_icon os.nixos) ┊" ;;
  opensuse*)    echo "$(nerd_font_icon os.opensuse) ┊" ;;
  raspbian)     echo "$(nerd_font_icon os.raspbian) ┊" ;;
  rhel|redhat)  echo "$(nerd_font_icon os.rhel) ┊" ;;
  rocky)        echo "$(nerd_font_icon os.rocky) ┊" ;;
  sles)         echo "$(nerd_font_icon os.opensuse) ┊" ;;
  ubuntu)       echo "$(nerd_font_icon os.ubuntu) ┊" ;;
  *)            echo "$(nerd_font_icon os.linux) ┊" ;;
esac
