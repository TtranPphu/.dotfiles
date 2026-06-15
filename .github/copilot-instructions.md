### Important Rules

- Never create git commits unless explicitly asked.
- Always mind the changes the user made during the session before making your own.

### Communication Style

See [communication style guide](.shared/agent/communication-style.md).

### Keywords

See [keywords reference](.shared/agent/keywords.md).

### Conventions

See [conventions guide](.shared/agent/conventions.md).

### Shared Agent Resources

Skills and handoffs live in `.shared/agent/`:
- **Skills** — `/commit`, `/stow-deploy`, `/pane-capture`, `/pane-logs`, `/handoff` ([skills directory](.shared/agent/skills/))
- **Handoffs** — Context documents for multi-session tasks ([handoffs directory](.shared/agent/handoffs/))

### Desktop
- **Hyprland**: Modular config: `monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`. Don't edit Omarchy paths — override locally. `unbind` before replacing Omarchy binds. App rules in `apps/*.conf`.
- **Niri**: Separate compositor config in `niri/.config/niri/config.kdl`.
- **Waybar**: Uses `omarchy-*` commands. `style.css` imports Omarchy CSS. `config.jsonc` is JSONC.
- **Walker**: Themes in `themes/omarchy-default/`.
- **Yazi**: `keymap.toml` & `theme.toml`.

### Shell
`zsh/.zshrc` → Oh My Zsh → `zsh/.config/zsh/*.zsh` → Starship. Auto-tmux on login.
`batcat` on Debian/Ubuntu, `bat` elsewhere.

### Editor
- **Neovim**: Kickstart. Only touch `lua/custom/plugins/*.lua`. Pinned in `nvim-pack-lock.json`. Stylua: 2-space, single quotes, no parens.

### Tools
- **Tmux**: `tmux.conf` > `bindings.conf` + `theme.conf`. Pane logs: `~/.local/state/tmux/pane-logs/`. Gate `extended-keys-format` behind tmux >= 3.5.
- **Starship**: `starship.toml` + helper scripts beside it.
- **bat** (`bat/.config/bat/config`), **eza** (`eza/.config/eza/theme.yml`), **ghostty**, **gdu**, **lazydocker**, **lazygit**.
