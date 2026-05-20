# Repository Overview

This is a GNU Stow-style dotfiles collection. Each top-level directory is a stow package whose directory structure mirrors the final target paths in `$HOME`. For example, `hypr/.config/hypr` deploys to `~/.config/hypr`, `nvim/.config/nvim` to `~/.config/nvim`, and `zsh/.zshrc` to `~/.zshrc`.

**Core principle:** Keep new files inside the existing package structure so they can be deployed with `stow <package-name>` without requiring additional relocation logic.

## Desktop Environment

**Hyprland** (`hypr/`) is the main desktop entrypoint. Configuration is layered in this order:
1. Omarchy defaults from `~/.local/share/omarchy/default`
2. Active Omarchy theme from `~/.config/omarchy/current/theme`
3. Local overrides from this repo (`monitors.conf`, `input.conf`, `bindings.conf`, `looknfeel.conf`, `autostart.conf`, `app.conf`)
4. Runtime toggle fragments from `~/.local/state/omarchy/toggles/hypr/*.conf`

Keep edits in local override files, not in Omarchy-owned paths. App-specific Hypr rules belong in `hypr/.config/hypr/apps/*.conf` and are sourced via `app.conf`, not mixed into `hyprland.conf`.

**Niri** (`niri/`) is an alternative compositor config in `niri/.config/niri/config.kdl`. Maintain separate window manager configs; the active one is set at system startup.

## UI and Theming

**Waybar** (`waybar/`) is the system taskbar. Its config integrates with Omarchy:
- `config.jsonc` uses `omarchy-*` commands for menu, updates, Wi-Fi, audio, idle, notifications, and screen recording
- `style.css` imports the current Omarchy theme CSS
- Preserve these integrations unless intentionally replacing the Omarchy workflow

**Walker** (`walker/`) is the application launcher. Themes are stored in `walker/.config/walker/themes/omarchy-default/` to integrate with Omarchy theme switching.

**Yazi** (`yazi/`) is the file manager with keybinds in `keymap.toml` and theme in `theme.toml`. Theming typically matches the active Omarchy theme.

## Shell and Prompts

**Zsh** (`zsh/`) is the primary shell. Startup sequence:
1. `zsh/.zshrc` loads Oh My Zsh first
2. Then initializes Starship and sets `STARSHIP_CONFIG` to `starship/.config/starship/starship.toml`
3. Modular Zsh configs are in `zsh/.config/zsh/` (e.g., `eza.zsh`)

**Starship** (`starship/`) is the shell prompt. Helper scripts in `starship/.config/starship/battery/` (e.g., `status.sh`, `mid.sh`) handle battery display and rely on `STARSHIP_CONFIG`-relative resolution, so keep them beside `starship.toml`.

## Editors and Tools

**Neovim** (`nvim/`) is a Kickstart-based distribution, not fully custom:
- Core behavior lives in `nvim/.config/nvim/init.lua`
- `lazy.nvim` imports plugin specs from `nvim/.config/nvim/lua/custom/plugins/*.lua`
- Plugin versions are pinned in `lazy-lock.json`
- Prefer new files in `lua/custom/plugins/` for custom behavior; edit `init.lua` only for shared core behavior

**Bat** (`bat/`) is a syntax-highlighting pager. Simple config in `bat/.config/bat/config`.

**Eza** (`eza/`) is a modern `ls` replacement with theme in `eza/.config/eza/theme.yml`.

## Other Utilities

- **Ghostty** (`ghostty/`) — Terminal emulator config at `ghostty/.config/ghostty/config`
- **Gdu** (`gdu/`) — Disk usage analyzer configured in `gdu/.gdu.yaml`
- **Walker** (`walker/`) — Application launcher (see UI section above)

# Validation Commands

There is no repo-wide build or test runner. Use tool-specific validation commands from the repo root:

## Full Validation Suite

```bash
# Zsh syntax check
zsh -n zsh/.zshrc

# Starship configuration validation
STARSHIP_CONFIG=$PWD/starship/.config/starship/starship.toml starship print-config >/dev/null

# Tmux configuration check (uses isolated session)
tmux -L dotfiles-check -f /dev/null start-server \; source-file "$PWD/tmux/.config/tmux/tmux.conf" \; kill-server

# Neovim Lua syntax check (all files)
find nvim/.config/nvim -name '*.lua' -print0 | xargs -0 -n1 luac -p

# Shell script formatting check
shfmt -d starship/.config/starship/battery/*.sh hypr/.config/hypr/scripts/*.sh
```

## Single-Component Checks

```bash
# Neovim specific file
luac -p nvim/.config/nvim/lua/custom/plugins/terminal.lua

# Hyprland script
shfmt -d hypr/.config/hypr/scripts/toggle-internal-display.sh

# Zsh only
zsh -n zsh/.zshrc

# Bat syntax
bat --config-file bat/.config/bat/config --list-themes >/dev/null

# Eza theme
cat eza/.config/eza/theme.yml >/dev/null

# Yazi config
cat yazi/.config/yazi/yazi.toml >/dev/null

# Ghostty config
cat ghostty/.config/ghostty/config >/dev/null
```

# Key Conventions

## Repository Structure

- **Top-level package structure is stow-friendly.** Add files under the package that owns their final target path instead of introducing ad hoc relocation scripts.
- Maintain the mirror structure: `<package>/.config/<tool>/` deploys to `~/.config/<tool>/`, `zsh/.zshrc` deploys to `~/.zshrc`, etc.
- Each package is independently deployable via `stow <package>` from the dotfiles root.

## Hyprland (`hypr/`)

- Hyprland customizations **override** Omarchy defaults by sourcing local files; do not edit Omarchy-owned paths from this repo.
- When replacing an Omarchy keybinding in `bindings.conf`, **explicitly `unbind` the original binding** before adding the new one.
  ```conf
  unbind = SUPER, W         # Original Omarchy binding
  bind = SUPER SHIFT, E, exec, [float] copyq show  # New binding
  ```
- Application-specific rules belong in `hypr/.config/hypr/apps/*.conf` (e.g., `apps/telegram.conf`, `apps/steam.conf`) and are sourced via `app.conf`.
- Do not add app rules directly to `hyprland.conf`; modularize them into separate files.
- Keep override files (`monitors.conf`, `input.conf`, `bindings.conf`, `autostart.conf`) focused on their purpose.

## Waybar (`waybar/`)

- `config.jsonc` is JSON with comments; comments are fully valid.
- Uses `omarchy-*` commands for dynamic theming and menu integration. Preserve these unless replacing the Omarchy workflow.
- `style.css` imports the current Omarchy theme via `@import url("file:///...omarchy/current/theme/waybar.css")`.
- Keep custom styles in `style.css` only if they override or extend the theme.

## Walker (`walker/`)

- Themes live in `walker/.config/walker/themes/omarchy-default/`.
- Layout in `layout.xml`, styling in `style.css`.
- These paths tie Walker to the Omarchy theme system; preserve the integration.

## Yazi (`yazi/`)

- Configuration: `yazi.toml` (main settings), `keymap.toml` (keybindings), `theme.toml` (colors and styling).
- Themes typically match the active Omarchy theme unless intentionally diverging.
- Plugin support is available; prefer config over plugins for simple customizations.

## Neovim (`nvim/`)

- **Kickstart-based**, not a full distribution. Most setup is intentionally minimal.
- Core behavior lives in `init.lua`; `lazy.nvim` manages plugins.
- **Modularize custom plugins** under `lua/custom/plugins/*.lua`. Each file is imported via `{ import = 'custom.plugins' }` in `init.lua`.
- Plugin versions are pinned in `lazy-lock.json`; update via `:Lazy sync` inside Nvim.
- **Indentation defaults to 2 spaces** globally (via `expandtab`, `shiftwidth=2`, `softtabstop=2` in `init.lua`).
  - **Tab display width:** Set to 8 spaces so actual tab characters are immediately visible and identifiable (helps catch accidental tabs).
  - **Language-specific overrides** in `lua/custom/plugins/language-indent.lua`:
    - Python, Go, Java, C, C++, Rust: 4 spaces (language conventions)
    - TypeScript, JavaScript, HTML, CSS, JSON, YAML, TOML: 2 spaces (explicit)
    - Easily add more languages to the `indent_map` table in `language-indent.lua`
- **Style conventions** (`.stylua.toml`): 2-space indentation, Unix line endings, single quotes, omitted call parentheses where valid.
  ```lua
  local opts = { noremap = true, silent = true }  -- not opts()
  local msg = 'hello world'  -- not "hello world"
  ```
- Only edit `init.lua` for shared core behavior (e.g., keymap setup, core plugin loading); custom features go in `lua/custom/`.

## Tmux (`tmux/`)

- Main configuration in `tmux.conf`.
- Helper scripts in `scripts/` (e.g., `scripts/status-left`, `scripts/pane-log`, `scripts/status-hint`).
- Status hint scripts load keybinding help into variables like `@status-hint-prefix-1` and `@status-hint-prefix-2`.
- Pane output is logged by default to `~/.local/state/tmux/pane-logs/<pane_id>.log` and cleaned up on pane exit/kill.
- Gate extended-keys-format behind tmux >= 3.5; tmux 3.4 only supports extended-keys without the format flag.

## Zsh (`zsh/`)

- Startup: `zsh/.zshrc` loads Oh My Zsh, then initializes Starship with `STARSHIP_CONFIG` pointing to `starship/.config/starship/starship.toml`.
- Modular configs in `zsh/.config/zsh/` (e.g., `eza.zsh` for eza aliases).
- Oh My Zsh theme is disabled; Starship is the primary prompt.
- **Shell script style:** 2-space indentation, Bash shebang.

## Starship (`starship/`)

- Main config: `starship/.config/starship/starship.toml`.
- Helper scripts in `battery/` (e.g., `low.sh`, `mid.sh`, `high.sh`, `status.sh`) for battery display.
- Scripts are sourced relative to `$STARSHIP_CONFIG`, so keep them beside `starship.toml`.
- Starship shells out to these scripts; preserve the relative paths and helper structure.

## Shell Scripts

- All shell scripts in this repo use **2-space indentation**.
- Preserve shebangs and paths as called by configs; relocating scripts breaks references.
- Examples: `starship/.config/starship/battery/status.sh`, `hypr/.config/hypr/scripts/toggle-internal-display.sh`.
- Format shells scripts with `shfmt -d <file>` before committing.

## Bat, Eza, Ghostty, Gdu

- **Bat** (`bat/`): Simple config file at `bat/.config/bat/config`. Theme is set here.
- **Eza** (`eza/`): Theme in `eza/.config/eza/theme.yml`. Colors typically match Omarchy or terminal theme.
- **Ghostty** (`ghostty/`): Terminal emulator config at `ghostty/.config/ghostty/config`. Minimal, straightforward settings.
- **Gdu** (`gdu/`): Disk usage tool config in `gdu/.gdu.yaml`. Simple, focused on display preferences.

## Documentation

- Each component may have inline comments in config files explaining non-obvious settings, but avoid over-commenting.
- When editing a package, verify syntax with the tool's own validation commands before committing.
- Breaking changes to Omarchy integration (e.g., replacing a theme) should be noted in the commit body.

# Commit Message Convention

All commits follow this format:

```
[Component] - Brief description

Optional detailed explanation of the change, rationale, or context.
```

## Guidelines

- **Component prefix** in square brackets (not angle brackets). Examples: `[Hypr]`, `[Nvim]`, `[Tmux]`, `[Zsh]`, `[Waybar]`, `[Starship]`, etc.
- **Capitalization:** Component is title-case (e.g., `[Neovim]` not `[neovim]`), summary uses sentence-style capitalization.
- **Dash separator:** Use ` - ` (space, dash, space) between the component and summary.
- **Summary line:** Keep it concise and descriptive. Avoid redundancy (don't say "Update [Component]", just describe the change).
- **Body:** Add 1–3 lines of explanation when helpful (e.g., rationale, side effects, interaction with other components).
- **Length:** First line should be ~60 characters or less; keep total commit message focused.

## Examples

### Good commits
```
[Hypr] - Unbind default keybinding and add new audio toggle

When replacing Omarchy keybindings, the original must be explicitly
unbound before adding the replacement. This prevents conflicts with
the Omarchy default layer.
```

```
[Nvim] - Add lint plugin for JavaScript/TypeScript
```

```
[Tmux] - Fix status line color on session switch

Updated the session-info script to clear color codes before printing.
```

```
[Zsh] - Refactor eza configuration into separate module

Moved eza aliases and options to zsh/.config/zsh/eza.zsh for clarity
and easier maintenance.
```

### Avoid

- `[Hyprland] - Update Hyprland config` (redundant)
- `[nvim] - add lint plugin` (wrong capitalization and dash format)
- `Hypr: Update config` (missing square brackets)
- `Fix stuff` (no component prefix)

---

# Common Tasks

## Adding a New Component

1. Create a top-level directory named after the tool: `mkdir -p <tool-name>`.
2. Mirror the target directory structure: `<tool-name>/.config/<tool-name>/` for standard config tools, or `<tool-name>/.local/share/<tool-name>/` for data, etc.
3. Add config files to the mirrored paths.
4. Test deployment: `stow <tool-name> --simulate` to preview changes.
5. Deploy: `stow <tool-name>`.
6. Validate tool-specific syntax (see Validation Commands).
7. Commit with `[ComponentName] - Initialize <tool> configuration`.

## Updating Omarchy Integration

When modifying components that integrate with Omarchy (Hyprland, Waybar, Walker, Yazi):

1. Test the change against the active Omarchy theme before committing.
2. If replacing a keybinding, explicitly `unbind` the old one (Hypr only).
3. If changing theme imports or paths, verify the Omarchy theme path remains valid.
4. Document breaking changes in the commit body (e.g., "Omarchy theme v1.5+ required").
5. Keep override files separate from Omarchy-owned directories.

## Adding a Neovim Plugin

1. Create a new file in `nvim/.config/nvim/lua/custom/plugins/<plugin-name>.lua`.
2. Define the plugin spec following `lazy.nvim` conventions (return a table or list).
3. Use `.stylua.toml` style: 2-space indents, single quotes, omitted call parens.
4. Validate syntax: `luac -p nvim/.config/nvim/lua/custom/plugins/<plugin-name>.lua`.
5. Test in Nvim: `:Lazy load <plugin-name>` or `:Lazy sync`.
6. Commit with `[Nvim] - Add <plugin-name> plugin`.

## Adding a Shell Script

1. Create the script in the appropriate package (e.g., `hypr/.config/hypr/scripts/myscript.sh` or `starship/.config/starship/battery/custom.sh`).
2. Use Bash shebang: `#!/bin/bash`.
3. Follow 2-space indentation throughout.
4. If sourced from configs, preserve the relative path references.
5. Format: `shfmt -i 2 -w <script-path>`.
6. Validate: `shfmt -d <script-path>` (should produce no output).
7. Commit with `[Component] - Add <script-description>`.

## Fixing or Enhancing a Component

1. Identify the package and the specific file(s) to change.
2. Make the change and save.
3. Run validation for that tool (e.g., `zsh -n zsh/.zshrc` for Zsh changes).
4. Test the change in the actual tool if possible (e.g., reload Zsh, `:source` in Nvim, tmux `source-file`).
5. Commit with clear, component-focused message.
6. If the change affects Omarchy integration, note it in the body.

---

# Documentation

When updating or documenting a component:

- **Inline comments:** Use them sparingly in config files for non-obvious settings only.
- **This file:** Update `.github/copilot-instructions.md` if adding new components or changing architectural patterns.
- **Commit bodies:** Explain *why* a change was made, not just what (e.g., "Disabled autocd in Oh My Zsh because it interferes with navigation in Yazi").
- **Breaking changes:** Always mention in the commit body if the change requires manual setup steps or Omarchy version constraints.

---

# Omarchy Integration Notes

Several components integrate with Omarchy theme and command systems:

1. **Hyprland** (`hypr/`): Layers Omarchy defaults, then applies local overrides.
2. **Waybar** (`waybar/`): Uses `omarchy-*` commands for dynamic features; imports theme CSS.
3. **Walker** (`walker/`): Themes stored in `omarchy-default/` for consistency.
4. **Yazi** (`yazi/`): Typically matches active Omarchy theme.
5. **Starship** (`starship/`): Can shell out to external scripts; independent of Omarchy but compatible.

When modifying these components, test against the active Omarchy theme and preserve command/path references unless intentionally replacing the workflow.

---

# Deployment and Testing

After making changes:

1. Validate syntax for the changed component(s) using the appropriate tool.
2. If changes span multiple components, validate each one.
3. For UI changes (Hypr, Waybar, Yazi, etc.), test in the running environment when possible.
4. For shell changes (Zsh, Starship, scripts), source or reload the configuration.
5. For Nvim, use `:Lazy sync` to ensure plugins are updated and validated.
6. Commit only after validation passes.

Use this workflow before pushing or creating PRs to ensure the repository stays in a working state.
