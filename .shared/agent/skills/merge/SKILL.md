---
name: merge
description: Merge a feature branch into master with a conventional commit message. Use when asked to merge a branch.
user-invocable: true
allowed-tools: [Bash, Read]
---

Use this skill when the task is to merge a feature branch into master.

This skill merges a branch with `--no-ff`, producing a merge commit that follows the
[commit message conventions](.shared/agent/commit-conventions.md).

## Workflow

1. Check the working tree is clean (`git status`).
2. Determine which branch to merge. If the user didn't specify one, ask.
3. Verify the source branch exists (`git branch --list <branch>`).
4. Check that the branch is rebased on master (`git merge-base --is-ancestor master <branch>`).
   - If not (exit code 1), stop and tell the user to ask the branch's agent to rebase first.
5. Check what commits are on the branch but not on master (`git log --oneline master..<branch>`).
6. Determine the component label per [commit-conventions.md](.shared/agent/commit-conventions.md):
   - For a single-component branch, use that component.
   - If changes span multiple components, combine with `/` (e.g. `Agent/OpenCode`).
   - If the branch is a general integration branch, use `Agent`.
7. Merge with `--no-ff`, crafting the message per the conventions:
   ```bash
   git merge <branch> --no-ff -m "[Component] - Merge <branch>"
   ```
   The body should summarize what the branch brings in (key changes, not a full log).
7. Report the merge commit hash and summary.
