#!/bin/bash
# Toggle internal laptop display (eDP-2) on/off
set -euo pipefail

INTERNAL="eDP-2"

outputs=$(niri msg outputs)

if echo "$outputs" | grep -qF "($INTERNAL)"; then
    internal_block=$(echo "$outputs" | sed -n "/($INTERNAL)/,/^$/p" | head -n -1)

    if echo "$internal_block" | grep -q "Current mode"; then
        enabled_count=$(echo "$outputs" | grep -c "Current mode")
        if [ "$enabled_count" -ge 2 ]; then
            niri msg output "$INTERNAL" off
            # Small delay for niri to process the change
            sleep 0.3
            # Focus the first non-empty workspace (mimics Hyprland behavior)
            ws=$(niri msg windows | grep -oP 'Workspace ID: \K\d+' | sort -un | head -1)
            [ -n "$ws" ] && niri msg action focus-workspace "$ws"
            notify-send "Internal display turned off"
        else
            notify-send "Cannot turn off — no other displays connected"
        fi
    else
        niri msg output "$INTERNAL" on
        notify-send "Internal display turned on"
    fi
else
    notify-send "Output $INTERNAL not found"
    exit 1
fi
