GNU Stow dotfiles. Top-level dirs mirror `$HOME`. `stow <pkg>` to deploy.

### Communication Style

See [`.shared/agent/communication-style.md`](/.shared/agent/communication-style.md).

### Keywords

- **picker** — Shell/multiplexer picker at startup: `zsh/.zshrc` (zsh) and `nu/.config/nushell/config.nu` (nushell). Chooses shell (zsh/nushell) and multiplexer (tmux/zelliji).

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

### Conventions
See [`.shared/agent/conventions.md`](/.shared/agent/conventions.md).
