GNU Stow dotfiles. Top-level dirs mirror `$HOME`. `stow <pkg>` to deploy.

### Communication Style

- Answer in one concise sentence unless the user asks for more detail.
- If you don't know, just say so. If unsure, ask for clarification.
- Answer in the same language as the user's query.
- Answer directly without XML tags in your response text.
- Don't include thinking or reasoning in the response unless asked.
- If the user types a CLI command with typos or wrong casing, just hint the correct command.

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
