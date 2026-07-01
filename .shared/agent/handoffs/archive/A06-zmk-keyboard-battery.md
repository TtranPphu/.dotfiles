# A06 — ZMK split keyboard battery reporting

## Goal

Create a CLI tool that reads battery levels from both halves of a ZMK split keyboard (Cornix) via BlueZ GATT, outputting machine-parseable values for consumption by starship and tmux.

## Background

ZMK exposes an auxiliary Battery Level characteristic (0x2A19 under service 0x180F) on the central half, proxying the peripheral's battery. Linux/upower only sees the main battery. The auxiliary level must be read directly via D-Bus/BlueZ GATT.

## Architecture

```
.shared/scripts/keyboard-battery-util.sh           # Canonical — pure data, no rendering

starship/.config/starship/scripts/
  keyboard-battery-util.sh                          # Symlink → ../../../../.shared/scripts/keyboard-battery-util.sh
  keyboard-battery.sh                               # Wrapper — --display, --guard for starship

tmux/.config/tmux/scripts/status/
  keyboard-battery-util.sh                          # Symlink → ../../../../../.shared/scripts/keyboard-battery-util.sh
  keyboard-battery.sh                               # Wrapper — --tmux with #[fg=...] segments
```

## Deliverables

### 1. `.shared/scripts/keyboard-battery-util.sh`

Pure data utility. Reads both battery levels from the Cornix keyboard via GATT, outputs space-separated integers:

| Subcommand | Output | Use case |
|---|---|---|
| `keyboard-battery-util.sh` (no args) | `"85 72"` or exit 1 with no output | Parsed by wrappers |

**Behavior:**
- Auto-detect Cornix keyboard by alias substring via D-Bus introspection
- Read both Battery Level characteristics under the 0x180F service
- Identify main vs auxiliary via the Characteristic User Description descriptor (0x2901): if the descriptor reads `"auxiliary"`, it's the peripheral (right) half. If no descriptor or value is `"main"`, it's the central (left) half
- Fallback: if two Battery Level characteristics exist but neither has the "auxiliary" descriptor, assign first found as left, second as right (order-dependent)
- `timeout 2` on every D-Bus call
- Cache in `/tmp/keyboard-battery.json` with 5-second TTL; `flock` serialization via `/tmp/keyboard-battery.lock`
- On error or timeout, exit 1 with no output

### 2. Symlinks

Each stow package that uses the util gets a symlink to the canonical source:

```
starship/.config/starship/scripts/keyboard-battery-util.sh → ../../../../.shared/scripts/keyboard-battery-util.sh
tmux/.config/tmux/scripts/status/keyboard-battery-util.sh  → ../../../../../.shared/scripts/keyboard-battery-util.sh
```

### 3. Starship wrapper (`starship/.config/starship/scripts/keyboard-battery.sh`)

| Subcommand | Output |
|---|---|
| `--display left` | ` 85` |
| `--display right` | ` 72` |
| `--guard <0-9> left` | Exit 0 if left battery is in tier range |
| `--guard <0-9> right` | Exit 0 if right battery is in tier range |

### 4. Tmux wrapper (`tmux/.config/tmux/scripts/status/keyboard-battery.sh`)

| Subcommand | Output |
|---|---|
| `--tmux` | Two `#[fg=brightblack,bold,bg=<color>]  N #[default]` segments |

### 5. Starship modules — 20 tiered modules

`[custom.keyboard_N]` and `[custom.keyboard_right_N]` (N=0..9) added to `starship.toml`:

- Same color palette as `battery_N` modules (#f7768e → #9ece6a)
- Hidden in tmux via `[ -z "$TMUX" ]` guard in `when`
- Placed after `battery_0` in format string

### 6. Tmux integration

`right.sh` calls `"$script_dir/keyboard-battery.sh"` after the existing `battery.sh` call.

## Files

| File | Role |
|---|---|
| `.shared/scripts/keyboard-battery-util.sh` | Canonical utility script |
| `starship/.config/starship/scripts/keyboard-battery-util.sh` | Symlink to canonical |
| `starship/.config/starship/scripts/keyboard-battery.sh` | Starship wrapper |
| `tmux/.config/tmux/scripts/status/keyboard-battery-util.sh` | Symlink to canonical |
| `tmux/.config/tmux/scripts/status/keyboard-battery.sh` | Tmux wrapper |
| `starship/.config/starship/starship.toml` | 20 keyboard modules added |
| `tmux/.config/tmux/scripts/status/right.sh` | keyboard-battery.sh call added |

## Key Findings

- **Auxiliary descriptor is the discriminator**: ZMK's split battery proxy (PR #2045) marks the peripheral battery characteristic with `"auxiliary"` in the User Description descriptor (0x2901).
- **D-Bus path is unpredictable**: BlueZ assigns paths like `service0010/char0011`. Must introspect by UUID.
- **`gdbus` over `bluetoothctl`**: `gdbus` is faster for direct D-Bus property reads.
- **Two keyboard names**: `"Cornix"` and `"Cornix Dongle"`. Match by substring.
- **Cache is essential**: 10 starship guard invocations per prompt would each trigger a BLE round-trip without it.
- **`flock` for serialization**: Blocking exclusive lock; lock released on script exit.
- **No `upower` involvement**: upower only exposes the main (left) battery.
- **Charging not detectable via GATT**: The standard Battery Level characteristic (0x2A19) only reports percentage. Always shows discharging icon ().
- **Pure bash**: No Python dependency. `gdbus` is the only external dependency.
- **`printf "\\x$hex"` for descriptor byte decoding**: Must use direct interpolation, not `%s` format (otherwise `\x` escape is not interpreted).

## Potential Issues

1. **`gdbus` not available** — falls back to `bluetoothctl` (not yet implemented in the util).
2. **Multiple ZMK keyboards connected** — match by alias substring; picks the first match.
3. **Keyboard disconnected** — D-Bus paths may not exist; `Connected` property check before reads.
4. **Battery level stale** — ZMK reports on change + every 60s. Value may lag by up to 60s.
5. **Descriptor missing** — old firmware may not set the "auxiliary" descriptor. Fallback uses first-found order.
6. **BlueZ not running** — all calls fail silently; exit 1, no warnings.

## References

| What | Link |
|---|---|
| ZMK battery Kconfig docs | https://zmk.dev/docs/config/battery |
| ZMK split config | https://zmk.dev/docs/config/split |
| PR #2045 — split battery reporting | https://github.com/zmkfirmware/zmk/pull/2045 |
| Shell script — read via gdbus | https://gist.github.com/alsibir/7556807954c8dce3660f575ae7108cb5 |
| Python script — read via dbus-next | https://gist.github.com/madushan1000/9744eb6350a5dd9685fb6bfbb25fbb8a |
| H08 — cache pattern reference | `H08-starship-timeout.md` |
| Existing laptop battery scripts | `starship/.config/starship/battery/guard.sh`, `status.sh` |

## Verification

1. Run `.shared/scripts/keyboard-battery-util.sh` while keyboard is connected — outputs `"85 72"` within 500ms.
2. Run `starship/.../scripts/keyboard-battery.sh --guard 5 left` at 50% — exits 0.
3. Run `tmux/.../scripts/keyboard-battery.sh --tmux` — outputs two colored segments.
4. Disconnect keyboard — all scripts exit 1 with no output.
5. Run 10 instances in parallel — only one hits Bluetooth, others read cache.
6. `timeout 1 .shared/scripts/keyboard-battery-util.sh` never hangs.
7. Both starship modules (`keyboard`, `keyboard_right`) show correct values in prompt.
8. Tmux status-right shows both keyboard battery segments.
