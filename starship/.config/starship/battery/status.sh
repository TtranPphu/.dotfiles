#!/usr/bin/bash

cache="/tmp/starship-battery-cache"

if [ -f "$cache" ]; then
  . "$cache"
  if [ $(( $(date +%s) - ts )) -ge 2 ]; then
    unset bat raw_status ts
  fi
fi

if [ -z "$bat" ]; then
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if mkdir "/tmp/starship-battery-wsl.lock" 2>/dev/null; then
      (
        result=$(timeout 3 powershell.exe -NoProfile -Command '
          $b = Get-WmiObject Win32_Battery
          if ($b) { Write-Host "$($b.EstimatedChargeRemaining) $($b.BatteryStatus)" }
        ' 2>/dev/null | tr -d '\r')
        new_bat="${result%% *}"
        new_raw="${result##* }"
        case "$new_raw" in
          1) new_raw="discharging" ;;
          2|6|7|8|9|11) new_raw="charging" ;;
          3) new_raw="fully-charged" ;;
          *) new_raw="" ;;
        esac
        [ -n "$new_bat" ] && printf 'bat=%s\nraw_status=%s\nts=%s\n' "$new_bat" "$new_raw" "$(date +%s)" > "$cache"
        rmdir "/tmp/starship-battery-wsl.lock" 2>/dev/null
      ) & disown
    fi
    exit 1
  fi

  bat_path=$(timeout 0.5 upower -e 2>/dev/null | grep -i bat | head -1)
  if [ -n "$bat_path" ]; then
    read -r bat raw_status < <(
      timeout 0.5 upower -i "$bat_path" 2>/dev/null | awk '
        /percentage:/ { gsub(/%/,""); cap = sprintf("%.0f", $2) }
        /state:/      { st = $2 }
        END           { print cap, st }
      '
    )
  fi

  if [ -z "$bat" ] && grep -qi microsoft /proc/version 2>/dev/null; then
    read -r bat raw_status < <(
      timeout 0.5 powershell.exe -NoProfile -Command '
        $b = Get-WmiObject Win32_Battery
        if ($b) { Write-Host "$($b.EstimatedChargeRemaining) $($b.BatteryStatus)" }
      ' 2>/dev/null | tr -d '\r'
    )
    case "$raw_status" in
      1) raw_status="discharging" ;;
      2|6|7|8|9|11) raw_status="charging" ;;
      3) raw_status="fully-charged" ;;
      *) raw_status="" ;;
    esac
  fi

  [ -n "$bat" ] && printf 'bat=%s\nraw_status=%s\nts=%s\n' "$bat" "$raw_status" "$(date +%s)" > "$cache"
fi

[ -z "$bat" ] && exit 1

charging=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
discharging=("󱃍" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

idx=$(( (bat - 1) / 10 ))

if [ "$raw_status" = "fully-charged" ]; then
  icon="󰂄"
elif [ "$raw_status" = "charging" ] || [ "$raw_status" = "pending-charge" ]; then
  icon="${charging[$idx]}"
else
  icon="${discharging[$idx]}"
fi

printf '%s %s\n' "$icon" "$bat"
