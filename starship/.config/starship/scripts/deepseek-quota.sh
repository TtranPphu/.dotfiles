#!/bin/bash
# Starship custom module: DeepSeek account balance (wide terminals).
# llm-quota-util.sh owns the fetch cache.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."
source "$script_dir/layout.sh"

render() {
  source "$script_dir/nerd-font.sh"
  local balance

  "$script_dir/llm-quota-util.sh" --configured deepseek || exit 1
  balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
  awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
  printf "%s%s%.2f" "$(nerd_font_icon deepseek)" "$(nerd_font_icon usd)" "$balance"
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
    "$script_dir/llm-quota-util.sh" --configured deepseek || exit 1
    balance=$("$script_dir/llm-quota-util.sh" --get deepseek) || exit 1
    awk -v v="${balance:-0}" 'BEGIN { exit !(v > 0) }' || exit 1
    exit 0
    ;;
  *) exit 2 ;;
esac
