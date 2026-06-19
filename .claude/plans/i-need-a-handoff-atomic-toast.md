# Plan: Write Handoff for Quorum CLI Installation

## Context

The user wants a handoff document for adding **quorum-cli** (an LLM debate/orchestration CLI tool) to their dotfiles. Currently:
- quorum-cli is installable via `pip install quorum-cli`
- The dotfiles use `uv tool install` for Python CLI tools (via `UV_PACKAGES` array in `install-dependencies.sh`)
- `UV_PACKAGES` is currently empty — the mechanism is wired up but unused
- quorum-cli requires a `.env` file with API keys to function

## What to Produce

Write a handoff document at `.shared/agent/handoffs/09-quorum-cli-installation.md` covering:

### Deliverables

1. **Add `quorum-cli` to `UV_PACKAGES`** in `zsh/.local/share/zsh/install-dependencies.sh` (line 72-73)
2. **Create a `quorum/` stow package** with:
   - `.config/quorum-cli/.env.example` — template for API keys (documenting which env vars are needed)
   - Possibly `.config/quorum-cli/.env` dotfile tracking? (need to flag that API keys are sensitive — this may need to be in `.gitignore` or user-managed)
3. **Shell completions** — check if `quorum-cli` ships completions and wire them up if so

### Key Files

- `zsh/.local/share/zsh/install-dependencies.sh` — install script, `UV_PACKAGES` array at line 72
- `zsh/.config/zsh/env.zsh` — PATH additions (already includes `~/.cargo/bin` and `~/.local/bin`)
- `.shared/agent/handoffs/` — target directory for the handoff document

### Verification

- `quorum --help` runs after `uv tool install quorum-cli`
- The `.env` file is present with required API keys
- No regression in existing install process

## Open Questions

- Should the `.env` with API keys be tracked in dotfiles or excluded? (likely excluded — sensitive)
- Any shell completion setup needed?
