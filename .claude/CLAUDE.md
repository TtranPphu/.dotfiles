# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Communication Style

See [`.shared/agent/communication-style.md`](/.shared/agent/communication-style.md).

## Keywords

See [`.shared/agent/keywords.md`](/.shared/agent/keywords.md).

## What This Repo Is

A GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose internal path mirrors `$HOME`. There is no build system, tests, or CI.

## Key Conventions

See [`.shared/agent/conventions.md`](/.shared/agent/conventions.md).

## Architecture Overview

**Desktop:** Hyprland is primary (modular config sources: `monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`). Waybar and Walker integrate with Omarchy.

**Shell:** Zsh → Oh My Zsh → `zsh/.config/zsh/*.zsh` → Starship. Auto-attaches tmux on login.

**Editor:** Neovim is Kickstart-based. Plugins in `lua/custom/plugins/*.lua`, versions pinned in `nvim-pack-lock.json`.

**Tmux:** Config in `tmux/.config/tmux/tmux.conf` sourcing `bindings.conf` and `theme.conf`. Helper scripts in `scripts/`. Pane output auto-logs to `~/.local/state/tmux/pane-logs/`.

**Other tools:** bat, eza, ghostty, git, lazydocker, lazygit, yazi.

## Omarchy Integration Points

Hyprland, Waybar, Walker, and Yazi integrate with Omarchy (theme system and `omarchy-*` commands). Test against the active Omarchy theme when modifying these.
