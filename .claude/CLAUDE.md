# CLAUDE.md

## Important Rules

- Never create git commits unless explicitly asked by the user.
- Always mind the changes the user made during the session before making your own.

## Communication Style

See [communication style guide](.shared/agent/communication-style.md).

## Keywords

See [keywords reference](.shared/agent/keywords.md).

## Key Conventions

See [conventions guide](.shared/agent/conventions.md).

## Shared Agent Resources

This repo ships reusable agent resources in `.shared/agent/`:
- **Skills** — Slash commands like `/commit`, `/stow-deploy`, `/pane-capture`, `/pane-logs`, `/handoff` ([skills directory](.shared/agent/skills/))
- **Handoffs** — Context handoff documents for multi-session tasks ([handoffs directory](.shared/agent/handoffs/))

## What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME`. There is no build system, tests, or CI.

## Architecture Overview

**Desktop:** Hyprland is primary (modular config sources: `monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`). Waybar and Walker integrate with Omarchy.

**Shell:** Zsh → Oh My Zsh → `zsh/.config/zsh/*.zsh` → Starship. Auto-attaches tmux on login.

**Editor:** Neovim is Kickstart-based. Plugins in `lua/custom/plugins/*.lua`, versions pinned in `nvim-pack-lock.json`.

**Tmux:** Config in `tmux/.config/tmux/tmux.conf` sourcing `bindings.conf` and `theme.conf`. Helper scripts in `scripts/`. Pane output auto-logs to `~/.local/state/tmux/pane-logs/`.

**Other tools:** bat, eza, ghostty, git, lazydocker, lazygit, yazi.

## Omarchy Integration Points

Hyprland, Waybar, Walker, and Yazi integrate with Omarchy (theme system and `omarchy-*` commands). Test against the active Omarchy theme when modifying these.
