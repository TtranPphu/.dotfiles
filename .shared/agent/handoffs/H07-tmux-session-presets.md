# H07 — tmux session presets

## Goal

Add a preset picker to the shell startup flow: after choosing tmux (no auto-launch), show a menu of session presets. Presets define a working directory, windows, and pane splits. A `default` preset preserves current behavior (single shell pane at `$PWD`). A `dotfiles` preset creates a session at `~/.dotfiles` with 3 windows running `opencode`, `nvim`, and a bare shell pane (tmux auto-names it). The data structure must support multi-app windows (auto-split at 50%/25%/12.5% ... ratios) and be extensible to multi-session presets in the future.

## Sample

Expected picker output (terminal rendering):

```
Session presets:
   dotfiles:   opencode  nvim   shell
Pick: _
```

- Session icon ``, window icon ``.
- First char of session name highlighted green.
- Window labels: first app name for non-empty windows, `shell` (brightblack foreground) for bare shell windows.
- Colon right-padded to align all session rows.
- Single-char input, no Enter needed.
- Unrecognized key falls to default preset.
- `d` and `D` both match `dotfiles`.

## Deliverables

### 1. Create `zsh/.config/zsh/session-presets.zsh`

Auto-sourced by `.zshrc` via the existing `for config in ~/.config/zsh/*.zsh; source "$config"` loop. Must contain:

- A `session_presets` associative array: keys are single-char shortcuts, values are pipe-delimited records (key, display name, working dir, window spec string). Window spec uses `;` between windows, `,` between apps in one window. Empty string after a `;` means bare shell pane (tmux auto-names it).
- Two presets: `default` (empty string key, session at `$PWD`, no windows) and `d` (dotfiles, dir `~/.dotfiles`, 3 windows: `opencode` first pane, `nvim` second pane, empty third pane for bare shell).
- A `create_from_preset` function: parse the preset record, derive session name from dir basename (strip leading dot, replace remaining dots with hyphens). If session exists, attach to it. Create the session with `new-session -d`, first window named after its first app, apps sent via `send-keys Enter`. Subsequent apps in the first window split the last created pane (horizontal if width > 2× height, else vertical) for natural 50%/25%/12.5% ratios. Remaining windows created with `new-window` in a loop; empty windows get no name (just `new-window`, tmux auto-names via `automatic-rename`), non-empty windows named after first app. End with `clear; exec tmux attach-session`.
- A `tmux_session_picker` function: print "Session presets:", iterate presets (skip default), build icon string with `` per window (first app name text, or "shell" in brightblack ANSI for empty windows). Display each preset as ` <green-first-char><reset><rest>:<padded>icons`. Prompt "Pick:", read one char, match case-insensitively, fall through to default on no match.

### 2. Modify `zsh/.zshrc` (lines 132-157)

Replace both tmux entry points with `tmux_session_picker`:

- **Only tmux available** (`else if` branch after zellij check): call `tmux_session_picker` after `clear` and setting `DOTFILES_SHELL_PICKED=1`.
- **tmux chosen from menu** (`t|T` case): same, remove the old `exec tmux new -A` command.

### 3. Modify `nu/.config/nushell/config.nu`

Mirror same behavior using nushell record syntax. Presets are a record with fields `key`, `name`, `dir`, `windows` (list of lists). Use `str downcase` on picker input for case-insensitive matching. Use `get -o` (`--optional`) instead of deprecated `get -i` for safe record access. Use `fill -c` for padding instead of removed `str repeat`.

Key blocks to change:

- **Double picker → t case**: same flow as zsh: print presets, read input, resolve preset, check session existence, create windows programmatically.
- **Only tmux available**: same `else if $has_tmux` branch.

Both branches share identical window creation logic: handle empty windows vs multi-app windows, same split strategy.

### 4. Update picker display in both `session-presets.zsh` and `config.nu`

When listing windows in the picker, empty window entries should show a brightblack-colored ` shell` icon and label. Non-empty windows show the first app name without special coloring.

## Deployment

```bash
stow -R zsh
stow -R nu
```

Verify both files are linked:
```bash
ls -la ~/.config/zsh/session-presets.zsh    # linked to dotfiles
ls -la ~/.config/nushell/config.nu          # linked to dotfiles
```

## Key Findings

- **Auto-sourcing**: `.zshrc` already sources `~/.config/zsh/*.zsh` — new file is zero-config.
- **Session naming**: basename of dir, strip leading dot, replace remaining dots with hyphens.
- **`new -A` vs `new-session -d`**: Since we build windows programmatically, use `new-session -d` + `has-session` check + `attach-session`.
- **Split ratio**: Splitting the last created pane gives 50%/25%/12.5%/... naturally (tmux `split-window` splits 50/50).
- **Split direction**: Horizontal if width > 2× height, else vertical.
- **No auto-launch**: Both "only tmux" and "both → t" go through preset picker.
- **No rename tampering**: Empty windows get a bare `new-window` — tmux's `automatic-rename` is left alone. The picker may show "shell" as a display icon, but the actual window title is tmux's decision.
- **Nushell 0.112 compat**: `get -i` deprecated → use `get --optional`. `str repeat` removed → use `fill -c`.
- **Case sensitivity**: Nushell record keys are case-sensitive; use `str downcase` on input. Zsh uses `${(L)}` parameter expansion.

## Potential Issues

1. **`$(pwd)` in default preset** evaluated at source time, not picker time. Use `$PWD` (zsh variable, not subshell) as safety.
2. **Nushell `$env.PWD`** behaves the same as zsh `$PWD` — correct.
3. **Session name collision**: `has-session` check means re-selecting a preset switches to existing session. Matches `new -A` behavior.
4. **Separator chars** `;` and `,` could conflict with unusual directory names. Not an issue for current presets.
5. **Default preset empty windows**: Falls back to a single-pane session with `attach-session`.
6. **Picker icon color**: Empty window icon+label rendered in brightblack ANSI (`\033[90m`) to visually separate it from app windows.

## Verification

1. Open terminal outside tmux — picker shows (no auto-launch).
2. Press `t` — preset picker lists `dotfiles` with window icons.
3. Enter (default) — session named after `$PWD`, single shell pane.
4. Press `d` — session named `dotfiles` at `~/.dotfiles`, 3 windows (opencode, nvim, bare shell).
5. Open another terminal, press `t` then `d` — switches to existing `dotfiles` session (no duplicate).
6. Repeat from nu — same behavior.
7. Invalid key → falls to default.
8. `D` (uppercase) → same as `d`.
