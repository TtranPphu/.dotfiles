#!/usr/bin/env bash
# Show all tmux keybindings in an interactive popup
# Triggered by Meta-? (Alt+Shift+/)

tmux display-popup -E -w 80% -h 80% \
  "{ echo '==================== PREFIX BINDINGS (prefix = C-Space / C-a) ===================='; tmux list-keys -T prefix 2>/dev/null; echo; echo '======================= GLOBAL BINDINGS (no prefix) ========================'; tmux list-keys -T root 2>/dev/null; } | less -FX"
