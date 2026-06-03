# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME` — e.g., `hypr/.config/hypr/` → `~/.config/hypr/`, `zsh/.zshrc` → `~/.zshrc`.

There is no build system, tests, or CI. Validation is tool-specific syntax checks (see below).

## Commands

```bash
# Validate all components
zsh -n zsh/.zshrc
STARSHIP_CONFIG=$PWD/starship/.config/starship/starship.toml starship print-config >/dev/null
tmux -L dotfiles-check -f /dev/null start-server \; source-file "$PWD/tmux/.config/tmux/tmux.conf" \; kill-server
find nvim/.config/nvim -name '*.lua' -print0 | xargs -0 -n1 luac -p
shfmt -d starship/.config/starship/battery/*.sh hypr/.config/hypr/scripts/*.sh

# Deploy a package
stow <package-name> --simulate  # preview
stow <package-name>             # deploy
```

## Architecture Overview

**Desktop:** Hyprland is primary (modular config in `hypr/.config/hypr/` — sources `monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`). Niri (`niri/.config/niri/config.kdl`) is an alternative. Waybar (`waybar/`) integrates with Omarchy via `omarchy-*` commands and theme CSS import. Walker (`walker/`) is the launcher.

**Shell:** Zsh is primary (`zsh/.zshrc` → Oh My Zsh → modular configs in `zsh/.config/zsh/*.zsh` → Starship). The last lines of `.zshrc` auto-attach tmux on login if not already in one. Starship config lives in `starship/` with battery helper scripts.

**Editor:** Neovim is Kickstart-based (`nvim/.config/nvim/init.lua` + `vim.pack` plugins in `lua/custom/plugins/`). Plugin versions pinned in `nvim-pack-lock.json`.

**Tmux** (`tmux/.config/tmux/tmux.conf`) has helper scripts in `scripts/`. Pane output auto-logs to `~/.local/state/tmux/pane-logs/`.

**Other tools:** bat, eza (with theme in `eza/.config/eza/theme.yml`), ghostty (terminal), gdu, git (minimal config), lazydocker, lazygit, yazi, zellij, xdg-terminal-exec.

**Setup:** `zsh/.local/share/zsh/install.sh` is a cross-package-manager dependency installer that runs on shell startup if tools are missing.

## Key Conventions

- **Add files under the existing stow package that owns the target path.** `<package>/.config/<tool>/` → `~/.config/<tool>/`. Don't create ad-hoc relocation scripts.
- **Commit format:** `[Component] - Summary`. Component in title-case square brackets, dash separator, sentence-style summary. Examples: `[Hypr]`, `[Nvim]`, `[Tmux]`, `[Zsh]`, `[Starship]`. Details after blank line if needed.
- **Hyprland:** Don't edit Omarchy-owned paths. Override by sourcing local files. Application rules go in `hypr/.config/hypr/apps/*.conf`, sourced via `app.conf`. When replacing an Omarchy keybinding, `unbind` the original first.
- **Neovim:** Core behavior in `init.lua`. Custom plugins in `lua/custom/plugins/*.lua`. Stylua style: 2-space indent, single quotes, omit call parens where valid. Indentation: 2-space default, 4-space for Python/Go/Java/C/C++/Rust via `language-indent.lua`.
- **Shell scripts:** Bash shebang, 2-space indentation. Format with `shfmt -i 2` before committing.
- **Waybar:** `config.jsonc` is JSON with comments (fully valid). Preserve `omarchy-*` command integrations. `style.css` imports Omarchy theme CSS.
- **Starship:** Helper scripts sourced relative to `$STARSHIP_CONFIG` path. Keep them beside `starship.toml`.
- **Tmux:** Gate `extended-keys-format` behind tmux >= 3.5; tmux 3.4 supports `extended-keys` without the format flag.
- **bat vs batcat:** On Debian/Ubuntu the command is `batcat`. Check for both in scripts.
- **Full existing conventions** documented in `.github/copilot-instructions.md` — refer to it for details not covered here.

## Omarchy Integration Points

Hyprland, Waybar, Walker, and Yazi all integrate with Omarchy (theme system and `omarchy-*` commands). When modifying these, test against the active Omarchy theme. Breaking changes to Omarchy paths need a commit-body note.
