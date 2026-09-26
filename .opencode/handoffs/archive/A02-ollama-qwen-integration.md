# Qwen / Ollama Integration

## Summary

Added Ollama as an `openai-compatible` aichat client for local Qwen models, created a `qwenie` keyword dispatch route in the command-not-found fallback with a dedicated `-s qwenie` session, and added a `white`-styled Starship indicator. Later ensured all three aichat personas (talkie, thinkie, qwenie) permanently load the `general` role via `repl_prelude` and `-r` flag, decoupling role loading from ephemeral session files.

## Files

- `aichat/.config/aichat/config.yaml` — added `openai-compatible` ollama client with `qwen3:4b-instruct`; set `repl_prelude: default:general`
- `zsh/.config/zsh/llm-fallback.zsh` — added `aichat-qwen` case, `qwenie` keyword trigger; migrated talkie/thinkie from shared `default` session to dedicated `talkie`/`thinkie` sessions; added `-r general` to all routes
- `starship/.config/starship/llm-route.sh` — added `aichat-qwen` icon case
- `starship/.config/starship/starship.toml` — added `custom.llm_qwen` module (style `white`)
- `aichat/.config/aichat/roles/general.md` — added Qwenie persona, no-emoji rule, reordered rules

## Key decisions

- Nickname `qwenie` for the Ollama dispatch route; internal route name `aichat-qwen`
- Each dispatch route gets a dedicated aichat session (`talkie`, `thinkie`, `qwenie`)
- Same spark icon `` as other LLM routes; Starship style `white`
- Two-pronged role approach: `repl_prelude` for REPL mode, explicit `-r general` in command-not-found handler — decouples role loading from ephemeral session files
- The `general` role gates responses by persona name (Talkie/Thinkie/Qwenie), allowing model-specific sessions with shared behavioral rules

## Future iteration notes

- Old `default.yaml` session file can be cleaned up from `~/.config/aichat/sessions/`
- Ollama auto-discovers models, so adding new Qwen variants needs no config change
- Consider whether other routes (claude-pro, claude-flash) need a shared behavioral prompt
