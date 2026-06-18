# Consolidate skills to shared location

## Context

We already moved shared conventions to `.shared/agent/conventions.md`. Now we do the same for the slash-command skills (`/commit`, `/stow-deploy`, `/pane-capture`, `/pane-logs`). Currently each skill is duplicated across `.claude/skills/` and `.github/skills/` with slightly different content.

## Constraint

Neither Claude Code nor GitHub Copilot supports a configurable skills path — both hardcode their scan directory (`.claude/skills/` and `.github/skills/` respectively). The only way to share is **symlinks**: put the canonical file in `.shared/agent/skills/<name>/SKILL.md` and symlink both tool-specific paths to it.

## Content merge strategy

### stow-deploy, pane-capture, pane-logs (easy merge)
Differences are cosmetic only — Claude version has frontmatter keys (`user-invocable`, `allowed-tools`, `argument-hint`) + full sentences; Copilot version has minimal frontmatter + compact bullets. Claude's YAML frontmatter is harmless to Copilot (unknown keys are ignored). Merge into one canonical file: Claude frontmatter + combined content (full sentences with compact command references).

### commit (trickier merge)
Differences are substantive:
- **Claude version**: `Claude - <model>` signature, no `Co-Authored-By`, simple 3-step procedure, 3-line subject rules
- **Copilot version**: `Copilot - <model>` or `Claude - <model>` signature, detailed 6-step workflow, component grouping, full formatting rules

Merge by: keep Claude frontmatter, combine procedure steps, include both agent signature styles in the body rules, keep the component grouping and formatting detail from Copilot's version.

## Plan

1. Create canonical skill files in `.shared/agent/skills/<name>/SKILL.md`:
   - `stow-deploy` — Claude frontmatter + merged content
   - `pane-capture` — Claude frontmatter + merged content  
   - `pane-logs` — Claude frontmatter + merged content
   - `commit` — Claude frontmatter + merged content (combine both procedures, support both signatures)

2. Move original files aside and replace with relative symlinks:
   - `.claude/skills/<name>/SKILL.md` → `../../.shared/agent/skills/<name>/SKILL.md`
   - `.github/skills/<name>/SKILL.md` → `../../.shared/agent/skills/<name>/SKILL.md`

3. Remove empty directories after symlinks are in place.

## Files to modify
- Create: `.shared/agent/skills/commit/SKILL.md`, `.../stow-deploy/SKILL.md`, `.../pane-capture/SKILL.md`, `.../pane-logs/SKILL.md`
- Replace: `.claude/skills/commit/SKILL.md`, `.../stow-deploy/SKILL.md`, `.../pane-capture/SKILL.md`, `.../pane-logs/SKILL.md` (→ symlinks)
- Replace: `.github/skills/commit/SKILL.md`, `.../stow-deploy/SKILL.md`, `.../pane-capture/SKILL.md`, `.../pane-logs/SKILL.md` (→ symlinks)

## Verification
- `readlink .claude/skills/*/SKILL.md` resolves to `../../.shared/agent/skills/*/SKILL.md`
- `readlink .github/skills/*/SKILL.md` resolves to `../../.shared/agent/skills/*/SKILL.md`
- `cat .claude/skills/commit/SKILL.md` shows the shared file content (follows symlink)
- Same for `cat .github/skills/commit/SKILL.md`
