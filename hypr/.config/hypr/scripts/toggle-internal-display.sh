#! /usr/bin/bash

if [[ -f ~/.local/state/hypr/toggles/internal-display-disable || $(hyprctl monitors | grep -c "Monitor") -le 1 ]]; then
  rm -f ~/.local/state/hypr/toggles/internal-display-disable
  hyprctl keyword monitor "eDP-1,preferred,auto,2"
  hyprctl keyword monitor "eDP-2,preferred,auto,2"
else
  touch ~/.local/state/hypr/toggles/internal-display-disable
  hyprctl keyword monitor "eDP-1,disable"
  hyprctl keyword monitor "eDP-2,disable"
fi
