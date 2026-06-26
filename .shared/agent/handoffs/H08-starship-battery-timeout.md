# H08 — Starship battery timeout

## Goal

Fix `guard.sh` and/or `status.sh` battery scripts that timeout on every starship prompt render, causing 10 `[WARN]` lines per prompt and a sluggish shell experience.

## Symptoms

```
[WARN] - (starship::modules::custom): Executing custom command
"${STARSHIP_CONFIG%/*}/battery/guard.sh 1" timed out.
```

Repeated for each tier 0–9 on every prompt. Likely cause: `upower -e` or `upower -i` hangs or takes longer than starship's default command timeout (500ms).

## Deliverables

### 1. Cache battery reading across the 10 invocations

`guard.sh` and `status.sh` each call `upower` independently, and guard is called 10 times per prompt. Add a cache file (e.g. `/tmp/starship-battery-cache`) with a short TTL (~2s) so the 10 guard calls only hit upower once.

### 2. Add command timeout in guard.sh

Wrap the `upower` / `powershell.exe` calls with a timeout (e.g. `timeout 0.5`). If it doesn't respond in 500ms, exit 1 (no battery shown).

### 3. Reduce starship command_timeout if needed

In `starship.toml`, set a global or per-custom-module `command_timeout` to match the expected guard.sh runtime. Current default is 500ms — may need to lower it or ensure guard.sh always exits within budget.

## Files

- `starship/.config/starship/battery/guard.sh`
- `starship/.config/starship/battery/status.sh`
- `starship/.config/starship/starship.toml` (lines 205–273, the 10 custom battery modules)

## Key Findings

- 10 separate custom modules each invoke guard.sh independently — no shared state between calls.
- guard.sh exits early if in tmux/zellij, but outside a multiplexer it runs `upower -e` + `upower -i` every time.
- `powershell.exe` fallback is for WSL and is very slow (can take seconds).
- starship treats custom module timeout as a warning but still renders the prompt; the warnings are noisy.

## Verification

1. Open a new shell outside tmux — no `[WARN]` battery timeout lines.
2. `time guard.sh 5` returns in under 200ms.
3. Battery status still shows correctly in the prompt.
