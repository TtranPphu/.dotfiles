---
name: retrospect
description: Analyze a completed handoff, gather feedback, and improve skills for future loops.
user-invocable: true
argument-hint: <handoff-identifier>
allowed-tools: [Read, Write, Bash, Grep, Glob]
---

## Instructions

### 1. Identify the handoff
If an argument is given, search `.shared/agent/handoffs/` for a file matching `*<argument>*`.
If no argument, list available handoffs and ask the user to pick one.

### 2. Summarize what happened
Read the handoff. Check whether the branch still exists (`git branch --list <topic>`). Summarize:
- What was implemented
- Whether verification passed
- How many build iterations were needed

### 3. Ask for feedback
Ask the user:

```
Any feedback on how the build-verify process went?
- Was the handoff clear and complete?
- Did the build process miss anything?
- Did the verification catch all issues?
- Any suggestions for the skills themselves?
```

### 4. Apply feedback
If the user provides feedback:
- Identify which skill file(s) should be updated (e.g. `build/SKILL.md`, `verify/SKILL.md`, `handoff/SKILL.md`)
- Read the current skill file
- Edit it to incorporate the feedback
- Report what was changed and why

### 5. Archive the handoff
Ask the user if they want to archive this handoff.
If yes, follow the archiving procedure from `.shared/agent/skills/handoff/SKILL.md` (find next A<NN>, write archive, delete original).

### 6. Report
Summarize what feedback was received, what skills were updated, and the final handoff status.
