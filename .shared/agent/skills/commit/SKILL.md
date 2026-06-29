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

See [commit-conventions.md](.shared/agent/commit-conventions.md) for the shared message format rules.

## Workflow

When asked to make commits:

1. Run `git status -u`, `git diff`, and `git log -5` to understand state and style.
2. Identify distinct top-level components with changes.
3. Review diffs for each component before staging.
4. Stage only one component at a time (never `git add -A`).
5. Commit that component with the required message format.
6. Repeat for the remaining components.

If a change clearly spans multiple top-level components and cannot be split safely, use the smallest honest shared component label that fits the change, or ask the user if the split is ambiguous.
