# Aichat General Role Routes

## Summary

Ensured all three aichat personas (talkie, thinkie, qwenie) and the default REPL permanently load the `general` role. Sessions are gitignored and periodically deleted, so the solution uses config.yaml and the command-line `-r` flag rather than session file role_name fields.

## Files

- `aichat/.config/aichat/config.yaml` — `repl_prelude: default:general` loads the role in REPL mode
- `zsh/.config/zsh/llm-fallback.zsh` — added `-r general` to all three `_llm_dispatch` aichat routes
- `aichat/.config/aichat/roles/general.md` — added Qwenie persona, no-emoji rule, reordered rules

## Key decisions

- Two-pronged approach: `repl_prelude` for REPL mode, explicit `-r general` in the command-not-found handler for fallback routes. This decouples role loading from ephemeral session files.
- The `general` role gates responses by persona name (Talkie/Thinkie/Qwenie) — each session can still be model-specific while sharing the same behavioral rules.

## Future iteration notes

- If the old `default.yaml` session gets deleted, `repl_prelude` will still load the role correctly
- Consider whether other routes (claude-pro, claude-flash) need a shared behavioral prompt
