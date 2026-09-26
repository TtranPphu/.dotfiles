#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"

case "$("$UTIL")" in
  alpine)       echo " 󰇝" ;;
  amzn)         echo " 󰇝" ;;
  android)      echo " 󰇝" ;;
  arch|artix)   echo "󰣇 󰇝" ;;
  centos)       echo " 󰇝" ;;
  darwin)       echo "󰀵 󰇝" ;;
  debian)       echo "󰣚 󰇝" ;;
  fedora)       echo "󰣛 󰇝" ;;
  gentoo)       echo "󰣨 󰇝" ;;
  manjaro)      echo " 󰇝" ;;
  mint)         echo "󰣭 󰇝" ;;
  nixos)        echo " 󰇝" ;;
  opensuse*)    echo " 󰇝" ;;
  raspbian)     echo "󰐿 󰇝" ;;
  rhel|redhat)  echo "󱄛 󰇝" ;;
  rocky)        echo " 󰇝" ;;
  sles)         echo " 󰇝" ;;
  ubuntu)       echo " 󰇝" ;;
  *)            echo "󰌽 󰇝" ;;
esac
