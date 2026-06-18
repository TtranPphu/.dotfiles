# Tmux: CWD-based session naming with attach-if-exists

## Context

Currently, tmux always creates/attaches to a session named `default` at startup (zsh, nushell, and the picker), and `prefix C` creates an unnamed session (tmux auto-numbers it). The user wants new sessions named after the current directory basename, attaching to an existing session if one with that name already exists.

## Changes

### 1. `zsh/.zshrc` — lines 132 and 149

Replace `default` with `${PWD##*/}` in both `tmux new -A -s default` commands.

```diff
- exec tmux new -A -s default
+ exec tmux new -A -s "${PWD##*/}"
```

### 2. `nu/.config/nushell/config.nu` — lines 26 and 31

Replace `default` with `($env.PWD | path basename)` in both `tmux new -A -s default` commands.

```diff
- tmux new -A -s default; exit
+ tmux new -A -s ($env.PWD | path basename); exit
```

### 3. `tmux/.config/tmux/bindings.conf` — line 86

Replace `prefix C` binding to call a new helper script.

```diff
- bind C new-session -c "#{pane_current_path}"
+ bind C run-shell -b '~/.config/tmux/scripts/session-cwd.sh'
```

### 4. New: `tmux/.config/tmux/scripts/auto-session.sh`

Helper script that creates a session named after the CWD basename, or switches to it if it exists.

```bash
#!/usr/bin/env bash
set -euo pipefail

cwd=$(tmux display-message -p '#{pane_current_path}')
name=$(basename "$cwd")
[[ -z "$name" ]] && name="root"

if tmux has-session -t "$name" 2>/dev/null; then
    tmux switch-client -t "$name"
else
    tmux new-session -d -s "$name" -c "$cwd"
    tmux switch-client -t "$name"
fi
```

## Design decisions

- **Explicit `has-session` + `switch-client`** instead of `new-session -A` — avoids ambiguity of `-A` behavior inside `run-shell` context
- **`set -euo pipefail`** — matches the most robust existing script (`pane-log.sh`)
- **`basename "$cwd"`** — uses external `basename` for clarity over bash substitution
- **Empty name guard** — `basename /` returns ""; falls back to `root`
- **No sanitization of session names** — tmux will error on invalid chars; acceptable tradeoff

## Verification

1. `bash -n session-cwd.sh`
2. `shellcheck session-cwd.sh`
3. `zsh -n .zshrc`
4. `nu -c 'source config.nu'` (basic syntax check)
5. `tmux source-file ~/.config/tmux/bindings.conf`
6. `stow tmux -d /home/phut/.dotfiles -t ~ --simulate` then `stow tmux -d /home/phut/.dotfiles -t ~`
