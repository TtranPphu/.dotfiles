# session_presets[key]="key|display_name|dir|window1_apps;window2_apps;..."
#   - key: single char for picker (empty = default fallback)
#   - display_name: shown in picker menu
#   - dir: working directory for all windows
#   - windows: separated by `;`, each window's apps separated by `,`
#   - empty windows = default behavior (single shell pane, no exec)

typeset -A session_presets
session_presets[default]="|default|$(pwd)|"
session_presets[d]="d|{d}otfiles|${HOME}/.dotfiles|opencode;nvim;"
session_presets[t]="t|{t}iny-repository|${HOME}/projects/tiny-repository|opencode;nvim;"

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

  local session_name="${${${dir##*/}#.}//./-}"
  [[ -z "$session_name" ]] && session_name="shell"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    clear; exec tmux attach-session -t "$session_name"
  fi

  local -a windows
  IFS=';' read -rA windows <<< "$windows_str"

  if [[ ${#windows} -eq 0 || -z "${windows[1]}" ]]; then
    tmux new-session -d -s "$session_name" -c "$dir"
    clear; exec tmux attach-session -t "$session_name"
  fi

  local first_win="${windows[1]}"
  local -a first_apps=("${(@s:,:)first_win}")

  tmux new-session -d -s "$session_name" -c "$dir" -n "${first_apps[1]}"
  tmux send-keys -t "${session_name}:1.1" "${first_apps[1]}" Enter

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
    tmux send-keys -t "${session_name}:1.${pane}" "$app" Enter
  done

  local -i win_idx=2
  for win_def in "${windows[@]:1}"; do
    if [[ -z "$win_def" ]]; then
      tmux new-window -t "$session_name" -c "$dir"
    else
      local -a apps=("${(@s:,:)win_def}")
      tmux new-window -t "$session_name" -c "$dir" -n "${apps[1]}"
      tmux send-keys -t "${session_name}:${win_idx}.1" "${apps[1]}" Enter
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
        tmux send-keys -t "${session_name}:${win_idx}.${pane}" "$app" Enter
      done
    fi
    ((win_idx++))
  done

  tmux select-window -t "${session_name}:1"
  clear; exec tmux attach-session -t "$session_name"
}

tmux_session_picker() {
  local GREEN=$'\033[1;32m' ACTIVE=$'\033[1;34m' NC=$'\033[0m'
  echo "Session presets:"

  local max_len=0
  local -a pdata=()
  local -a pdisplay=()
  local -a pplain=()
  local -a picons=()
  for key val in "${(@kv)session_presets}"; do
    local -a fields=("${(@s:|:)val}")
    [[ -z "${fields[1]}" ]] && continue
    local raw_name="${fields[2]}"
    local windows_str="${fields[4]:-}"

    if [[ "${raw_name:0:1}" == "{" && "${raw_name:2:1}" == "}" ]]; then
      local char="${raw_name:1:1}"
      local rest="${raw_name:3}"
      local display="${GREEN}${char}${NC}${rest}"
      local plain="${char}${rest}"
    else
      local plain="$raw_name"
      local display="$raw_name"
    fi

    local wicons=""
    if [[ -n "$windows_str" ]]; then
      local -a wins
      IFS=';' read -rA wins <<< "$windows_str"
      local first_win=true
for w in "${wins[@]}"; do
  if [[ -z "$w" ]]; then
    if $first_win; then
      wicons+="${ACTIVE}  \$shell ${NC}"
    else
      wicons+="  \$shell "
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
    local pad=$(( max_len - ${#plain} + 1 ))
    local padding=$(printf '%*s' $pad '')
    echo "   ${display}:${padding}${picons[$idx]}"
    ((idx++))
  done

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
