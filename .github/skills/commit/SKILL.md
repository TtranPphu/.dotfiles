---
name: commit
description: Split changes into separate commits by top-level component in this dotfiles repository, and write commit messages in the user's preferred bracketed format. Use this when asked to make commits, prepare commits, or write commit messages.
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
- End the body with a blank line followed by an agent signature: `Copilot - <model>` for Copilot CLI or `Claude - <model>` for Claude Code.

## Workflow

When asked to make commits:

1. Check `git status --short` and `git diff --stat`.
2. Identify distinct top-level components with changes.
3. Review diffs for each component before staging.
4. Stage only one component at a time.
5. Commit that component with the required message format.
6. Repeat for the remaining components.

If a change clearly spans multiple top-level components and cannot be split safely, use the smallest honest shared component label that fits the change, or ask the user if the split is ambiguous.
