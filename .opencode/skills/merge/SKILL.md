---
name: merge
description: Merge a feature branch into master with a conventional commit message. Use when asked to merge a branch.
user-invocable: true
allowed-tools: [Bash, Read, Edit]
---

Use this skill when the task is to merge a feature branch into master.

This skill merges a branch with `--no-ff`, producing a merge commit that follows the
[commit message conventions](.opencode/docs/commit-conventions.md).

## Workflow

1. Check the working tree is clean (`git status`).
2. Determine which branch to merge. If the user didn't specify one, ask.
3. Verify the source branch exists (`git branch --list <branch>`).
4. Check that the branch is rebased on master (`git merge-base --is-ancestor master <branch>`).
   - If not (exit code 1), rebase it onto master (`git rebase master <branch>`), then
     return to master (`git checkout master`). If the rebase stops with conflicts,
     resolve them as described in Conflicts and continue.
5. Check what commits are on the branch but not on master (`git log --oneline master..<branch>`).
6. Determine the component label per [commit-conventions.md](.opencode/docs/commit-conventions.md):
   - For a single-component branch, use that component.
   - If changes span multiple components, combine with `/` (e.g. `Agent/OpenCode`).
   - If the branch is a general integration branch, use `Agent`.
7. Merge with `--no-ff`, crafting the message per the conventions:
   ```bash
   git merge <branch> --no-ff -m "[Component] - Merge <branch>"
   ```
   The body should summarize what the branch brings in (key changes, not a full log).
   If the merge stops with conflicts, resolve them as described in Conflicts.
8. Report the merge commit hash and summary.

## Conflicts

The `/merge` command runs in the `committer` agent, which may run merge, rebase,
commit, and push. Resolve conflicts there instead of stopping:

1. List the conflicted files: `git diff --name-only --diff-filter=U`.
2. Read both sides before editing. In a merge, `--ours` is master and `--theirs`
   is the merged branch. In a rebase, `--ours` is the upstream (master) and
   `--theirs` is the branch being rebased.
3. Resolve each file by combining both intents; never leave conflict markers.
4. Stage the resolved files with `git add <file>`.
5. Set `GIT_EDITOR=true` in the shell, then continue with `git merge --continue`
   or `git rebase --continue`; repeat if new conflicts appear.
6. After it completes, finish the merge commit and report its hash.
