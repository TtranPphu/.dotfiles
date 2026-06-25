---
name: initiate
description: Orchestrate the build-verify-retrospect loop for a handoff. Entry point for automated handoff execution.
---

Use this workflow when asked to start a handoff loop or when the user runs `/initiate`.

## Workflow

### 1. List available handoffs
Read `.shared/agent/handoffs/` directory. Filter for `H<NN>-*.md` files, excluding `archive/`.
Present them as a numbered list to the user.

### 2. Select handoff
Ask the user to pick one by number or identifier.

### 3. Read and present the handoff
Read the selected handoff file in full. Present:
- Title and Goal
- Each Deliverable
- Each Verification item

Ask: "Proceed with implementation? [Y/n]"
If the user declines, stop here.

### 4. Create feature branch
Extract the topic from the handoff filename (e.g. `H03-stt-tmux-integration` → topic `stt-tmux-integration`).
Expand known abbreviations in the topic to make the branch name descriptive:

| Abbreviation | Expansion |
|---|---|
| `stt` | `speech-to-text` |

Create and switch to a new branch:

```bash
git checkout -b <expanded-topic> master
```

### 5. Build-verify loop

Repeat until verify passes:

**Build phase:**
Read `.shared/agent/skills/build/SKILL.md` and follow its instructions to implement the handoff. After implementation, commit to the branch.

**Verify phase:**
Read `.shared/agent/skills/verify/SKILL.md` and follow its instructions to verify the handoff.

If the verification output contains `RESULT: FAIL`, identify the specific failures and go back to the Build phase.
If `RESULT: PASS`, exit the loop.

### 6. Retrospect
Read `.shared/agent/skills/retrospect/SKILL.md` and follow its instructions.

### 7. Report
Tell the user:

```
Build-test loop completed successfully.
Branch: <expanded-topic>
Run `merge` to squash and merge to master.
```
