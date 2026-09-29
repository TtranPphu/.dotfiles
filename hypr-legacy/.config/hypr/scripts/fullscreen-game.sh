#!/bin/bash
# Monitor for native game windows that reset their fullscreen state after init
# and re-apply fullscreen. Hyprland's windowrule fullscreen is static-only,
# so it won't re-fire when Godot changes class from Godot -> Brotato etc.

known_games="Brotato dontstarve_steam_x64"

while true; do
  for class in $known_games; do
    window=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
try:
    clients = json.load(sys.stdin)
except:
    exit()
for c in clients:
    if c['class'] == '$class' and c['mapped'] and not c['hidden'] and c['fullscreen'] == 0:
        print(c['address'])
        break
")
    if [ -n "$window" ]; then
      hyprctl dispatch fullscreen 1 address:"$window"
    fi
  done
  sleep 2
done
