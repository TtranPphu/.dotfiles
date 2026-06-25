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
  - Examples: `hypr/...` -> `Hypr`, `tmux/...` -> `Tmux`, `nvim/...` -> `Nvim`, `opencode/...` -> `OpenCode`.
- For `.github/...`, use `GitHub`.
- For changes to agent configuration or documentation files (e.g., `.claude/`, `.github/skills/`, `.github/copilot-instructions.md`), use `Agent`.
- For root-level files that are not inside a component directory, use `Repo`.
- Prefer a human-readable component label in title case inside the commit subject.
- When changes span multiple tightly-coupled components (e.g., removing an old file in one component
  and updating references in another), combine them with `/`: `[Zsh/Nu]`.

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
[OpenCode] - Add stow package for opencode config
[Zsh/Nu] - Update install-deps and reference
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
- End the body with a blank line followed by an agent signature matching the system prompt exactly (e.g., `OpenCode - deepseek-v4-flash-free`, `Claude - deepseek-v4-flash[1m]`, or `Copilot - <model>`).
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

## Handoff branch workflow

When committing during a handoff build loop, you are on a feature branch (not master).

- Check that you are on the correct branch (`git branch --show-current`)
- Stage all changes for the handoff: `git add -A`
- Commit with iteration tracking:
  ```bash
  iteration=$(git rev-list --count HEAD ^master 2>/dev/null || echo 1)
  git commit -m "[<topic>] - Build iteration ${iteration}: <summary>"
  ```

## Merge to master

When the user asks to merge a feature branch (e.g. "merge"):

1. Ensure the working tree is clean (`git status`)
2. Switch to master: `git checkout master`
3. Squash merge the branch:
   ```bash
   git merge --squash <branch-name>
   git commit -m "[Component] - <descriptive summary>"
   ```
4. Delete the feature branch: `git branch -D <branch-name>`
5. Report success.
   - The agent signature in the commit body should match the system prompt.
   - Write a concise summary line in the merge commit.
