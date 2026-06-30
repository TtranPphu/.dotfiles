# session_presets[key]="display_name|dir|window1_apps;window2_apps;..."
#   - key: single char for picker (_ = default fallback, hidden from picker)
#   - display_name: shown in picker menu
#   - dir: working directory for all windows
#   - windows: separated by `;`, each window's apps separated by `,`
#   - empty windows = default behavior (single shell pane, no exec)

typeset -A session_presets
session_presets[_]="default|$(pwd)|"
session_presets[d]="{d}otfiles|${HOME}/.dotfiles|opencode;nvim;"
session_presets[t]="{t}iny-repository|${HOME}/Projects/tiny-repository|opencode;nvim;"
session_presets[n]="ti{n}y-repository|${HOME}/projects/tiny-repository|opencode;nvim;"
session_presets[k]="zmk-{k}eyboard-cornix|${HOME}/Projects/zmk-keyboard-cornix|opencode;nvim;"

create_from_preset() {
  local preset_key="$1"
  local def="${session_presets[$preset_key]}"
  [[ -z "$def" ]] && def="${session_presets[_]}"
  [[ -z "$def" ]] && return 1

  local IFS='|'
  local -a fields=("${(@s:|:)def}")
  local name="${fields[1]}"
  local dir="${fields[2]}"
  local windows_str="${fields[3]:-}"

  local session_name="${${${dir##*/}#.}//./-}"
  [[ -z "$session_name" ]] && session_name="shell"

  local known_shells=' zsh bash sh nu fish dash ksh tcsh '
  local current_shell="zsh"
  local current
  current=$(tmux display-message -p '#{pane_current_command}' 2>/dev/null)
  if [[ "$known_shells" == *" $current "* ]]; then
    current_shell="$current"
  else
    local start
    start=$(tmux display-message -p '#{pane_start_command}' 2>/dev/null)
    current_shell="${start:-zsh}"
  fi

  if tmux has-session -t "$session_name" 2>/dev/null; then
    clear; exec tmux attach-session -t "$session_name"
  fi

  local -a windows
  IFS=';' read -rA windows <<< "$windows_str"

  if [[ ${#windows} -eq 0 || -z "${windows[1]}" ]]; then
    tmux new-session -d -s "$session_name" -c "$dir" "$current_shell"
    clear; exec tmux attach-session -t "$session_name"
  fi

  local first_win="${windows[1]}"
  local -a first_apps=("${(@s:,:)first_win}")

  local branch
  branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
  local win1_name="${first_apps[1]}${branch:+ 󰊢 ${branch}}"

  tmux new-session -d -s "$session_name" -c "$dir" -n "$win1_name" "$current_shell"
  tmux send-keys -t "${session_name}:1.1" "clear && ${first_apps[1]}" Enter

  local pane="1"
  local -i total_apps=${#first_apps}
  for (( i = 2; i <= total_apps; i++ )); do
    local app="${first_apps[$i]}"
    local pane_width pane_height
    pane_width=$(tmux display-message -p -t "${session_name}:1.${pane}" '#{pane_width}')
    pane_height=$(tmux display-message -p -t "${session_name}:1.${pane}" '#{pane_height}')
    if (( pane_width > pane_height * 2 )); then
      pane=$(tmux split-window -h -t "${session_name}:1.${pane}" -c "$dir" -P -F '#{pane_index}' "$current_shell")
    else
      pane=$(tmux split-window -v -t "${session_name}:1.${pane}" -c "$dir" -P -F '#{pane_index}' "$current_shell")
    fi
    tmux send-keys -t "${session_name}:1.${pane}" "clear && $app" Enter
  done

  local -i win_idx=2
  for win_def in "${windows[@]:1}"; do
    if [[ -z "$win_def" ]]; then
      tmux new-window -t "$session_name" -c "$dir" "$current_shell"
    else
      local -a apps=("${(@s:,:)win_def}")
      local win_name="${apps[1]}${branch:+ 󰊢 ${branch}}"
      tmux new-window -t "$session_name" -c "$dir" -n "$win_name" "$current_shell"
      tmux send-keys -t "${session_name}:${win_idx}.1" "clear && ${apps[1]}" Enter
      local pane="1"
      local -i napps=${#apps}
      for (( i = 2; i <= napps; i++ )); do
        local app="${apps[$i]}"
        local pane_width pane_height
        pane_width=$(tmux display-message -p -t "${session_name}:${win_idx}.${pane}" '#{pane_width}')
        pane_height=$(tmux display-message -p -t "${session_name}:${win_idx}.${pane}" '#{pane_height}')
        if (( pane_width > pane_height * 2 )); then
          pane=$(tmux split-window -h -t "${session_name}:${win_idx}.${pane}" -c "$dir" -P -F '#{pane_index}' "$current_shell")
        else
          pane=$(tmux split-window -v -t "${session_name}:${win_idx}.${pane}" -c "$dir" -P -F '#{pane_index}' "$current_shell")
        fi
        tmux send-keys -t "${session_name}:${win_idx}.${pane}" "clear && $app" Enter
      done
    fi
    ((win_idx++))
  done

  tmux select-window -t "${session_name}:1"
  clear; exec tmux attach-session -t "$session_name"
}

tmux_session_picker() {
  clear

  local GREEN=$'\033[1;32m' ACTIVE=$'\033[1;34m' NC=$'\033[0m'

  local known_shells=' zsh bash sh nu fish dash ksh tcsh '
  local shell_name="zsh"
  local current
  current=$(tmux display-message -p '#{pane_current_command}' 2>/dev/null)
  if [[ "$known_shells" == *" $current "* ]]; then
    shell_name="$current"
  else
    local start
    start=$(tmux display-message -p '#{pane_start_command}' 2>/dev/null)
    shell_name="${start:-zsh}"
  fi

  echo "Session presets:"

  local max_len=0
  local -a pdata=()
  local -a pdisplay=()
  local -a pplain=()
  local -a picons=()
  for key val in "${(@kv)session_presets}"; do
    local -a fields=("${(@s:|:)val}")
    [[ "$key" == "_" ]] && continue
    local dir="${fields[2]}"
    [[ -z "$dir" || ! -d "$dir" ]] && continue
    local raw_name="${fields[1]}"
    local windows_str="${fields[3]:-}"

    if [[ "$raw_name" =~ '\{'([a-zA-Z0-9])'\}' ]]; then
      local char="$match[1]"
      local before="${raw_name%%\{$char\}*}"
      local after="${raw_name##*\{$char\}}"
      local display="${before}${GREEN}${char}${NC}${after}"
      local plain="${before}${char}${after}"
    else
      local plain="$raw_name"
      local display="$raw_name"
    fi

    local wicons=""
    if [[ -n "$windows_str" ]]; then
      local -a wins
      IFS=';' read -rA wins <<< "$windows_str"
      local       first_win=true
for w in "${wins[@]}"; do
  if [[ -z "$w" ]]; then
    if $first_win; then
      wicons+="${ACTIVE}  ${shell_name} ${NC}"
    else
      wicons+="  ${shell_name} "
    fi
  else
    if $first_win; then
      wicons+="${ACTIVE}  ${w%%,*} ${NC}"
    else
      wicons+="  ${w%%,*} "
    fi
  fi
  first_win=false
done
    fi

    pdata+=("$val")
    pdisplay+=("$display")
    pplain+=("$plain")
    picons+=("$wicons")
    (( ${#plain} > max_len )) && max_len=${#plain}
  done

  local idx=1
  for val in "${pdata[@]}"; do
    local -a fields=("${(@s:|:)val}")
    local display="${pdisplay[$idx]}"
    local plain="${pplain[$idx]}"
    local dir="${fields[2]}"
    local session_name="${${${dir##*/}#.}//./-}"
    local wicons="${picons[$idx]}"
    if tmux has-session -t "$session_name" 2>/dev/null; then
      local active=$(tmux display-message -p -t "$session_name" '#{window_id}' 2>/dev/null)
      local raw=$(tmux list-windows -t "$session_name" -F "#{window_id}|#{window_name}" 2>/dev/null)
      wicons=""
      while IFS= read -r line; do
        local wid="${line%%|*}"
        local wname="${line#*|}"
        if [[ "$wid" == "$active" ]]; then
          wicons+="${ACTIVE}  ${wname} ${NC}"
        else
          wicons+="  ${wname} "
        fi
      done <<< "$raw"
    fi
    local pad=$(( max_len - ${#plain} + 1 ))
    local padding=$(printf '%*s' $pad '')
    echo "   ${display}:${padding}${wicons}"
    ((idx++))
  done

  echo -n "Pick: "
  read -r -k1 choice
  echo

  local matched="${session_presets[${(L)choice}]}"
  if [[ -z "$matched" ]]; then
    create_from_preset "_"
  else
    create_from_preset "${(L)choice}"
  fi
}
