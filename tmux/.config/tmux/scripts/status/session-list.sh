#!/usr/bin/env bash

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/icon.sh"
source "$script_dir/color.sh"

socket_path="$1"
current_session="$2"
direction="$3"

mapfile -t sessions < <(tmux -S "$socket_path" list-sessions -F '#{session_name}')

current_index=-1
for index in "${!sessions[@]}"; do
  if [[ "${sessions[$index]}" == "$current_session" ]]; then
    current_index=$index
    break
  fi
done

if (( current_index < 0 )); then
  exit 0
fi

case "$direction" in
  prev)
    selected=("${sessions[@]:0:current_index}")
    ;;
  next)
    selected=()
    for ((i = ${#sessions[@]} - 1; i > current_index; i--)); do
      selected+=("${sessions[i]}")
    done
    ;;
  *)
    exit 1
    ;;
esac

if (( ${#selected[@]} > 0 )); then
  fg_green="$(color_get green)"
  icon_bell="$(nerd_font_icon bell)"
  icon_session="$(nerd_font_icon session)"
  icon_sep="$(nerd_font_icon separator.heavy)"
  style_bell=$(printf '#[fg=%s,bold]' "$fg_green")
  style_plain='#[bold]'

  first=1
  for session in "${selected[@]}"; do
    if (( first )); then
      first=0
    else
      printf '%s' "$icon_sep"
    fi
    if tmux -S "$socket_path" list-windows -t "$session" \
      -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
      text="$icon_bell$session"
      printf ' %s%s ' "$style_bell" "$text"
    else
      text="$icon_session$session"
      printf ' %s%s ' "$style_plain" "$text"
    fi
  done
fi
