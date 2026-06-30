# H08 — Starship timeout warnings

## Goal

Eliminate all `[WARN] - (starship::*)` timeout messages from the prompt: battery custom commands, directory scanning, and any other modules that exceed Starship's defaults.

## Symptoms

### Battery custom command timeouts

```
[WARN] - (starship::modules::custom): Executing custom command
"${STARSHIP_CONFIG%/*}/battery/guard.sh 1" timed out.
```

Repeated for each tier 0–9 on every prompt. Caused by `upower -e` / `upower -i` taking longer than Starship's default 500ms `command_timeout`. Under WSL, the problem is worse: `upower` hangs for the full `timeout 0.5` (no Linux battery in WSL), then falls through to the `powershell.exe` fallback, pushing the first cache-miss invocation to ~1000ms.

### Scan timeout

```
[WARN] - (starship::context): Scanning current directory timed out.
```

Observed in `tiny-repository` and other large repos. Starship walks up the directory tree scanning for `.git`, `.nvim`, etc. The default `scan_timeout` is 30ms, which is too low for repos with many files.

## Status

**Open** — battery cache fix (cache + `timeout 0.5` on upower) is merged but insufficient on WSL. Scan timeout not yet addressed.

## Deliverables

### 1. Cache battery reading across the 10 invocations ✅

`guard.sh` and `status.sh` each call `upower` independently, and guard is called 10 times per prompt. Added a shared cache file `/tmp/starship-battery-cache` with a 2s TTL so the 10 guard + 1 status calls only hit upower once per prompt render.

Implementation: both scripts check the cache first (source it if fresh). On cache miss, they fetch battery data and write `bat`, `raw_status`, and `ts` (epoch timestamp) to the cache. Cache is only written when `bat` is non-empty to avoid caching a "no battery" state.

### 2. Add command timeout in guard.sh ✅

Both `upower -e`, `upower -i`, and `powershell.exe` calls are wrapped with `timeout 0.5`. If upower doesn't respond in 500ms, the script exits 1 (no battery shown) instead of letting starship's built-in 500ms custom module timer fire the warning.

### 3. Add early WSL detection to skip upower ❌

Add a WSL check (`grep -qi microsoft /proc/version`) at the top of both `guard.sh` and `status.sh`. On WSL, skip `upower` entirely and go straight to `powershell.exe`. Saves 500ms per cache-miss invocation.

```bash
# Early WSL fast-path — skip upower entirely
if grep -qi microsoft /proc/version 2>/dev/null; then
    # ... go straight to powershell.exe path ...
fi
```

### 4. Increase Starship command_timeout ❌

Add to `starship.toml` top-level (not inside any `[section]`):

```toml
command_timeout = 1000
```

The default 500ms is too low for the WSL fallback path (powershell.exe interop can take 300-800ms alone). 1000ms provides headroom while keeping the prompt snappy. This applies to all custom modules globally.

### 5. Increase Starship scan_timeout ❌

Add to `starship.toml` top-level:

```toml
scan_timeout = 100
```

The default 30ms is too low for directory scanning in repos with many files. 100ms handles large repos without making the prompt feel sluggish.

## Files changed

- `starship/.config/starship/battery/guard.sh`
- `starship/.config/starship/battery/status.sh`
- `starship/.config/starship/starship.toml`

## Implementation notes

- Both battery scripts share identical fetch+cache logic. Same WSL-detection fix applies to both.
- `command_timeout` and `scan_timeout` go at the top level of `starship.toml`, near `add_newline`.
- No changes needed to the custom module definitions themselves — just the global config.

## Verification

1. Open a new shell outside tmux — no `[WARN]` battery timeout lines.
2. Open a new shell **inside WSL** — no `[WARN]` battery timeout lines.
3. Open a shell in `~/Projects/tiny-repository` — no `[WARN]` scan timeout lines.
4. `time guard.sh 5` returns in under 200ms (cache hit) or under 1000ms (WSL cache miss).
5. Prompt still renders in under 200ms (`time starship prompt`).
6. Battery status still shows correctly in the prompt.
