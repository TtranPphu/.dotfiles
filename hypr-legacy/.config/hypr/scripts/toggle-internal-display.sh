#!/bin/bash

if [[ $(hyprctl monitors | grep Monitor | grep -c eDP-2) -ge 1 && $(hyprctl monitors all | grep -c Monitor) -ge 2 ]]; then
  hyprctl keyword monitor "eDP-2,disable"
  hyprctl keyword scrolling:column_width 0.6
  hyprctl keyword layout:single_window_aspect_ratio "16 10"
  hyprctl keyword env "GDK_SCALE,1.5"
else
  hyprctl keyword monitor "eDP-2,preferred,auto-center-down,2"
  hyprctl keyword scrolling:column_width 0.8
  hyprctl keyword layout:single_window_aspect_ratio "12 10"
  hyprctl keyword env "GDK_SCALE,2"
fi
