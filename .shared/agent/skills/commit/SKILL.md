---
name: commit
description: Create a git commit following project conventions. Use when the user asks to commit changes.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

Use this skill when the task is to create commits or draft commit messages.

This repository is organized around top-level components. When making commits:

1. Inspect the changed paths from the repository root.
2. Group changes by the top-level path that owns them.
3. Create one commit per top-level component whenever the changes are not tightly coupled.
4. Do not mix unrelated top-level components into the same commit unless the user explicitly asks for that.

## Component grouping

- For files under a top-level directory, use the first path segment as the component owner.
  - Examples: `hypr/...` -> `Hypr`, `tmux/...` -> `Tmux`, `nvim/...` -> `Nvim`.
- For `.github/...`, use `GitHub`.
- For changes to agent configuration or documentation files (e.g., `.claude/`, `.github/skills/`, `.github/copilot-instructions.md`), use `Agent`.
- For root-level files that are not inside a component directory, use `Repo`.
- Prefer a human-readable component label in title case inside the commit subject.

## Commit message format

Format the first line exactly like this:

```text
[Component] - Summary
```

Examples:

```text
[Hypr] - Increase scrolling column width
[Tmux] - Set default shell to zsh
[GitHub] - Consolidate repository instructions
```

## Subject line rules

- Put the component name in square brackets.
- Use a space, a dash, and a space after the closing bracket.
- Write the summary in sentence style, not title case.
- Capitalize the first letter of the sentence, proper names, and short all-caps terms when needed.
- Keep the summary concise and specific.

## Body rules

- Add detail lines after a blank line.
- Use short sentences or wrapped prose that explains the meaningful changes in the commit.
- Capitalize the first letter of each sentence, proper names, and short all-caps terms when appropriate.
- Mention the key files or behavior changes when that helps explain the commit.
- If the commit is trivial, keep the body brief rather than omitting it entirely.
- End the body with a blank line followed by an agent signature matching the system prompt exactly (e.g., `Claude - deepseek-v4-flash[1m]`, `Copilot - <model>`, or `OpenCode - <model>`).
- Do NOT use `Co-Authored-By` or other signatures.

## Workflow

When asked to make commits:

1. Run `git status`, `git diff`, and `git log -5` to understand state and style.
2. Identify distinct top-level components with changes.
3. Review diffs for each component before staging.
4. Stage only one component at a time (never `git add -A`).
5. Commit that component with the required message format.
6. Repeat for the remaining components.

If a change clearly spans multiple top-level components and cannot be split safely, use the smallest honest shared component label that fits the change, or ask the user if the split is ambiguous.
