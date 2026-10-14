#!/usr/bin/env bash
set -euo pipefail

CACHE="/tmp/starship-battery-cache"
LOCK="/tmp/starship-battery.flock"
TTL=60

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

fetch_async() {
  (
    flock -xn 200 2>/dev/null || exit 0

    local bat raw_status result

    result=$(read_battery_local 2>/dev/null) || result=""
    if [[ -n "$result" ]]; then
      bat="${result%% *}"
      raw_status="${result##* }"
      printf 'bat=%s\nraw_status=%s\nts=%s\n' "$bat" "$raw_status" "$(date +%s)" > "$CACHE"
    else
      rm -f "$CACHE"
    fi
  ) 200>"$LOCK" >/dev/null 2>&1 & disown
}

main() {
  mkdir -p /tmp

  local now ts bat raw_status
  now=$(date +%s)

  if [[ -f "$CACHE" ]]; then
    . "$CACHE"
    bat="${bat:-}"
    if [[ -n "$bat" ]]; then
      if [[ $(( now - ${ts:-0} )) -lt "$TTL" ]]; then
        printf '%s %s' "$bat" "${raw_status:-}"
        return 0
      fi
      fetch_async
      printf '%s %s' "$bat" "${raw_status:-}"
      return 0
    fi
  fi

  fetch_async
  return 1
}

main "$@"
