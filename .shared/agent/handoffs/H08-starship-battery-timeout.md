# H08 — Starship battery timeout

## Goal

Fix `guard.sh` and/or `status.sh` battery scripts that timeout on every starship prompt render, causing 10 `[WARN]` lines per prompt and a sluggish shell experience.

## Symptoms

```
[WARN] - (starship::modules::custom): Executing custom command
"${STARSHIP_CONFIG%/*}/battery/guard.sh 1" timed out.
```

Repeated for each tier 0–9 on every prompt. Likely cause: `upower -e` or `upower -i` hangs or takes longer than starship's default command timeout (500ms).

## Status

**Delivered** — changes merged in commit `[Starship] - Add battery cache and timeout to guard.sh/status.sh`.

## Deliverables

### 1. Cache battery reading across the 10 invocations ✅

`guard.sh` and `status.sh` each call `upower` independently, and guard is called 10 times per prompt. Added a shared cache file `/tmp/starship-battery-cache` with a 2s TTL so the 10 guard + 1 status calls only hit upower once per prompt render.

Implementation: both scripts check the cache first (source it if fresh). On cache miss, they fetch battery data and write `bat`, `raw_status`, and `ts` (epoch timestamp) to the cache. Cache is only written when `bat` is non-empty to avoid caching a "no battery" state.

### 2. Add command timeout in guard.sh ✅

Both `upower -e`, `upower -i`, and `powershell.exe` calls are wrapped with `timeout 0.5`. If upower doesn't respond in 500ms, the script exits 1 (no battery shown) instead of letting starship's built-in 500ms custom module timer fire the warning.

### 3. Reduce starship command_timeout if needed ✅ (not needed)

No changes required — with the cache, all guard.sh/status.sh calls return well within the default 500ms window. The first call (cache miss) does the upower fetch with its own `timeout 0.5`, so it always finishes before starship's timer.

## Files changed

- `starship/.config/starship/battery/guard.sh`
- `starship/.config/starship/battery/status.sh`

## Implementation notes

- Both scripts share identical fetch+cache logic. The cache write happens in the same `if [ -z "$bat" ]` block that fetches, so a cache hit skips the fetch block entirely (no condition duplication).
- When guard.sh runs first and populates the cache, the subsequent 9 guard calls and the 1 status.sh call all read from cache without any upower invocation.
- `raw_status` is now also fetched by guard.sh (previously it only extracted percentage), so status.sh gets the full state even if guard.sh wrote the cache.
- The WSL powershell fallback also now extracts `BatteryStatus` and maps it to the same strings used by status.sh.

## Verification

1. Open a new shell outside tmux — no `[WARN]` battery timeout lines.
2. `time guard.sh 5` returns in under 200ms.
3. Battery status still shows correctly in the prompt.
