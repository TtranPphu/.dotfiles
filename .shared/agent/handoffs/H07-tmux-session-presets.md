# H07 — tmux session presets

## Goal

Add a preset picker to the shell startup flow: after choosing tmux (no auto-launch), show a numbered menu of session presets. Presets define a working directory, windows, and pane splits. A `default` preset preserves current behavior (single shell pane at `$PWD`). A `dotfiles` preset creates a session at `~/.dotfiles` with 3 windows running `opencode`, `nvim`, and `zsh` (each `exec`'d). The data structure must support multi-app windows (auto-split at 50%/25%/12.5% ... ratios) and be extensible to multi-session presets in the future.

## Deliverables

### 1. Create `zsh/.config/zsh/session-presets.zsh`

Auto-sourced by `.zshrc` via the existing `for config in ~/.config/zsh/*.zsh; source "$config"` loop (line 117). Contains:

```zsh
# session_presets[key]="key|display_name|dir|window1_apps;window2_apps;..."
#   - key: single char for picker (empty = default fallback)
#   - display_name: shown in picker menu
#   - dir: working directory for all windows
#   - windows: separated by `;`, each window's apps separated by `,`
#   - empty windows = default behavior (single shell pane, no exec)

typeset -A session_presets
session_presets[default]="|default|$(pwd)|"
session_presets[d]="d|dotfiles|${HOME}/.dotfiles|opencode;nvim;zsh"

create_from_preset() {
  local preset_key="$1"
  local def="${session_presets[$preset_key]}"
  [[ -z "$def" ]] && def="${session_presets[default]}"
  [[ -z "$def" ]] && return 1

  local IFS='|'
  local -a fields=("${(@s:|:)def}")
  local key="${fields[1]}"
  local name="${fields[2]}"
  local dir="${fields[3]}"
  local windows_str="${fields[4]:-}"

  # Session name from dir (current auto-naming logic)
  local session_name="${${${dir##*/}#.}//./-}"
  [[ -z "$session_name" ]] && session_name="shell"

  # If session exists, switch to it (matches new -A behavior)
  if tmux has-session -t "$session_name" 2>/dev/null; then
    exec tmux switch-client -t "$session_name"
  fi

  # Parse windows
  local -a windows
  IFS=';' read -rA windows <<< "$windows_str"

  # Create session with first window
  if [[ ${#windows} -eq 0 || -z "${windows[1]}" ]]; then
    # No windows defined = default behavior: single shell pane
    tmux new-session -d -s "$session_name" -c "$dir"
    exec tmux attach-session -t "$session_name"
  fi

  local first_win="${windows[1]}"
  local -a first_apps=("${(@s:,:)first_win}")

  tmux new-session -d -s "$session_name" -c "$dir" -n "${first_apps[1]}"
  tmux send-keys -t "${session_name}:1.1" "exec ${first_apps[1]}" Enter

  # Additional apps in first window: split last created pane
  # This achieves 50%/25%/12.5%/... ratios automatically
  local pane="1"
  local -i total_apps=${#first_apps}
  for (( i = 2; i <= total_apps; i++ )); do
    local app="${first_apps[$i]}"
    local pane_width pane_height
    pane_width=$(tmux display-message -p -t "${session_name}:1.${pane}" '#{pane_width}')
    pane_height=$(tmux display-message -p -t "${session_name}:1.${pane}" '#{pane_height}')
    if (( pane_width > pane_height * 2 )); then
      pane=$(tmux split-window -h -t "${session_name}:1.${pane}" -c "$dir" -P -F '#{pane_index}')
    else
      pane=$(tmux split-window -v -t "${session_name}:1.${pane}" -c "$dir" -P -F '#{pane_index}')
    fi
    tmux send-keys -t "${session_name}:1.${pane}" "exec $app" Enter
  done

  # Remaining windows
  local -i win_idx=2
  for win_def in "${windows[@]:1}"; do
    [[ -z "$win_def" ]] && continue
    local -a apps=("${(@s:,:)win_def}")
    tmux new-window -t "$session_name" -c "$dir" -n "${apps[1]}"
    tmux send-keys -t "${session_name}:${win_idx}.1" "exec ${apps[1]}" Enter
    local pane="1"
    local -i napps=${#apps}
    for (( i = 2; i <= napps; i++ )); do
      local app="${apps[$i]}"
      local pane_width pane_height
      pane_width=$(tmux display-message -p -t "${session_name}:${win_idx}.${pane}" '#{pane_width}')
      pane_height=$(tmux display-message -p -t "${session_name}:${win_idx}.${pane}" '#{pane_height}')
      if (( pane_width > pane_height * 2 )); then
        pane=$(tmux split-window -h -t "${session_name}:${win_idx}.${pane}" -c "$dir" -P -F '#{pane_index}')
      else
        pane=$(tmux split-window -v -t "${session_name}:${win_idx}.${pane}" -c "$dir" -P -F '#{pane_index}')
      fi
      tmux send-keys -t "${session_name}:${win_idx}.${pane}" "exec $app" Enter
    done
    ((win_idx++))
  done

  exec tmux attach-session -t "$session_name"
}


tmux_session_picker() {
  echo "Session presets:"
  local keys=()
  for key val in "${(@kv)session_presets}"; do
    [[ -z "$key" ]] && continue
    keys+=("$key")
    local fields=("${(@s:|:)val}")
    echo "${key}. ${fields[2]}"
  done
  echo "Enter: default"
  echo -n "Pick: "
  read -r -k1 choice
  echo

  local matched="${session_presets[${(L)choice}]}"
  if [[ -z "$matched" ]]; then
    create_from_preset "default"
  else
    create_from_preset "${(L)choice}"
  fi
}
```

### 2. Modify `zsh/.zshrc` (lines 132-157)

Replace both tmux paths with preset picker call.

**Line 134-135** (only tmux available — replace auto-launch):
```zsh
  if command -v tmux >/dev/null 2>&1 && ! command -v zellij >/dev/null 2>&1; then
    clear && export DOTFILES_SHELL_PICKED=1
    tmux_session_picker
  fi
```

**Line 152** (tmux picked from menu):
```zsh
      t|T) clear && export DOTFILES_SHELL_PICKED=1
        tmux_session_picker ;;
```

Remove the `exec` from the `t` case (no longer needed — `create_from_preset` ends with `exec`). The `exec` on line 152 changes to just calling `tmux_session_picker`.

### 3. Modify `nu/.config/nushell/config.nu`

Mirror same behavior after `t` case (line 26):

```nu
"t" | "T" => {
    clear
    $env.DOTFILES_SHELL_PICKED = "1"
    let presets = {
        default: { key: "", name: "default", dir: $env.PWD, windows: [] }
        d: { key: "d", name: "dotfiles", dir: $"($env.HOME)/.dotfiles", windows: [[opencode], [nvim], [zsh]] }
    }
    print "Session presets:"
    for p in ($presets | transpose key val | where key != "default") {
        print $"($p.key). ($p.val.name)"
    }
    print "Enter: default"
    print -n "Pick: "
    let choice = (input --numchar 1 --suppress-output)
    let preset = ($presets | get -i $choice | default ($presets | get -i "default"))
    if ($preset | is-empty) {
        tmux new -A -s ($env.PWD | path basename | str replace --regex '^\.' '' | str replace --all '.' '-') nu; exit
    }
    let dir = $preset.dir
    let session = ($dir | path basename | str replace --regex '^\.' '' | str replace --all '.' '-')
    if (tmux has-session -t $session | complete | get exit_code) == 0 {
        tmux switch-client -t $session; exit
    }
    let windows = $preset.windows
    if ($windows | length) == 0 {
        tmux new-session -d -s $session -c $dir; tmux attach-session -t $session; exit
    }
    let first = ($windows | first)
    tmux new-session -d -s $session -c $dir -n ($first | first)
    tmux send-keys -t $"($session):1.1" $"exec ($first | first)" Enter
    # Split remaining apps in first window + create remaining windows
    # (mirrors zsh logic — see full implementation in the file)
    tmux attach-session -t $session; exit
}
```

## Deployment

```bash
stow -R zsh
stow -R nu
```

Verify:
```bash
ls -la ~/.config/zsh/session-presets.zsh    # linked to dotfiles
ls -la ~/.config/nushell/config.nu          # linked to dotfiles
```

## Key Findings

- **Auto-sourcing**: `.zshrc` already sources `~/.config/zsh/*.zsh` (line 117) — new file is zero-config.
- **Session naming**: `${${${dir##*/}#.}//./-}` = basename, strip leading dot, replace remaining dots with hyphens.
- **`new -A` vs `new-session -d`**: Since we build windows programmatically, use `new-session -d` + `has-session` check + `attach-session`.
- **Split ratio**: Splitting the last created pane gives 50%/25%/12.5%/... naturally (tmux `split-window` splits 50/50).
- **Split direction**: Same as `auto-split.sh` — horizontal if width > 2× height, else vertical.
- **No auto-launch**: Both "only tmux" and "both → t" go through preset picker.

## Potential Issues

1. **`$(pwd)` in default preset** evaluated at source time, not picker time. If user `cd`s between terminal open and picker running, dir is wrong. Current flow runs picker immediately so it's fine. Use `$PWD` (variable, not subshell) as safety.

2. **Nushell `$env.PWD`** behaves the same as zsh `$PWD` — correct.

3. **Session name collision**: `has-session` check means re-selecting a preset switches to existing session. This matches `new -A` behavior. Future multi-session presets need name dedup.

4. **Separator chars** `;` and `,` could conflict with unusual directory names. Not an issue for current presets.

5. **Default preset empty windows**: Falls back to `exec tmux attach-session` of a single-pane session.

## Verification

1. Open terminal outside tmux — picker shows (no auto-launch).
2. Press `t` — preset picker lists `d. dotfiles` and shows "Enter: default".
3. Enter (default) — session named after `$PWD`, single shell pane.
4. Press `d` — session named `dotfiles` at `~/.dotfiles`, 3 windows (opencode, nvim, zsh).
5. Open another terminal, press `t` then `d` — switches to existing `dotfiles` session (no duplicate).
6. Repeat from `nu` — same behavior.
7. Invalid key → falls to default.
8. `D` (uppercase) → same as `d`.
