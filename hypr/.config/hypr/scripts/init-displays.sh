#! /usr/bin/bash

if [[ $(hyprctl monitors all | grep -c "Monitor") -ge 2 ]]; then
  lock_file=~/.local/state/hypr/toggles/internal-display-disable
  [ -e $lock_file ] || touch $lock_file
  hyprctl keyword monitor "eDP-2,preferred,auto-center-down,2"
fi
