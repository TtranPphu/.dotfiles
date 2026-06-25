---
name: verify
description: Verify a handoff's implementation against its Verification checklist.
user-invocable: true
argument-hint: <handoff-identifier>
allowed-tools: [Read, Bash, Grep, Glob]
---

## Instructions

### 1. Identify the handoff
If an argument is given, search `.shared/agent/handoffs/` for a file matching `*<argument>*`.
If no argument, list available handoffs and ask the user to pick one.

### 2. Read the handoff
Read the handoff file in full. Focus on the **Verification** section — each item describes an expected behavior or state to check.

### 3. Switch to the branch
Extract the topic from the handoff filename, expand abbreviations, and switch:

```bash
git switch <expanded-topic>
```

Abbreviation map:

| Abbreviation | Expansion |
|---|---|
| `stt` | `speech-to-text` |

### 4. Check each verification item
For each item in the Verification checklist:
- Examine the current state of files and the running system
- Report as `PASS` or `FAIL` with a brief explanation
- For FAIL items, describe exactly what is wrong and what needs to be fixed

### 5. Output final result
End with one of these lines:

```
RESULT: PASS
```

```
RESULT: FAIL
```
