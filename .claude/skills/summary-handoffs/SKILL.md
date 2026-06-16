---
name: summary-handoffs
description: Read handoffs and related code/configs, produce a concise self-contained summary, and archive it
user-invocable: true
argument-hint: <topic>
allowed-tools: [Read, Write, Bash, Grep]
---

Use this skill to consolidate handoffs into a single archival document. After the archive is written, the original handoffs can be deleted.

## Workflow

1. **Find handoffs** — Search `.shared/agent/handoffs/` for handoffs matching the topic (by name match or keyword match against content). Match against both the `NN-topic` filename and the `# Title`.
2. **Read handoffs** — Read all matching handoffs in full.
3. **Read referenced files** — For each handoff, read the current state of the files it references (configs, scripts, etc.) so the archive reflects what's actually on disk, not just planned changes.
4. **Produce archive** — Write to `.shared/agent/handoffs/archive/<topic>.md` with this structure:

   ```
   # <Topic>

   ## Summary
   <2-4 sentences: what was done, architecture decisions, key files affected>

   ## Files
   <bullet list of all files involved, with one-line purpose>

   ## Key decisions
   <brief bullet list of architectural or design decisions made>

   ## Future iteration notes
   <bullet list of what's left, edge cases, or potential improvements>
   ```

5. **Report** — Tell the user the archive is written and suggest they can delete the original handoffs.

## Format rules

- Keep the archive concise — under 40 lines total. It will be consulted frequently.
- Use repo-relative paths.
- Absolute paths borrow `$HOME` from the environment, don't hardcode a username.
- If no handoffs match the topic, report that and list available handoffs.
