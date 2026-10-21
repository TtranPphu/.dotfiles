#!/usr/bin/env bash
set -euo pipefail

# Exit 0 only when wide enough for the standalone quota pill
if [[ "${1:-}" == --guard ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  source "$script_dir/layout.sh"
  [[ "$(layout_size_fast)" == wide ]] || exit 1
  "$script_dir/opencode-quota-util.sh" --values >/dev/null || exit 1
  exit 0
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/nerd-font.sh"
source "$script_dir/layout.sh"
source "$script_dir/level-color.sh"
values=$("$script_dir/opencode-quota-util.sh" --values) || exit 1
read -r rolling _ monthly <<<"$values"

size=$(layout_size_fast)
[[ "$size" == narrow ]] && exit 1

# Rolling quota drives the pill color: low usage green, near limit red. The
# colors and 10% buckets mirror battery.sh so the gradients line up.
[[ "${rolling:-}" =~ ^-?[0-9]+$ ]] || rolling=0

icon_percent="$(nerd_font_icon percent)"
icon_opencode="$(nerd_font_icon opencode)"
icon_head="$(nerd_font_icon separator.head)"
icon_flat="$(nerd_font_icon separator.flat)"
fg_ink="$(color_get ink)"
bg_rolling="$(level_hex "$rolling")"
style=$(printf '#[fg=%s,bold,bg=%s]' "$fg_ink" "$bg_rolling")
reset='#[default]'

out="$icon_head$icon_opencode$monthly$icon_percent$icon_flat"
printf '%s%s%s' "$style" "$out" "$reset"
