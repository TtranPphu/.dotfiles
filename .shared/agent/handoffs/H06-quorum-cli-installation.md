# Handoff: Quorum CLI Installation

## Goal

Add [quorum-cli](https://github.com/Detrol/quorum-cli) to the dotfiles install pipeline and document its configuration. Quorum orchestrates structured debates between multiple LLMs (GPT, Claude, Gemini, Grok, Ollama) using formal discussion methods.

## Deliverables

### 1. Add `quorum-cli` to `UV_PACKAGES`

**File:** `zsh/.local/share/zsh/install-dependencies.sh` (line 72)

Insert `quorum-cli` into the empty `UV_PACKAGES` array:

```bash
# Packages installed via `uv tool install`
declare -a UV_PACKAGES=(
  quorum-cli
)
```

This is the only code change. `uv` is already installed as a priority package and the `install_via_uv` function is fully implemented. `uv tool install quorum-cli` will be called automatically on the next shell login (or `reload`).

### 2. Document `.env` setup (NOT tracked in dotfiles)

API keys are **not** tracked in the repo — they stay local. The user needs to create `~/.config/quorum-cli/.env` with at least one provider key:

```bash
# Provider API keys (at least one required)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...
XAI_API_KEY=...
OLLAMA_API_KEY=...      # only if Ollama requires proxy auth
OPENROUTER_API_KEY=...  # optional, for OpenRouter

# Optional: model overrides (comma-separated)
# OPENAI_MODELS=gpt-5.2,gpt-5.1
# ANTHROPIC_MODELS=claude-sonnet-4-20250514
# GOOGLE_MODELS=gemini-3-pro

# Optional: endpoint overrides
# OLLAMA_BASE_URL=http://localhost:11434
```

Quorum reads `.env` automatically from the current directory or from `~/.quorum/` (its data dir). Alternatively, the env vars can be set in the user's shell profile (`~/.config/zsh/env.zsh` or `~/.zshenv`).

## Deployment

No stow commands needed — the only tracked file is `install-dependencies.sh` which is already deployed. Changes take effect on next shell reload.

## Key Findings

- **`uv tool install` is the right mechanism** — `UV_PACKAGES` exists and is wired up but was empty. quorum-cli is a natural first entry.
- **No shell completions** — quorum-cli doesn't ship them, so nothing to wire up.
- **Data dir** — `~/.quorum/` stores history, settings, and validated model cache. Auto-created by quorum on first run.
- **No PATH change needed** — `uv tool install` places binaries in `~/.local/bin` which is already in `PATH` via `zsh/.config/zsh/env.zsh`.
- **Seven discussion methods** — Standard, Oxford, Advocate, Socratic, Delphi, Brainstorm, Tradeoff. Default is Standard.

## Potential Issues

- **Multiple API keys** — The user may need to gather keys from several providers. The handoff doesn't create a tracked `.env` template, so the user needs to know what vars to set.
- **`uv` not installed yet** — If `uv` fails to install (priority step), quorum-cli won't install either. This is handled gracefully by the existing install script (logs failure, moves on).
- **Python 3.11+ required** — quorum-cli requires Python 3.11+. `uv` will handle this check; if the system Python is too old, the install will fail with a clear error.

## Verification

1. Run `reload` in a new shell (or `uv tool install quorum-cli` manually)
2. `quorum --help` prints usage
3. Create `~/.config/quorum-cli/.env` with at least one API key
4. `quorum` launches the interactive TUI
5. `/models` shows available models and `quorum --list-providers` lists providers
6. No regression: other `uv tool install` packages still work, existing tools unaffected
