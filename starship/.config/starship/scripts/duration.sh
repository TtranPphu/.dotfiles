#!/usr/bin/env bash
# Duration segment: formats DOTFILES_CMD_DURATION_MS (set by the zsh precmd
# hook) with spaced units and the catalog's duration icon.
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
[ "$script_dir" = "${BASH_SOURCE[0]}" ] && script_dir="."

# Guard: a non-negative integer of at least one second, like the built-in
# cmd_duration's min_time = 1000.
valid_ms() {
  local ms=${DOTFILES_CMD_DURATION_MS:-}
  [[ $ms =~ ^[0-9]+$ ]] || return 1
  ((10#$ms >= 1000))
}

render() {
  source "$script_dir/icon.sh"
  local total=$((10#${DOTFILES_CMD_DURATION_MS:-0} / 1000))
  local h=$((total / 3600)) m=$(((total % 3600) / 60)) s=$((total % 60))
  local out="" icon_duration
  ((h)) && out+="${h}h"
  ((m)) && out+="${out:+ }${m}m"
  ((s)) && out+="${out:+ }${s}s"
  icon_duration="$(nerd_font_icon duration)"
  icon_duration="${icon_duration% }"
  [[ -n "$icon_duration" ]] && out="$icon_duration $out"
  printf '%s' "$out"
}

case "${1:-}" in
  --guard) valid_ms ;;
  --display | "")
    valid_ms || exit 1
    render
    ;;
  *) exit 1 ;;
esac
