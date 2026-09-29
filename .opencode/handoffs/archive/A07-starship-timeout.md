# Starship timeout

## Summary
Investigated and partially resolved Starship `[WARN]` timeout messages from battery custom commands and directory scanning. Battery scripts were consolidated from `battery/guard.sh` + `battery/status.sh` into `scripts/battery.sh` + `scripts/battery-util.sh` with shared caching (`/tmp/starship-battery-cache`, 60s TTL), `timeout 0.5` wrappers on `upower`, and early WSL detection to skip `upower` and go straight to `powershell.exe`. The global `command_timeout` and `scan_timeout` settings in `starship.toml` were never added.

## Files
- `starship/.config/starship/scripts/battery.sh` — display/guard wrapper
- `starship/.config/starship/scripts/battery-util.sh` — battery fetch with cache, timeouts, WSL fast-path
- `starship/.config/starship/starship.toml` — 10 battery custom modules (`custom.battery_0`–`custom.battery_9`)

## Key decisions
- Cache + `timeout 0.5` on `upower` calls eliminates the per-prompt battery timeout warnings on Linux
- WSL detection (`grep -qi microsoft /proc/version`) skips the `upower` round-trip entirely, saving 500ms per cache-miss invocation
- Guard/status scripts merged into a single `battery.sh` + `battery-util.sh` pair instead of separate `guard.sh`/`status.sh`

## Future iteration notes
- Add `command_timeout = 1000` to `starship.toml` top-level for headroom on WSL fallback path
- Add `scan_timeout = 100` to `starship.toml` top-level to prevent directory scan warnings in large repos
