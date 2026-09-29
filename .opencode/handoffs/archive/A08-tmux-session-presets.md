# Tmux session presets

## Summary
Added a preset picker to the shell startup flow for both zsh and nushell. After choosing tmux, a menu shows session presets (dotfiles, tiny-repository, zmk-keyboard-cornix) with window icons. Presets define a working directory, windows, and pane splits with intelligent split direction (horizontal if wide, vertical if tall). The `default` preset preserves original behavior (single shell pane at `$PWD`).

## Files
- `zsh/.config/zsh/session-presets.zsh` — `session_presets` associative array, `create_from_preset` with multi-window/multi-pane creation, `tmux_session_picker` with ANSI-colored menu
- `zsh/.zshrc` — calls `tmux_session_picker` on `t` picker choice
- `nu/.config/nushell/config.nu` — `_session_picker` function, called from both "only tmux" and "t/T" branches

## Key decisions
- Auto-sourcing via existing `~/.config/zsh/*.zsh` loop — zero config
- Session name derived from directory basename (strip leading dot, replace remaining dots with hyphens)
- `resolve_app` maps short names to full commands (e.g. `opencode` → `opencode --continue` if sessions exist)
- Empty windows get bare `new-window` — tmux `automatic-rename` left untouched
- Nushell uses `get --optional` and `fill -c` for 0.112 compatibility

## Future iteration notes
- Presets are hardcoded — could be made configurable via a data file
- The "only tmux" zsh path clears to shell instead of auto-showing the picker (user must press `t`), though nushell side auto-invokes the picker
