---
name: merge
description: Merge a feature branch into master with a conventional commit message. Use when asked to merge a branch.
user-invocable: true
allowed-tools: [Bash, Read]
---

Use this skill when the task is to merge a feature branch into master.

This skill merges a branch with `--no-ff`, producing a merge commit that follows the
same message conventions as the `/commit` skill.

## Workflow

1. Check the working tree is clean (`git status`).
2. Determine which branch to merge (from the user's request, or default to `agent`).
3. Verify the target branch exists (`git branch --list <branch>`).
4. Check what commits are on the branch but not on master (`git log --oneline master..<branch>`).
5. Identify the top-level components those commits touch.
6. Determine the component label:
   - If all changes are in one component, use that.
   - If changes span multiple components, combine with `/` (e.g. `Agent/OpenCode`).
   - If the branch itself is a general integration branch, use `Agent` as the label.
7. Merge with `--no-ff`:
   ```bash
   git merge <branch> --no-ff -m "[Component] - Merge <branch>"
   ```
8. Craft the commit message body:
   - Summarize what the branch brings in (key changes, not a full log).
   - End with a blank line and the agent signature matching the system prompt.
9. Report the merge commit hash and summary.

## Commit message format

```text
[Component] - Merge <branch>

- Key change one
- Key change two

<agent-name> - <model>
```

The component label, summary style, and agent signature follow the
same rules as [/commit](../commit/SKILL.md).
