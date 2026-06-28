# H10 — Starship scan timeout

## Goal

Fix the `[WARN] - (starship::context): Scanning current directory timed out.` warning that appears in the `tiny-repository` project on every prompt, and set a sane `scan_timeout` in starship config to prevent it in other large repos.

## Symptoms

```
[WARN] - (starship::context): Scanning current directory timed out.
[WARN] - (starship::context): You can set scan_timeout in your config to a higher value to allow longer-running scans to keep executin
g.
```

Observed in pane `%7` (`tiny-repository:1.1 opencode`). Likely triggered by starship walking up the directory tree scanning for `.git`, `.nvim`, or other context files in a repo with many files.

## Solution

Add `scan_timeout` to **`starship/.config/starship/starship.toml`**. The default is 30ms. A reasonable value is 100–200ms — enough for large repos but quick enough that prompt doesn't feel sluggish.

```toml
scan_timeout = 100
```

Add it at the top level (after `add_newline` or before `format`), not inside any `[section]`.

## Files changed

- `starship/.config/starship/starship.toml`

## Verification

1. Open a shell in `~/Projects/tiny-repository` — no `[WARN]` scan timeout lines.
2. Prompt still renders in under 200ms (`time starship prompt`).

## Related

- H08 — Starship battery timeout: similar warning pattern, different module (custom command vs context scan). Both emit `[WARN] - (starship::<module>)` with a timeout message.
