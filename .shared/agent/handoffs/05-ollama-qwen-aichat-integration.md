# Handoff: Integrate Ollama + Qwen into Aichat

## Context

aichat currently uses only remote API providers (DeepSeek, OpenAI, Claude). The user has Ollama running locally with Qwen models — already configured for `gh copilot` in `llm.zsh` (`http://localhost:11434/v1` + `qwen3:4b-instruct`). This task adds Ollama as an aichat client, creates a `qwenie` dispatch route in the command-not-found fallback, and adds a Starship indicator for it.

## Plan File

Full implementation plan at `.claude/plans/help-me-integrate-ollama-robust-toast.md` (tracked in the repo via symlink from `~/.claude/plans/`)

## Key Decisions

- **Nickname**: `qwenie` — keyword trigger for the dispatch
- **Route name**: `aichat-qwen` — used in dispatch cases and route indicators
- **Sessions**: All aichat dispatch routes get dedicated sessions named after their nicknames:
  - `aichat-chat` → `-s talkie --save-session` (was `-s default`)
  - `aichat-reasoner` → `-s thinkie --save-session` (was `-s default`)
  - `aichat-qwen` → `-s qwenie --save-session`
- **Starship style**: `white`
- **Route icon**: ` ` (same spark icon as other routes)

## Files to Modify (in order)

| # | File | Stow | Change |
|---|------|------|--------|
| 1 | `aichat/.config/aichat/config.yaml` | `aichat` | Add `openai-compatible` client: `name: ollama`, `api_base: http://localhost:11434/v1` |
| 2 | `zsh/.config/zsh/llm-fallback.zsh` | `zsh` | Update `aichat-chat`/`aichat-reasoner` sessions to `talkie`/`thinkie`; add `aichat-qwen` case with `-s qwenie`; add `qwenie` keyword trigger |
| 3 | `starship/.config/starship/llm-route.sh` | `starship` | Add `aichat-qwen) echo " " ;;` case |
| 4 | `starship/.config/starship/starship.toml` | `starship` | Add `llm_qwen` format entry + custom module block (style `white`) |
| — | `starship/.config/starship/llm-when.sh` | — | No change needed (already generic) |

## Verification

1. `aichat -m ollama:qwen3:4b-instruct` — should connect to local Ollama
2. `qwenie <some-query>` — should dispatch to `aichat-qwen`
3. Check `~/.config/aichat/sessions/qwenie.yaml`, `talkie.yaml`, `thinkie.yaml` — each with its model
4. Old `~/.config/aichat/sessions/default.yaml` — no longer used by dispatch (can be cleaned up)

## Related Files

- `zsh/.config/zsh/llm.zsh` — already has `COPILOT_PROVIDER_BASE_URL=http://localhost:11434/v1` + `COPILOT_MODEL=qwen3:4b-instruct`
- `.claude/settings.local.json` — has `Bash(ollama rm *)` permission
