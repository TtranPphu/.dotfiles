#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/icons.sh"

case "${1:-}" in
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    "$SCRIPT_DIR/layout.sh" is narrow && exit 1
    exit 0
    ;;
esac

case "$("$UTIL")" in
  alpine)       echo "$(icon os.alpine) ┊" ;;
  amzn)         echo "$(icon os.amzn) ┊" ;;
  android)      echo "$(icon os.android) ┊" ;;
  arch|artix)   echo "$(icon os.arch) ┊" ;;
  centos)       echo "$(icon os.centos) ┊" ;;
  darwin)       echo "$(icon os.darwin) ┊" ;;
  debian)       echo "$(icon os.debian) ┊" ;;
  fedora)       echo "$(icon os.fedora) ┊" ;;
  gentoo)       echo "$(icon os.gentoo) ┊" ;;
  manjaro)      echo "$(icon os.manjaro) ┊" ;;
  mint)         echo "$(icon os.mint) ┊" ;;
  nixos)        echo "$(icon os.nixos) ┊" ;;
  opensuse*)    echo "$(icon os.opensuse) ┊" ;;
  raspbian)     echo "$(icon os.raspbian) ┊" ;;
  rhel|redhat)  echo "$(icon os.rhel) ┊" ;;
  rocky)        echo "$(icon os.rocky) ┊" ;;
  sles)         echo "$(icon os.opensuse) ┊" ;;
  ubuntu)       echo "$(icon os.ubuntu) ┊" ;;
  *)            echo "$(icon os.linux) ┊" ;;
esac
