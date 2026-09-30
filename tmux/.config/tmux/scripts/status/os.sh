#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/icons.sh"

case "$("$UTIL")" in
  alpine)       icon="$(icon os.alpine)" ;;
  amzn)         icon="$(icon os.amzn)" ;;
  android)      icon="$(icon os.android)" ;;
  arch|artix)   icon="$(icon os.arch)" ;;
  centos)       icon="$(icon os.centos)" ;;
  darwin)       icon="$(icon os.darwin)" ;;
  debian)       icon="$(icon os.debian)" ;;
  fedora)       icon="$(icon os.fedora)" ;;
  gentoo)       icon="$(icon os.gentoo)" ;;
  manjaro)      icon="$(icon os.manjaro)" ;;
  mint)         icon="$(icon os.mint)" ;;
  nixos)        icon="$(icon os.nixos)" ;;
  opensuse*)    icon="$(icon os.opensuse)" ;;
  raspbian)     icon="$(icon os.raspbian)" ;;
  rhel|redhat)  icon="$(icon os.rhel)" ;;
  rocky)        icon="$(icon os.rocky)" ;;
  sles)         icon="$(icon os.opensuse)" ;;
  ubuntu)       icon="$(icon os.ubuntu)" ;;
  *)            icon="$(icon os.linux)" ;;
esac

printf '#[fg=colour233,bold,bg=white] %s ▐#[default]' "$icon"
