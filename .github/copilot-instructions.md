# Repository overview

This repo is a GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose contents mirror the final target path, for example `hypr/.config/hypr`, `nvim/.config/nvim`, `tmux/.config/tmux`, `waybar/.config/waybar`, `walker/.config/walker`, `starship/.config/starship`, and `zsh/.zshrc`. Keep new files inside the existing package layout so they can be stowed without extra relocation logic.

Hyprland is the main desktop entrypoint. `hypr/.config/hypr/hyprland.conf` layers the setup in this order: Omarchy defaults from `~/.local/share/omarchy/default`, the active Omarchy theme from `~/.config/omarchy/current/theme`, local overrides from this repo (`monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`), then runtime toggle fragments from `~/.local/state/omarchy/toggles/hypr/*.conf`. Keep edits in the local override files instead of changing Omarchy-owned paths. App-specific Hypr rules belong under `hypr/.config/hypr/apps/*.conf` and are sourced via `app.conf`.

Waybar, Walker, and parts of Hyprland are coupled to Omarchy commands and theme assets. `waybar/.config/waybar/style.css` imports the current Omarchy theme CSS, and `waybar/.config/waybar/config.jsonc` uses `omarchy-*` commands for menu, updates, Wi-Fi, audio, idle, notifications, and screen recording. Preserve those integrations unless the change is intentionally replacing the Omarchy workflow.

Shell startup is split between `zsh/.zshrc` and Starship. Zsh loads Oh My Zsh first, then initializes Starship and points `STARSHIP_CONFIG` at `starship/.config/starship/starship.toml`. The Starship config shells out to helper scripts in `starship/.config/starship/battery/` and relies on `STARSHIP_CONFIG`-relative resolution, so keep those helpers beside `starship.toml`.

Neovim is a Kickstart-based config, not a fully custom distribution. Most editor behavior still lives in `nvim/.config/nvim/init.lua`; `lazy.nvim` imports extra plugin specs from `nvim/.config/nvim/lua/custom/plugins/*.lua`, and plugin versions are pinned in `nvim/.config/nvim/lazy-lock.json`. When adding or changing custom behavior, prefer a new or updated file in `lua/custom/plugins/`; only edit `init.lua` for shared core behavior that should stay in the Kickstart layer.

# Validation commands

There is no repo-wide build or test runner. Use tool-specific validation commands from the repo root:

```bash
zsh -n zsh/.zshrc
STARSHIP_CONFIG=$PWD/starship/.config/starship/starship.toml starship print-config >/dev/null
tmux -L dotfiles-check -f /dev/null start-server \; source-file "$PWD/tmux/.config/tmux/tmux.conf" \; kill-server
find nvim/.config/nvim -name '*.lua' -print0 | xargs -0 -n1 luac -p
shfmt -d starship/.config/starship/battery/*.sh hypr/.config/hypr/scripts/*.sh
```

Single-file checks:

```bash
luac -p nvim/.config/nvim/lua/custom/plugins/terminal.lua
shfmt -d hypr/.config/hypr/scripts/toggle-internal-display.sh
zsh -n zsh/.zshrc
```

# Key conventions

- Keep the top-level package structure stow-friendly. Add files under the package that owns their final target path instead of introducing ad hoc relocation scripts.
- Hyprland customizations override Omarchy defaults by sourcing local files; do not edit Omarchy-owned paths from this repo.
- When replacing an Omarchy keybinding in `hypr/.config/hypr/bindings.conf`, explicitly `unbind` the original binding before adding the new `bindd`.
- Keep Hypr application-specific rules in `hypr/.config/hypr/apps/*.conf` and source them from `app.conf` instead of mixing them into `hyprland.conf`.
- `waybar/.config/waybar/config.jsonc` is JSONC, so comments are valid and already used.
- Neovim custom plugins are modularized under `lua/custom/plugins/*.lua`; `init.lua` imports that directory with `{ import = 'custom.plugins' }`.
- The Neovim Lua style is defined in `nvim/.config/nvim/.stylua.toml`: 2-space indentation, Unix line endings, and a preference for single quotes with omitted call parentheses where valid.
- The Neovim config expects modern external tooling from the Kickstart setup, especially `git`, `make`, `rg`, `fd`, a clipboard tool, and current Neovim.
- Shell helpers in this repo are Bash scripts referenced directly from configs. Preserve their shebangs and the paths their callers expect rather than relocating them.
