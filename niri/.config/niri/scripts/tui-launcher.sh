#!/bin/bash
# TUI application launcher using fzf
# Lists desktop entries, lets you fuzzy-find and launch

set -euo pipefail

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Collect all desktop file dirs
IFS=':' read -ra dirs <<< "$XDG_DATA_DIRS:$XDG_DATA_HOME"
desktop_dirs=()
for d in "${dirs[@]}"; do
    dd="$d/applications"
    [ -d "$dd" ] && desktop_dirs+=("$dd")
done

if [ ${#desktop_dirs[@]} -eq 0 ]; then
    echo "No application directories found." >&2
    exit 1
fi

# Parse desktop files into name → exec mapping
entries=$(
    find "${desktop_dirs[@]}" -name '*.desktop' -type f 2>/dev/null |
    while read -r file; do
        name=$(grep -m1 '^Name=' "$file" 2>/dev/null | sed 's/^Name=//')
        exec_cmd=$(grep -m1 '^Exec=' "$file" 2>/dev/null | sed 's/^Exec=//' | sed 's/%.//g' | sed 's/ //g')
        [ -n "$name" ] && [ -n "$exec_cmd" ] && echo "$name|$exec_cmd"
    done | sort -t'|' -k1
)

if [ -z "$entries" ]; then
    echo "No applications found." >&2
    exit 1
fi

selected=$(echo "$entries" | column -t -s '|' -o '  ' | fzf --prompt="Launch > " --height=20 --with-nth=1 | awk '{print $NF}')

if [ -n "$selected" ]; then
    # Remove field codes like %f, %F, %u, %U from the exec line
    clean_cmd=$(echo "$selected" | sed 's/%[fFuU]//g')
    eval "$clean_cmd" &
fi
