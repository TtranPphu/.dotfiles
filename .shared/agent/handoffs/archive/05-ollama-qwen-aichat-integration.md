# Ollama + Qwen Aichat Integration

## Summary

Added Ollama as an `openai-compatible` aichat client for local Qwen models, created a `qwenie` keyword dispatch route in the command-not-found fallback, gave it a dedicated `-s qwenie` session, and added a `white`-styled Starship indicator. Also migrated the existing `aichat-chat` and `aichat-reasoner` routes from the shared `default` session to dedicated `talkie`/`thinkie` sessions.

## Files

- `aichat/.config/aichat/config.yaml` — added `openai-compatible` ollama client with `qwen3:4b-instruct`
- `zsh/.config/zsh/llm-fallback.zsh` — added `aichat-qwen` case, `qwenie` keyword trigger, migrated sessions
- `starship/.config/starship/llm-route.sh` — added `aichat-qwen` icon case
- `starship/.config/starship/starship.toml` — added `custom.llm_qwen` module (style `white`)

## Key decisions

- Nickname `qwenie` for the Ollama dispatch route; internal route name `aichat-qwen`
- Each dispatch route gets a dedicated aichat session (`talkie`, `thinkie`, `qwenie`)
- Same spark icon `` as other LLM routes; Starship style `white`

## Future iteration notes

- Old `default.yaml` session file can be cleaned up from `~/.config/aichat/sessions/`
- Ollama auto-discovers models, so adding new Qwen variants needs no config change
