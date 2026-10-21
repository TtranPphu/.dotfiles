#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/nerd-font.sh"
source "$SCRIPT_DIR/color.sh"

icon_os=""
case "$("$UTIL")" in
  alpine)       icon_os="$(nerd_font_icon os.alpine)" ;;
  amzn)         icon_os="$(nerd_font_icon os.amzn)" ;;
  android)      icon_os="$(nerd_font_icon os.android)" ;;
  arch)         icon_os="$(nerd_font_icon os.arch)" ;;
  artix)        icon_os="$(nerd_font_icon os.artix)" ;;
  omarchy)      icon_os="$(nerd_font_icon os.omarchy)" ;;
  centos)       icon_os="$(nerd_font_icon os.centos)" ;;
  darwin)       icon_os="$(nerd_font_icon os.darwin)" ;;
  debian)       icon_os="$(nerd_font_icon os.debian)" ;;
  fedora)       icon_os="$(nerd_font_icon os.fedora)" ;;
  gentoo)       icon_os="$(nerd_font_icon os.gentoo)" ;;
  manjaro)      icon_os="$(nerd_font_icon os.manjaro)" ;;
  mint)         icon_os="$(nerd_font_icon os.mint)" ;;
  nixos)        icon_os="$(nerd_font_icon os.nixos)" ;;
  opensuse*)    icon_os="$(nerd_font_icon os.opensuse)" ;;
  raspbian)     icon_os="$(nerd_font_icon os.raspbian)" ;;
  rhel)    icon_os="$(nerd_font_icon os.rhel)" ;;
  redhat)  icon_os="$(nerd_font_icon os.redhat)" ;;
  rocky)        icon_os="$(nerd_font_icon os.rocky)" ;;
  sles)         icon_os="$(nerd_font_icon os.opensuse)" ;;
  ubuntu)       icon_os="$(nerd_font_icon os.ubuntu)" ;;
  *)            icon_os="$(nerd_font_icon os.linux)" ;;
esac

icon_head="$(nerd_font_icon separator.head)"
icon_tail="$(nerd_font_icon separator.tail)"
fg_soft="$(color_get ink.soft)"
bg_white="$(color_get white)"

style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_soft" "$bg_white")
reset='#[default]'
if [[ "$(nerd_font_type)" == nerd ]]; then
  out=" $icon_os$icon_tail"
else
  out="$icon_head$icon_os$icon_tail"
fi
printf '%s%s%s' "$style" "$out" "$reset"
