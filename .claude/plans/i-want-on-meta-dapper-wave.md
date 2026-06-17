# Session Picker Popup on Meta+j/k/w/s

## Context

Currently `M-j`/`M-s` cycle to the next session and `M-k`/`M-w` cycle to the previous
session — linear navigation that requires multiple presses to reach a far session.
The user wants all four keys to instead show a popup with all sessions listed,
allowing quick fuzzy-search selection via `fzf`, then switch to the chosen session
on selection.

## Changes

### 1. New file: `tmux/.config/tmux/scripts/session-picker.sh`

A script that lists all tmux sessions and pipes them through `fzf` (which renders
interactively inside the popup). On selection it runs `switch-client -t <session>`.
On cancel (Esc / Ctrl-C / no selection) it does nothing.

Key design:
- Uses `fzf` with `--reverse` layout and a clear prompt
- Session names are piped from `tmux list-sessions -F "#{session_name}"`
- Selected session is passed to `tmux switch-client -t "$session"`
- If fzf is not available, falls back to a numbered-select prompt via `select`

### 2. Modify: `tmux/.config/tmux/bindings.conf` (lines 91-94)

Replace the four existing bindings:

```
# Old:
bind -n M-j switch-client -n
bind -n M-k switch-client -p
bind -n M-s switch-client -n
bind -n M-w switch-client -p

# New:
bind -n M-j display-popup -E -w 40% -h 40% -d "#{pane_current_path}" "~/.config/tmux/scripts/session-picker.sh"
bind -n M-k display-popup -E -w 40% -h 40% -d "#{pane_current_path}" "~/.config/tmux/scripts/session-picker.sh"
bind -n M-s display-popup -E -w 40% -h 40% -d "#{pane_current_path}" "~/.config/tmux/scripts/session-picker.sh"
bind -n M-w display-popup -E -w 40% -h 40% -d "#{pane_current_path}" "~/.config/tmux/scripts/session-picker.sh"
```

The `-E` flag closes the popup when the command exits (user makes a selection or
cancels). The popup is 40% x 40% of the terminal — enough for a session list.

## Flow

```
User presses M-j/k/w/s
  → tmux opens 80% popup running session-picker.sh
    → fzf lists all sessions
    → user types to filter or arrows to navigate
    → user presses Enter on a session
      → popup closes
      → tmux switches to that session
    → user presses Esc/Ctrl-C
      → popup closes
      → nothing changes
```

## Verification

1. Source the new config: `tmux source-file ~/.config/tmux/tmux.conf`
   (or `Prefix q` since it's bound to `source-file` the config)
2. Press `M-j` — a popup should appear listing all tmux sessions
3. Type to fuzzy-filter, hit Enter on a session — should switch to it
4. Press `M-k`/`M-w`/`M-s` — same popup should appear
5. Press `Esc` in the popup — popup closes, no session change
