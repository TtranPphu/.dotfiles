#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL="$SCRIPT_DIR/os-util.sh"
source "$SCRIPT_DIR/icon.sh"
source "$SCRIPT_DIR/color.sh"

key_os=""
case "$("$UTIL")" in
  alpine)    key_os=os.alpine ;;
  amzn)      key_os=os.amzn ;;
  android)   key_os=os.android ;;
  arch)      key_os=os.arch ;;
  artix)     key_os=os.artix ;;
  omarchy)   key_os=os.omarchy ;;
  centos)    key_os=os.centos ;;
  darwin)    key_os=os.darwin ;;
  debian)    key_os=os.debian ;;
  fedora)    key_os=os.fedora ;;
  gentoo)    key_os=os.gentoo ;;
  manjaro)   key_os=os.manjaro ;;
  mint)      key_os=os.mint ;;
  nixos)     key_os=os.nixos ;;
  opensuse*) key_os=os.opensuse ;;
  raspbian)  key_os=os.raspbian ;;
  rhel)      key_os=os.rhel ;;
  redhat)    key_os=os.redhat ;;
  rocky)     key_os=os.rocky ;;
  sles)      key_os=os.opensuse ;;
  ubuntu)    key_os=os.ubuntu ;;
  *)         key_os=os.linux ;;
esac

icon_os="$(nerd_font_icon "$key_os")"
icon_head="$(nerd_font_icon separator.head)"
icon_tail="$(nerd_font_icon separator.tail)"
# Pill background and icon foreground come from their own tmux keys;
# unknown OS keys fall back to the neutral look.
bg_os="$(color_get "$key_os.tmux.bg")"
[[ -n $bg_os ]] || bg_os="$(color_get white)"
fg_icon="$(color_get "$key_os.tmux.fg")"
[[ -n $fg_icon ]] || fg_icon="$(color_get ink)"
fg_edge="$(color_get ink)"

style_edge=$(printf '#[fg=%s,bold,bg=%s]' "$fg_edge" "$bg_os")
style_icon=$(printf '#[fg=%s,bold,bg=%s]' "$fg_icon" "$bg_os")
reset='#[default]'
printf '%s%s%s%s%s%s%s' "$style_edge" "$icon_head" "$style_icon" "$icon_os" "$style_edge" "$icon_tail" "$reset"
