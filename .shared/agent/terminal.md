# Terminal Config

Terminal-only dotfiles: shell, editor, multiplexer, prompt, and CLI tools. See `desktop.md` for compositors and desktop environment.

## Repo structure

GNU Stow-style dotfiles. Every top-level directory is a stow package whose internal path mirrors `$HOME`. Deploy with `stow -St ~ <package>` or `/stow-deploy` skill. No build, tests, or CI. Add files under the stow package that owns the target path — never create ad-hoc relocation scripts.

## Shell

- **Zsh** (default) — Chain: `.zshrc` → Oh My Zsh → `.config/zsh/*.zsh` → Starship.
- **Nushell** (alternative) — Config in `nu/.config/nushell/config.nu`.
- **Picker** — At startup, `.zshrc` lets you choose shell (zsh/nushell) and multiplexer (tmux/zellij). See `keywords.md` "picker".
- `batcat` on Debian/Ubuntu, `bat` elsewhere.
- Shell scripts: Bash shebang, 2-space indentation. Format with `shfmt -i 2`.

## Editor

- **Neovim** — Kickstart-based. Only touch `lua/custom/plugins/*.lua`. Don't edit `init.lua`. Plugin versions pinned in `nvim-pack-lock.json`. Stylua: 2-space, single quotes, no parens.

## Multiplexer

- **Tmux** — Config: `tmux.conf` sources `bindings.conf` + `theme.conf`. Scripts in `tmux/.config/tmux/scripts/`. Gate `extended-keys-format` behind tmux >= 3.5. Pane output auto-logs to `~/.local/state/tmux/pane-logs/`.
- **Zellij** (alternative) — Config in `zellij/.config/zellij/`.

## Prompt

- **Starship** — `starship.toml` + helper scripts (`.sh`) in same directory (`starship/.config/starship/`): `compress-date.sh`, `compress-path.sh`, `deepseek-balance.sh`, `llm-route.sh`, `llm-when.sh`.

## Other tools

| Package | Config path | Notes |
|---|---|---|
| bat | `bat/.config/bat/config` | `batcat` on Debian/Ubuntu |
| eza | `eza/.config/eza/theme.yml` | |
| ghostty | `ghostty/.config/ghostty/` | |
| gdu | `gdu/.gdu.yaml` | |
| git | `git/.config/git/` | |
| lazydocker | `lazydocker/.config/lazydocker/` | |
| lazygit | `lazygit/.config/lazygit/` | |
| aichat | `aichat/.config/aichat/` | Integrates `llm-functions` if present |
