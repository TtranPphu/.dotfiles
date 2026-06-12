# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code).

## Communication Style

- Answer in one concise sentence unless the user asks for more detail.
- If you don't know, just say so. If unsure, ask for clarification.
- Answer in the same language as the user's query.
- Answer directly without XML tags in your response text.
- Don't include thinking or reasoning in the response unless asked.
- If the user types a CLI command with typos or wrong casing, just hint the correct command.

## Keywords

- **picker** — The shell/multiplexer picker at startup: `zsh/.zshrc` (zsh) and `nu/.config/nushell/config.nu` (nushell). Lets you choose between zsh/nushell shells and tmux/zellij multiplexers.

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
