#!/bin/bash
# Launch a TUI app or focus existing instance (mirrors Omarchy's behavior)
# Uses xdg-terminal-exec with --app-id so windows can be matched by app-id.
# Usage: launch-or-focus <app-name> <command> [args...]

set -euo pipefail

APP_NAME="$1"
APP_ID="org.omarchy.$APP_NAME"
shift
CMD="$*"

# Find existing window by app-id
win_id=$(niri msg windows 2>/dev/null | awk -v id="$APP_ID" '
    /^Window ID/ { current_id = $3; gsub(/:/, "", current_id) }
    /App ID:/ && index(tolower($0), tolower(id)) { print current_id }
' | head -1)

if [ -n "$win_id" ]; then
    niri msg action focus-window "$win_id" || true
else
    # If the target IS the terminal itself, launch it directly.
    # xdg-terminal-exec -e <terminal> creates ghostty-in-ghostty which dumps
    # startup log into the outer terminal window.
    if command -v "$APP_NAME" &>/dev/null && xdg-terminal-exec --print-id 2>/dev/null | grep -qiF "$APP_NAME"; then
        setsid "$APP_NAME" &
    else
        setsid xdg-terminal-exec --app-id="$APP_ID" -e "$CMD" &
    fi
fi
