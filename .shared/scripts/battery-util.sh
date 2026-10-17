#!/usr/bin/env bash
# Battery probe + fetch cache (TTL 30s).
#
#   battery-util.sh             -> cached "percent status"; exits 1 when unknown
#   battery-util.sh --refresh F -> run the probe and store it (detached refresher)
#
# The read path is a cache read; the upower/PowerShell probe runs in the
# detached refresher when the entry is missing or stale.
set -euo pipefail

# Resolve this script through symlinks (stow links it into consumers) so the
# shared fetch-cache engine next to the real file is found.
script_dir="${BASH_SOURCE[0]:-}"
script_dir="$(readlink -f -- "$script_dir" 2>/dev/null || true)"
script_dir="${script_dir%/*}"
[ -n "$script_dir" ] || script_dir=.
[ -f "$script_dir/fetch-cache.sh" ] && source "$script_dir/fetch-cache.sh"

read_battery_local() {
  local bat raw_status bat_path

  bat_path=$(timeout 0.5 upower -e 2>/dev/null | grep -i bat | head -1)
  if [[ -n "$bat_path" ]]; then
    read -r bat raw_status < <(
      timeout 0.5 upower -i "$bat_path" 2>/dev/null | awk '
        /percentage:/ { gsub(/%/,""); cap = sprintf("%.0f", $2) }
        /state:/      { st = $2 }
        END           { print cap, st }
      '
    )
  fi

  if [[ -z "${bat:-}" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    read -r bat raw_status < <(
      timeout 0.5 powershell.exe -NoProfile -Command '
        $b = Get-WmiObject Win32_Battery
        if ($b) { Write-Host "$($b.EstimatedChargeRemaining) $($b.BatteryStatus)" }
      ' 2>/dev/null | tr -d '\r'
    )
    case "${raw_status:-}" in
      1) raw_status="discharging" ;;
      2|6|7|8|9|11) raw_status="charging" ;;
      3) raw_status="fully-charged" ;;
      *) raw_status="" ;;
    esac
  fi

  [[ -n "${bat:-}" ]] || return 1
  printf '%s %s' "$bat" "${raw_status:-}"
}

case "${1:-}" in
  --refresh) fetch_refresh "${2:?}" read_battery_local ;;
  *) fetch_display battery 30 ;;
esac
