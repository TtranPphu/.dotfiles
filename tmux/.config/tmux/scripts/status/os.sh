#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"

case "$("$UTIL")" in
  alpine)       icon="$(nerd_font_icon os.alpine)" ;;
  amzn)         icon="$(nerd_font_icon os.amzn)" ;;
  android)      icon="$(nerd_font_icon os.android)" ;;
  arch)         icon="$(nerd_font_icon os.arch)" ;;
  artix)        icon="$(nerd_font_icon os.artix)" ;;
  omarchy)      icon="$(nerd_font_icon os.omarchy)" ;;
  centos)       icon="$(nerd_font_icon os.centos)" ;;
  darwin)       icon="$(nerd_font_icon os.darwin)" ;;
  debian)       icon="$(nerd_font_icon os.debian)" ;;
  fedora)       icon="$(nerd_font_icon os.fedora)" ;;
  gentoo)       icon="$(nerd_font_icon os.gentoo)" ;;
  manjaro)      icon="$(nerd_font_icon os.manjaro)" ;;
  mint)         icon="$(nerd_font_icon os.mint)" ;;
  nixos)        icon="$(nerd_font_icon os.nixos)" ;;
  opensuse*)    icon="$(nerd_font_icon os.opensuse)" ;;
  raspbian)     icon="$(nerd_font_icon os.raspbian)" ;;
  rhel)    icon="$(nerd_font_icon os.rhel)" ;;
  redhat)  icon="$(nerd_font_icon os.redhat)" ;;
  rocky)        icon="$(nerd_font_icon os.rocky)" ;;
  sles)         icon="$(nerd_font_icon os.opensuse)" ;;
  ubuntu)       icon="$(nerd_font_icon os.ubuntu)" ;;
  *)            icon="$(nerd_font_icon os.linux)" ;;
esac

if [[ "$(nerd_font_mode)" == lame ]]; then
  printf '#[fg=colour233,bold,bg=white]▏%s▕#[default]' "$icon"
else
  printf '#[fg=colour233,bold,bg=white] %s ▐#[default]' "$icon"
fi
