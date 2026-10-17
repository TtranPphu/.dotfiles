#!/bin/bash
# Starship custom module: OpenCode Go quota usage.
# opencode-quota-util.sh owns the fetch cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local size=${1:-$(layout_size_fast)}
  local values rolling monthly pct icon

  [ "$size" = narrow ] && exit 1

  values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
  read -r rolling _ monthly <<<"$values"

  pct="$(nerd_font_icon percent)"
  icon="$(nerd_font_icon opencode)"

  # Rolling quota drives the foreground: low usage green, near limit red.
  printf '%s%s%s%s\033[0m' "$(level_color "$rolling")" "$icon" "$monthly" "$pct"
}

case "${1:-}" in
  --display | "")
    render "$(layout_size_fast)"
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = wide ] || exit 1
    # Presence gate: a hidden module must contribute nothing, so the values are
    # checked here too — a command that fails would still render the format's
    # literal space.
    "$script_dir/opencode-quota-util.sh" --values >/dev/null || exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
