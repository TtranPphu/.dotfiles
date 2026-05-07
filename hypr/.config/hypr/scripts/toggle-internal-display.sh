#! /usr/bin/bash

if [[ $(hyprctl monitors | grep Monitor | grep -c eDP-2) -ge 1 && $(hyprctl monitors all | grep -c Monitor) -ge 2 ]]; then
  hyprctl keyword monitor "eDP-2,disable"
else
  hyprctl keyword monitor "eDP-2,preferred,auto,2"
fi
