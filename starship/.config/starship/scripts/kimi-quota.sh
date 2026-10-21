#!/bin/bash
# Starship custom module: Kimi account balance (wide terminals).
# llm-quota-util.sh owns the fetch cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/icon.sh"
  local balance icon_kimi icon_usd text

  balance=$("$script_dir/llm-quota-util.sh" --get kimi) || exit 1
  awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  icon_kimi="$(nerd_font_icon kimi)"
  icon_usd="$(nerd_font_icon usd)"
  text="$icon_kimi$icon_usd"
  printf "%s%.2f" "$text" "$balance"
}

case "${1:-}" in
  --display | "")
    render
    ;;
  --guard)
    [ -n "${TMUX:-}${ZELLIJ:-}" ] && exit 1
    [ "$(layout_size_fast)" = wide ] || exit 1
    # Presence gate: a hidden module must contribute nothing, so the balance is
    # checked here too — a command that fails would still render the format's
    # literal space.
    balance=$("$script_dir/llm-quota-util.sh" --get kimi) || exit 1
    awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
