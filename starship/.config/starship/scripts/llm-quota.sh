#!/bin/bash
# Starship custom module: combined LLM quota (medium terminals) — opencode
# monthly quota plus the combined dollar balance, colored by opencode's rolling
# bucket. Shown at medium only; wide shows the separate opencode/deepseek/kimi
# pills instead.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/level-color.sh"
  source "$script_dir/nerd-font.sh"
  local values rolling monthly total

  values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
  read -r rolling _ monthly <<<"$values"
  total=$("$script_dir/llm-quota-util.sh" --total) || exit 1
  awk -v v="${total:-0}" 'BEGIN { exit !(v > 0) }' || exit 1

  # Rolling quota drives the color: low usage green, near limit red.
  printf '%s%s%s%s + %s%s\033[0m' \
    "$(level_color "$rolling")" \
    "$(nerd_font_icon opencode)" "$monthly" "$(nerd_font_icon percent)" \
    "$(nerd_font_icon usd)" "$total"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = medium ] || exit 1
    # Presence gate: a hidden module must contribute nothing, so both values
    # are checked here too — a command that fails would still render the
    # format's literal space.
    "$script_dir/opencode-quota-util.sh" --values >/dev/null || exit 1
    total=$("$script_dir/llm-quota-util.sh" --total) || exit 1
    awk -v v="${total:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
