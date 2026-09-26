# Conventions

- **Add files under the stow package that owns the target path.** Don't create ad-hoc relocation scripts.
- **No auto-committing.** Use the `/commit` skill.
- **Hyprland:** Don't edit Omarchy-owned paths. Override by sourcing local files. `unbind` before replacing Omarchy keybindings. App rules go in `hypr/.config/hypr/apps/*.conf`.
- **Neovim:** Only work in `lua/custom/plugins/*.lua`. Don't touch `init.lua`.
- **Shell scripts:** Bash shebang, 2-space indentation. Format with `shfmt -i 2`.
- **Waybar:** Preserve `omarchy-*` command integrations. `style.css` imports Omarchy theme CSS. `config.jsonc` is JSON with comments.
- **Tmux:** Gate `extended-keys-format` behind tmux >= 3.5.
- **bat vs batcat:** On Debian/Ubuntu check for both.
