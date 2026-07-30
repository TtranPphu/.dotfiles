# H07 - Tmux session presets via YAML/TOML

## Goal

Define tmux session layouts (windows, panes, commands, working directories) in declarative YAML or TOML files instead of hardcoded shell scripts, with an `fzf` picker to launch them.

## Motivation

Current session setup is ad-hoc: individual scripts, manual window creation, or `tmuxp`-style YAML configs. A unified preset system would let users define project environments in a single config directory (`~/.config/tmux/presets/`) and launch them via `Alt+S` or a dedicated keybind.

## Deliverables

1. Choose format: YAML vs TOML (YAML is more familiar for tmux users, TOML is stricter)
2. Define the preset schema (windows, layout, panes, commands, env vars, working dir)
3. Write a CLI tool (bash or python) that reads presets and builds the session
4. Add an `fzf` picker to select and launch a preset
5. Bind it to a key (e.g., `Alt+S` or repurpose the existing session switch)

## Preset Schema (draft YAML)

```yaml
name: my-project
root: ~/projects/my-project
windows:
  - name: code
    root: ~/projects/my-project/src
    layout: even-horizontal
    panes:
      - type: editor      # e.g., nvim, code
        command: nvim .
      - type: shell       # plain shell
  - name: server
    root: ~/projects/my-project
    panes:
      - command: npm run dev
      - command: cargo watch
  - name: git
    panes:
      - command: lazygit
```

## Related

- Current `switch-session.sh` (`tmux/.config/tmux/scripts/control/switch-session.sh`) — fzf-tmux session picker
- Current session switch binding `M-s` in `bindings.conf:84`
- `tmuxp` (Python) — existing YAML-based tmux session manager, could be an integration point or inspiration

## Potential Issues

- **Dependencies**: TOML parsing in bash is awkward; Python with `yaml`/`tomllib` (3.11+) is cleaner. Python is already available on the target systems.
- **tmuxp compat**: Could reuse or extend tmuxp YAML format for zero-new-format friction.
- **Layout handling**: `tmux select-layout` works only if panes match the layout grid; may need manual pane splitting.
- **Session exists**: Need to decide whether to attach, switch, or error if the session already exists.

## Verification

- [ ] Create 2-3 preset YAMLs (dev, notes, system)
- [ ] Launch each via `Alt+S` → fzf picker → session is created with correct windows/panes/commands
- [ ] Re-launch with existing session → attaches/refocuses without duplicating
- [ ] Works on both Linux (Arch) and WSL (Ubuntu)

OpenCode - deepseek-v4-flash-free