#!/usr/bin/env bash
set -uo pipefail

: "${DEBUG:=0}"
log_file="${XDG_STATE_HOME:-$HOME/.local/state}/tmux/move-to-session.log"

debug_log() {
    [[ "$DEBUG" -ne 1 ]] && return 0
    mkdir -p "$(dirname "$log_file")"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$log_file"
}

debug_log "=== START ==="

pane_id="${1:-}"
cwd="${2:-}"
current_session="${3:-}"

if [[ -z "$cwd" ]]; then
    cwd=$(tmux display-message -p '#{pane_current_path}')
    debug_log "cwd from tmux: $cwd"
    pane_id=$(tmux display-message -p '#{pane_id}')
    debug_log "pane_id from tmux: $pane_id"
    current_session=$(tmux display-message -p '#{session_name}')
    debug_log "current_session from tmux: $current_session"
fi

default_session=$(basename "$cwd")
default_session="${default_session#.}"
default_session="${default_session//[^a-zA-Z0-9_-]/-}"
[[ -z "$default_session" ]] && default_session="shell"
debug_log "default_session: $default_session"

win_fmt_act='-F "#{window_active} #{window_index}"'
win_fmt_list='#{?window_bell_flag,󰅸,} #{window_name}'\
'#{?#{>:#{window_panes},1}, (#{window_panes} panes),}'

preview_cmd='s=$(echo {} | awk "{print \$2}" | cut -d: -f1); '\
'i=$(tmux list-windows -t "$s" '"$win_fmt_act"' '\
'  2>/dev/null | sort -k1 -rn | head -1 | cut -d" " -f2); '\
'tmux capture-pane -p -t "$s:$i" -e -J 2>/dev/null'

debug_log "Sessions listed, launching fzf-tmux..."
result=$(
  tmux list-sessions -F "#{session_name}" \
  | while read -r s; do
      windows=$(tmux list-windows -t "$s" \
        -F "$win_fmt_list" \
        2>/dev/null | paste -sd '|' | sed 's/|/ | /g')
      if tmux list-windows -t "$s" -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
        icon="󰅸"
      else
        icon=""
      fi
      echo "$icon $s: $windows"
    done \
  | fzf-tmux -p 60%,60% --reverse --print-query \
      --query="$default_session" \
      --wrap-sign='' --ellipsis='··' --preview-wrap-sign='' \
      --preview "$preview_cmd" \
      --preview-window='down:60%,nowrap' \
      --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
      --prompt="Move to session: "
)
fzf_exit=$?
debug_log "fzf-tmux exited with: $fzf_exit"
[[ -z "$result" ]] && { debug_log "User cancelled (empty result)"; exit 0; }

line_count=$(echo "$result" | wc -l)
debug_log "result line_count: $line_count"
if [[ "$line_count" -gt 1 ]]; then
    target_session=$(echo "$result" | tail -1 | awk '{print $2}' | cut -d: -f1)
else
    target_session="$result"
fi
debug_log "target_session parsed: $target_session"
target_session="${target_session/#\~/$HOME}"
debug_log "target_session after tilde expansion: $target_session"
debug_log "current_session: $current_session"

if tmux has-session -t "$target_session" 2>/dev/null; then
    debug_log "Session exists: $target_session"
    [[ "$current_session" == "$target_session" ]] && { debug_log "Already in target session, aborting"; tmux display-message "Already in session \"$target_session\""; exit 0; }

    new_win=$(tmux new-window -P -F '#{window_index}' -t "$target_session" -c "$cwd")
    debug_log "new_win created: $new_win in session $target_session"
    tmux join-pane -s "$pane_id" -t "${target_session}:${new_win}"
    tmux kill-pane -t "${target_session}:${new_win}.1"
    tmux switch-client -t "$target_session"
    debug_log "Moved pane to existing session $target_session"
else
    debug_log "Session does not exist, trying zoxide"
    dir=$(zoxide query "$target_session" 2>&1) || {
        debug_log "zoxide query failed: $dir"
        tmux display-message "zoxide: $(echo "$dir" | head -1)"
        exit 0
    }
    debug_log "zoxide returned: $dir"
    if [[ -n "$dir" ]]; then
        name=$(basename "$dir")
    elif [[ -d "$target_session" ]]; then
        dir="$target_session"
        name=$(basename "$dir")
    else
        tmux display-message "No match for '$target_session'"
        exit 0
    fi
    name="${name#.}"
    name="${name//[^a-zA-Z0-9_-]/-}"
    [[ -z "$name" ]] && name="shell"
    debug_log "new session name: $name"

    session_created=false
    if ! tmux has-session -t "$name" 2>/dev/null; then
        debug_log "Creating new session: $name"
        tmux new-session -d -s "$name" -c "$dir"
        session_created=true
    fi

    new_win=$(tmux new-window -P -F '#{window_index}' -t "$name" -c "$dir")
    debug_log "new_win in new session: $new_win"
    tmux join-pane -s "$pane_id" -t "${name}:${new_win}"
    tmux kill-pane -t "${name}:${new_win}.1"

    if [[ "$session_created" == "true" ]]; then
        debug_log "Cleaning up default window in new session"
        tmux kill-window -t "${name}:1"
    fi

    tmux switch-client -t "$name"
    debug_log "Moved pane to new session $name"
fi

# Clean up source session if now empty
if ! tmux has-session -t "$current_session" 2>/dev/null; then
    :  # session already gone from pane move
elif tmux list-windows -t "$current_session" 2>/dev/null; then
    :  # session still has windows, keep it
else
    debug_log "Killing empty source session: $current_session"
    tmux kill-session -t "$current_session"
fi

debug_log "=== END ==="
tmux send -X cancel 2>/dev/null || true
