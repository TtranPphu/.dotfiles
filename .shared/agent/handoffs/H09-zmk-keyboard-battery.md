# H09 — ZMK split keyboard battery reporting

## Goal

Create a CLI tool that reads battery levels from both halves of a ZMK split keyboard (Cornix) via BlueZ GATT, outputting machine-parseable JSON for consumption by starship, waybar, or any other component.

## Background

ZMK exposes an auxiliary Battery Level characteristic (0x2A19 under service 0x180F) on the central half, proxying the peripheral's battery. Linux/upower only sees the main battery. The auxiliary level must be read directly via D-Bus/BlueZ GATT.

## Deliverables

### 1. Create `zsh/.local/bin/keyboard-battery`

Script at `~/.dotfiles/zsh/.local/bin/keyboard-battery`. Accepts subcommands:

| Subcommand | Output | Use case |
|---|---|---|
| `keyboard-battery` (no args) | `{"left":85,"right":72}` or non-zero exit if disconnected | General purpose — starship, waybar, scripts |
| `keyboard-battery --guard <tier>` | Exit 0 if **worst** battery ≤ tier range, else 1 | Starship guard (replaces/exists alongside laptop `guard.sh`) |
| `keyboard-battery --waybar` | Waybar JSON with tooltip showing both halves | Direct waybar custom module |

**Behavior:**

- Auto-detect Cornix keyboard by name alias (try `Cornix`, `Cornix Dongle`, fallback to first device with a Battery Service that has auxiliary descriptor).
- Read both Battery Level characteristics under the 0x180F service.
- Identify main vs auxiliary via the Characteristic User Description descriptor (0x2901): if the descriptor reads `"auxiliary"`, it's the peripheral (right) half. If no descriptor or value is `"main"`, it's the central (left) half.
- `timeout 2` every D-Bus call — stalled Bluetooth responses must never delay the prompt.
- Cache result in `/tmp/keyboard-battery.json` with a 5-second TTL so multiple callers (10 starship tiers) share one Bluetooth read. If cache is stale, all waiters block on the first caller. Use a lock file (`/tmp/keyboard-battery.lock`) with `flock` to serialize.
- On error or timeout, exit 1 with no output (starship shows nothing).

### 2. Symlink and deploy

```bash
chmod +x ~/.dotfiles/zsh/.local/bin/keyboard-battery
ln -sf ../../.dotfiles/zsh/.local/bin/keyboard-battery ~/.local/bin/keyboard-battery
```

`~/.local/bin` is already on PATH via `env.zsh` — no config changes needed.

### 3. Wire into starship (optional, recommended)

Replace the 10 `battery_N` custom modules in `starship.toml` with a single module for keyboard battery:

```toml
[custom.kb_battery]
command = 'keyboard-battery'
when = 'keyboard-battery --guard 9'
shell = ["bash"]
style = "bold #9ece6a"
format = " [$output]($style)"
```

Or merge into the existing battery display with a combined status line. The handoff implementer should decide with the user.

## Files

| File | Role |
|---|---|
| `zsh/.local/bin/keyboard-battery` | New script (tool) |
| `starship/.config/starship/starship.toml` | Optional: add keyboard battery module |
| `~/.local/bin/keyboard-battery` | Symlink target |

## Key Findings

- **Auxiliary descriptor is the discriminator**: ZMK's split battery proxy (PR #2045) marks the peripheral battery characteristic with `"auxiliary"` in the User Description descriptor (0x2901). No other reliable way to tell halves apart.
- **D-Bus path is unpredictable**: BlueZ assigns service/characteristic paths like `service0010/char0011`. Must introspect by UUID, not hardcode paths.
- **`bluetoothctl gatt.list-attributes` is slow**: Prefer direct `gdbus` calls with `org.bluez.GattService1.UUID` and `org.bluez.GattCharacteristic1.UUID` property reads.
- **Two keyboard names in play**: Left half shows as `"Cornix"`, dongle half shows as `"Cornix Dongle"`. Match by substring `"Cornix"`.
- **Cache is essential**: Same reasoning as H08 — 10 starship guard invocations per prompt would each trigger a BLE round-trip without it.
- **`flock` over `mkdir`**: Use `flock -n /tmp/keyboard-battery.lock` for cache serialization. The lock is released when the script exits, so timeouts auto-clean.
- **No `upower` involvement**: upower only exposes the main (left) battery. Never read keyboard battery from upower.
- **Existing starship battery scripts** (`guard.sh`, `status.sh`) handle the **laptop battery**, not the keyboard. The new script is complementary, not a replacement.
- **No Python dependency**: Keep it pure bash + `gdbus` / `bluetoothctl` so it works in any environment without venv management.

## Potential Issues

1. **`gdbus` not available** — falls back to `bluetoothctl gatt.list-attributes` + `gatt.read`, which is slower but works everywhere BlueZ is present.
2. **Multiple ZMK keyboards connected** — match by alias substring. If ambiguous, pick the first. Could add a `--mac <addr>` flag in future.
3. **Keyboard disconnected or not bonded** — D-Bus paths may not exist. Check `org.bluez.Device1.Connected` property before attempting reads.
4. **Battery level stale** — ZMK reports on change + every 60s (configurable via `CONFIG_ZMK_BATTERY_REPORT_INTERVAL`). The characteristic is readable any time, but the value might lag behind real charge by up to 60s.
5. **Descriptor length** — The auxiliary descriptor might be an empty byte array if firmware is older than the ZMK split battery PR. If no descriptor found, treat the first Battery Level as main and the second as peripheral (order-dependent fallback).
6. **BlueZ not running** — all calls fail silently, script exits 1. Starship shows nothing, no warnings.

## References

| What | Link |
|---|---|
| ZMK battery Kconfig docs | https://zmk.dev/docs/config/battery |
| ZMK split config (BLE battery flags) | https://zmk.dev/docs/config/split |
| ZMK split keyboards feature page | https://zmk.dev/docs/features/split-keyboards |
| PR #2045 — split battery reporting over BLE GATT | https://github.com/zmkfirmware/zmk/pull/2045 |
| Original issue #764 — feature request | https://github.com/zmkfirmware/zmk/issues/764 |
| Python script — read both levels via dbus-next | https://gist.github.com/madushan1000/9744eb6350a5dd9685fb6bfbb25fbb8a |
| Shell script — read both levels via gdbus | https://gist.github.com/alsibir/7556807954c8dce3660f575ae7108cb5 |
| zmkBATx — Linux system tray app (AUR: `zmkbatx`) | https://github.com/mh4x0f/zmkBATx |
| ZmkBatteryClient — Waybar custom module | https://github.com/JanValiska/ZmkBatteryClient |
| zmk-battery-center — Tauri tray app (cross-platform) | https://github.com/kot149/zmk-battery-center |
| H08 — Starship battery timeout (cache pattern reference) | `H08-starship-battery-timeout.md` |
| Cornix ZMK config (this repo) | `boards/jzf/cornix/cornix_left_defconfig` (lines 67-68) |
| Existing laptop battery scripts | `starship/.config/starship/battery/guard.sh` and `status.sh` |

## Verification

1. Run `keyboard-battery` while keyboard is connected — valid JSON with two integer values printed within 500ms.
2. Run `keyboard-battery --guard 5` at 50% charge — exits 0 (true, worst battery is ≤ 50%).
3. Run `keyboard-battery --guard 1` at 50% charge — exits 1 (false).
4. Disconnect keyboard — exits 1 with no output.
5. Run 10 instances in parallel — only one hits Bluetooth, others read cache, all return within 1s total.
6. `timeout 1 keyboard-battery` never hangs.
7. `keyboard-battery --waybar` outputs valid Waybar JSON.
