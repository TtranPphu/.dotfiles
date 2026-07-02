#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/tmp/keyboard-battery.lock"
CACHEFILE="/tmp/keyboard-battery.json"
CACHE_TTL=5
DBUS_TIMEOUT=2

DBUS_CONN="org.bluez"
DBUS_PATH="/org/bluez/hci0"
BATTERY_SVC_UUID="0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID="00002a19-0000-1000-8000-00805f9b34fb"
BATTERY_USER_DESC="00002901-0000-1000-8000-00805f9b34fb"

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
WSL_PS1="$SCRIPT_DIR/keyboard-battery-wsl.ps1"

usage() { exit 1; }
err_exit() { exit 1; }

gdbus_prop() {
  local path="$1" iface="$2" prop="$3"
  local out
  out=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$path" \
    --method org.freedesktop.DBus.Properties.Get \
    "$iface" "$prop" 2>/dev/null) || return 1
  out="${out#*<}"
  out="${out%%>*}"
  out="${out#\'}"
  out="${out%\'}"
  printf '%s' "$out"
}

gdbus_read_value() {
  local path="$1" val
  val=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$path" \
    --method org.bluez.GattCharacteristic1.ReadValue {} 2>/dev/null |
    grep -o '0x[0-9a-f][0-9a-f]' | head -1 | sed 's/0x//') || true
  [[ -z "$val" ]] && return 1
  printf '%s' "$val"
}

gdbus_desc_value() {
  local path="$1" out hex
  out=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$path" \
    --method org.bluez.GattDescriptor1.ReadValue {} 2>/dev/null) || return 1
  for hex in $(printf '%s' "$out" | grep -o '0x[0-9a-f][0-9a-f]'); do
    printf "\\x$hex"
  done
}

read_batteries_wsl() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v powershell.exe &>/dev/null || return 1
  grep -qi microsoft /proc/version 2>/dev/null || return 1

  if ! mkdir "/tmp/keyboard-battery-wsl.lock" 2>/dev/null; then
    return 1
  fi

  (
    tmp=$(mktemp "$CACHEFILE.XXXXXX")
    result=$(timeout 10 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WSL_PS1" 2>/dev/null | tr -d '\r')
    if [[ -n "$result" ]]; then
      left="${result%% *}"
      right="${result##* }"
      if [[ -n "$left" ]]; then
        printf '%s %s %s\n' "$left" "${right:-0}" "$(date +%s)" > "$tmp"
        mv "$tmp" "$CACHEFILE"
      fi
    fi
    rm -f "$tmp"
    rmdir "/tmp/keyboard-battery-wsl.lock" 2>/dev/null
  ) & disown

  return 1
}

read_batteries_gdbus() {
  local dev_path="" left="" right=""
  local devices svc_uuid char_uuid desc_uuid
  local raw_val hex_val

  while read -r dev; do
    local name con
    name=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Alias) || continue
    con=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Connected) || continue
    if [[ "$con" != "true" ]]; then continue; fi
    if [[ "$name" != *Cornix* ]]; then continue; fi
    dev_path="$DBUS_PATH/$dev"
    break
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$DBUS_PATH" 2>/dev/null |
    grep -o 'dev_[A-Z0-9_]*')

  [[ -z "$dev_path" ]] && return 1

  while read -r svc; do
    svc_uuid=$(gdbus_prop "$dev_path/$svc" org.bluez.GattService1 UUID) || continue
    [[ "$svc_uuid" != "$BATTERY_SVC_UUID" ]] && continue

    while read -r chr; do
      char_uuid=$(gdbus_prop "$dev_path/$svc/$chr" org.bluez.GattCharacteristic1 UUID) || continue
      [[ "$char_uuid" != "$BATTERY_LEVEL_UUID" ]] && continue

      raw_val=$(gdbus_read_value "$dev_path/$svc/$chr") || continue
      [[ -z "$raw_val" ]] && continue
      hex_val=$((16#$raw_val))
      [[ "$hex_val" -gt 100 ]] && continue

      local is_aux=""
      while read -r desc; do
        desc_uuid=$(gdbus_prop "$dev_path/$svc/$chr/$desc" org.bluez.GattDescriptor1 UUID) || continue
        if [[ "$desc_uuid" == "$BATTERY_USER_DESC" ]]; then
          local desc_str
          desc_str=$(gdbus_desc_value "$dev_path/$svc/$chr/$desc") || true
          if [[ "$desc_str" == "auxiliary" ]]; then
            is_aux=1
          fi
        fi
      done < <(gdbus introspect --system --only-properties \
        --dest "$DBUS_CONN" --object-path "$dev_path/$svc/$chr" 2>/dev/null |
        grep -o 'desc[0-9a-f][0-9a-f]*')

      if [[ -n "$is_aux" ]]; then
        right="$hex_val"
      elif [[ -z "$left" ]]; then
        left="$hex_val"
      elif [[ -z "$right" ]]; then
        right="$hex_val"
      fi
    done < <(gdbus introspect --system --only-properties \
      --dest "$DBUS_CONN" --object-path "$dev_path/$svc" 2>/dev/null |
      grep -o 'char[0-9a-f][0-9a-f]*')
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$dev_path" 2>/dev/null |
    grep -o 'service[0-9a-f][0-9a-f]*')

  if [[ -n "$left" ]]; then
    printf '%s %s' "${left:-0}" "${right:-0}"
    return 0
  fi
  return 1
}

read_batteries_wsl_sync() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v powershell.exe &>/dev/null || return 1
  grep -qi microsoft /proc/version 2>/dev/null || return 1

  local result left right
  result=$(timeout 10 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WSL_PS1" 2>/dev/null | tr -d '\r') || return 1
  left="${result%% *}"
  right="${result##* }"
  [[ -z "$left" ]] && return 1
  printf '%s %s' "$left" "${right:-0}"
  return 0
}

read_batteries() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if [[ -z "${TMUX-}" ]]; then
      read_batteries_wsl && return 0
    else
      read_batteries_wsl_sync && return 0
    fi
    return 1
  fi
  if command -v gdbus &>/dev/null; then
    read_batteries_gdbus && return 0
  fi
  return 1
}

main() {
  mkdir -p /tmp

  {
    flock -x 200 2>/dev/null || return 1

    local now ts left right
    now=$(date +%s)

    if [[ -f "$CACHEFILE" ]]; then
      read -r left right ts < "$CACHEFILE" 2>/dev/null || true
      if [[ -n "$ts" ]] && [[ $(( now - ts )) -lt "$CACHE_TTL" ]] && [[ -n "$left" ]]; then
        printf '%s %s\n' "$left" "${right:-0}"
        return 0
      fi
    fi

    local result
    result=$(read_batteries 2>/dev/null) || return 1
    left="${result%% *}"
    right="${result##* }"
    printf '%s %s\n' "$left" "${right:-0}"
    printf '%s %s %s\n' "$left" "${right:-0}" "$now" > "$CACHEFILE"

  } 200>"$LOCKFILE"
}

main "$@"
