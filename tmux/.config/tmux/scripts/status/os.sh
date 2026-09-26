#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"

case "$("$UTIL")" in
  alpine)       icon="" ;;
  amzn)         icon="" ;;
  android)      icon="" ;;
  arch|artix)   icon="󰣇" ;;
  centos)       icon="" ;;
  darwin)       icon="󰀵" ;;
  debian)       icon="󰣚" ;;
  fedora)       icon="󰣛" ;;
  gentoo)       icon="󰣨" ;;
  manjaro)      icon="" ;;
  mint)         icon="󰣭" ;;
  nixos)        icon="" ;;
  opensuse*)    icon="" ;;
  raspbian)     icon="󰐿" ;;
  rhel|redhat)  icon="󱄛" ;;
  rocky)        icon="" ;;
  sles)         icon="" ;;
  ubuntu)       icon="" ;;
  *)            icon="󰌽" ;;
esac

printf '#[fg=colour233,bold,bg=white] %s ▐#[default]' "$icon"
