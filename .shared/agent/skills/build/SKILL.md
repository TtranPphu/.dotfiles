---
name: build
description: Implement a handoff's deliverables. Usable standalone or within the initiate loop.
user-invocable: true
argument-hint: <handoff-identifier>
allowed-tools: [Read, Write, Bash, Grep, Glob]
---

## Instructions

### 1. Identify the handoff
If an argument is given, search `.shared/agent/handoffs/` for a file matching `*<argument>*`.
If no argument, list available handoffs and ask the user to pick one.

### 2. Read the handoff
Read the handoff file in full. Focus on the **Deliverables** section — each item specifies files to create or modify and their content.

### 3. Determine and switch to branch
Extract the topic from the handoff filename (e.g. `H03-stt-tmux-integration.md` → topic `stt-tmux-integration`).
Expand known abbreviations for the branch name:

| Abbreviation | Expansion |
|---|---|
| `stt` | `speech-to-text` |

Check if branch `<expanded-topic>` exists:
- If yes: `git switch <expanded-topic>`
- If no: `git checkout -b <expanded-topic> master`

### 4. Implement each deliverable
For each item in the Deliverables section:
- Create or modify files at the specified paths
- Follow the exact specifications (code snippets, config values, file structure)
- Use existing project conventions

### 5. Commit
Stage and commit to the branch:

```bash
git add -A
iteration=$(git rev-list --count HEAD ^master 2>/dev/null || echo 1)
git commit -m "[<topic>] - Build iteration ${iteration}: <summary of changes>"
```

### 6. Report
Summarize what was implemented. List each file that was created or modified.
