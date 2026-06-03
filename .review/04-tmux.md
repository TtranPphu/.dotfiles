# Tmux — Review Findings

## 🟢 Remaining — Low severity

### `auto-split` uses unsafe `$*` pattern

**File:** `tmux/.config/tmux/scripts/auto-split:14`

```bash
tmux send-keys -t "$PANE" "exec $*" Enter
```

`$*` joins arguments with spaces. If called with untrusted input, could execute arbitrary commands. Currently only called with hardcoded values from tmux.conf. Has a comment noting this but pattern is unchanged.

---

### `status-hint` script is entirely dead code (107 lines)

**File:** `tmux/.config/tmux/scripts/status-hint`

The `init` call and `status-format[1]`/`status-format[2]` config are all commented out in `tmux.conf`. The entire display system is dead code.

---

### Terminal keybinding compatibility

**File:** `tmux/.config/tmux/tmux.conf:33-46`

`C-M-S-{Left,Right,Up,Down}` and `C-M-{h,j,k,l}` combinations are not reliably sent by most terminal emulators. These bindings silently fail on many setups (gnome-terminal, Windows Terminal, etc.).
