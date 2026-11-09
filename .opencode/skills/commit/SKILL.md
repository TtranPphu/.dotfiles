---
name: commit
description: Create a git commit following project conventions. Use when the user asks to commit changes.
user-invocable: true
allowed-tools: [Bash, Read, Grep]
---

> **Hard rule:** `git commit`, `git push`, `git merge`, and `git rebase` are
> denied for normal sessions in `.opencode/opencode.jsonc`. A direct attempt
> returns `Permission denied: shell`; do not retry it. Commits run in the hidden
> `committer` agent through the user's `/commit` command. If you are a normal
> session, ask the user to run `/commit`.

Use this skill when the task is to create commits or draft commit messages.

This repository is organized around top-level components. When making commits:

1. Inspect the changed paths from the repository root.
2. Group changes by the top-level path that owns them.
3. Create one commit per top-level component whenever the changes are not tightly coupled.
4. Do not mix unrelated top-level components into the same commit unless the user explicitly asks for that.

See [commit-conventions.md](.opencode/docs/commit-conventions.md) for the shared message format rules.

## Workflow

When asked to make commits:

1. Run `git status -u`, `git diff`, and `git log -5` to understand state and style.
2. If running as a subagent, read the parent session's recent user/assistant
   messages for intent. The current session is `$OPENCODE_SESSION_ID`; the
   parent ID is in the local OpenCode database:
   ```bash
   db="$HOME/.local/share/opencode/opencode.db"
   parent=$(sqlite3 -json "$db" "SELECT parent_id FROM session_v2 WHERE id='$OPENCODE_SESSION_ID';" | jq -r '.[0].parent_id // empty')
   if [ -n "$parent" ]; then
     sqlite3 -json "$db" "SELECT data FROM session_message WHERE session_id='$parent' AND type IN ('user','assistant') ORDER BY seq DESC LIMIT 20;" \
       | jq -r '.[].data | fromjson | if .text then .text else (.content[]? | select(.type == "text") | .text) end'
   fi
   ```
   Use this to understand why the changes exist; the diff and repository state
   remain authoritative. Skip silently if the database or tables are unavailable.
3. Identify distinct top-level components with changes.
4. Review diffs for each component before staging.
5. Stage only one component at a time (never `git add -A`).
6. Commit that component with the required message format.
7. Repeat for the remaining components.

If a change clearly spans multiple top-level components and cannot be split safely, use the smallest honest shared component label that fits the change, or ask the user if the split is ambiguous.
