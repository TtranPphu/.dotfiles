#!/usr/bin/env bash
# Hostname segment: gate + live render; ssh-quality-util.sh keeps its own 15s
# RTT cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/icon.sh"
  local size=${1:-$(layout_size_fast)}
  local data level ramp icon_signal icon_host text fg_quality

  [[ "$size" == narrow ]] && exit 1

  data=$("$script_dir/hostname-util.sh") || exit 1
  [[ -z "$data" ]] && exit 1

  icon_host="$(nerd_font_icon host)"

  # Over SSH color the host with the connection quality ramp (10 = green, 1 = red);
  # medium drops the name. Without SSH the module only shows in wide.
  if level=$("$script_dir/ssh-quality-util.sh" level 2>/dev/null); then
    ramp=$((level * 10))
    icon_signal=$("$script_dir/ssh-quality-util.sh" signal 2>/dev/null)
    fg_quality=$(level_color "$ramp")
    reset=$'\033[0m'
    if [[ "$size" == wide ]]; then
      text="$icon_signal$icon_host$data"
      printf '%s%s%s' "$fg_quality" "$text" "$reset"
    else
      text="${icon_signal% }"
      printf '%s%s%s' "$fg_quality" "$text" "$reset"
    fi
  else
    [[ "$size" == wide ]] || exit 1
    text="$icon_host$data"
    printf '%s%s' "$text"
  fi
}

case "${1:-}" in
  --display | "")
    render "$(layout_size_fast)"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ -n "${SSH_CONNECTION:-}" ] || [ -f /.dockerenv ] || exit 1
    size=$(layout_size_fast)
    [ "$size" = narrow ] && exit 1
    # Without SSH there is no quality ramp to color with, and the render then
    # needs a wide terminal: gate that here so a hidden module contributes
    # nothing to the prompt.
    [ -n "${SSH_CONNECTION:-}" ] || [ "$size" = wide ] || exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
