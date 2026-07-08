#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/tmp/headphone-battery.lock"
CACHEFILE="/tmp/headphone-battery.json"
CACHE_TTL=5
DBUS_TIMEOUT=2

DBUS_CONN="org.bluez"
DBUS_PATH="/org/bluez/hci0"
BATTERY_SVC_UUID="0000180f-0000-1000-8000-00805f9b34fb"
BATTERY_LEVEL_UUID="00002a19-0000-1000-8000-00805f9b34fb"
BATTERY_USER_DESC="00002901-0000-1000-8000-00805f9b34fb"

# Device name pattern for gdbus matching (Linux path).
# Override via HEADPHONE_DEVICE env var for your headphone model.
DEVICE_PATTERN="${HEADPHONE_DEVICE:-*OPPO Enco*}"

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
WSL_PS1="$SCRIPT_DIR/headphone-battery-wsl.ps1"

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

read_batteries_gdbus() {
  local dev_path=""
  local svc_uuid char_uuid
  local raw_val hex_val

  while read -r dev; do
    local name con
    name=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Alias) || continue
    con=$(gdbus_prop "$DBUS_PATH/$dev" org.bluez.Device1 Connected) || continue
    if [[ "$con" != "true" ]]; then continue; fi
    if [[ "$name" != $DEVICE_PATTERN ]]; then continue; fi
    dev_path="$DBUS_PATH/$dev"
    break
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$DBUS_PATH" 2>/dev/null |
    grep -o 'dev_[A-Z0-9_]*')

  [[ -z "$dev_path" ]] && return 1

  # Try newer BlueZ Battery1 interface first (no GATT traversal needed).
  # gdbus_prop doesn't handle D-Bus byte types (<byte 0xNN>), so parse directly.
  local battery_raw battery_hex
  battery_raw=$(timeout "$DBUS_TIMEOUT" gdbus call --system \
    --dest "$DBUS_CONN" \
    --object-path "$dev_path" \
    --method org.freedesktop.DBus.Properties.Get \
    org.bluez.Battery1 Percentage 2>/dev/null) || battery_raw=""
  battery_hex=$(printf '%s' "$battery_raw" | grep -o '0x[0-9a-f][0-9a-f]' | head -1) || battery_hex=""
  if [[ -n "$battery_hex" ]]; then
    battery_val=$((16#${battery_hex#0x}))
    if [[ "$battery_val" -ge 0 && "$battery_val" -le 100 ]] 2>/dev/null; then
      printf '%s\n' "$battery_val"
      return 0
    fi
  fi

  # Fallback: traverse GATT services for Battery Service (older BlueZ/device path)
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

      printf '%s\n' "$hex_val"
      return 0
    done < <(gdbus introspect --system --only-properties \
      --dest "$DBUS_CONN" --object-path "$dev_path/$svc" 2>/dev/null |
      grep -o 'char[0-9a-f][0-9a-f]*')
  done < <(gdbus introspect --system --only-properties \
    --dest "$DBUS_CONN" --object-path "$dev_path" 2>/dev/null |
    grep -o 'service[0-9a-f][0-9a-f]*')

  return 1
}

read_batteries_wsl() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v powershell.exe &>/dev/null || return 1
  grep -qi microsoft /proc/version 2>/dev/null || return 1

  if ! mkdir "/tmp/headphone-battery-wsl.lock" 2>/dev/null; then
    return 1
  fi

  (
    tmp=$(mktemp "$CACHEFILE.XXXXXX")
    result=$(timeout 10 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WSL_PS1" 2>/dev/null | tr -d '\r')
    if [[ -n "$result" ]]; then
      val="${result%% *}"
      if [[ -n "$val" ]]; then
        printf '%s %s\n' "$val" "$(date +%s)" > "$tmp"
        mv "$tmp" "$CACHEFILE"
      fi
    fi
    rm -f "$tmp"
    rmdir "/tmp/headphone-battery-wsl.lock" 2>/dev/null
  ) & disown

  return 1
}

read_batteries_wsl_sync() {
  [[ -f "$WSL_PS1" ]] || return 1
  command -v powershell.exe &>/dev/null || return 1
  grep -qi microsoft /proc/version 2>/dev/null || return 1

  local result val
  result=$(timeout 10 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WSL_PS1" 2>/dev/null | tr -d '\r') || return 1
  val="${result%% *}"
  [[ -z "$val" ]] && return 1
  printf '%s' "$val"
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

fetch_async() {
  (
    flock -xn 200 2>/dev/null || exit 1

    local now ts val
    now=$(date +%s)

    if [[ -f "$CACHEFILE" ]]; then
      read -r val ts < "$CACHEFILE" 2>/dev/null || true
      if [[ -n "$val" ]] && [[ $(( now - ts )) -lt "$CACHE_TTL" ]]; then
        exit 0
      fi
    fi

    local result
    result=$(read_batteries 2>/dev/null) || { rm -f "$CACHEFILE"; exit 1; }
    printf '%s %s\n' "$result" "$now" > "$CACHEFILE"
  ) 200>"$LOCKFILE" >/dev/null 2>&1 & disown
}

main() {
  mkdir -p /tmp

  local now ts val
  now=$(date +%s)

  if [[ -f "$CACHEFILE" ]]; then
    read -r val ts < "$CACHEFILE" 2>/dev/null || true
    if [[ -n "$val" ]]; then
      if [[ $(( now - ts )) -lt "$CACHE_TTL" ]]; then
        printf '%s\n' "$val"
        return 0
      fi
      fetch_async
      printf '%s\n' "$val"
      return 0
    fi
  fi

  fetch_async
  return 1
}

main "$@"
