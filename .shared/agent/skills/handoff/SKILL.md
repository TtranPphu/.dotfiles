---
name: handoff
description: Write or archive handoff documents for interrupted or deferred work. Use when work cannot be completed in a single session or when asked to summarize/archive handoffs.
user-invocable: true
argument-hint: <topic>
allowed-tools: [Read, Write, Bash, Grep]
---

Use this skill when you need to document in-progress work so another agent can pick it up later, or when asked to summarize and archive handoffs. A handoff captures what was discovered, what was decided, and what remains to be done.

## Where handoffs live

Active handoffs go in `.shared/agent/handoffs/H<NN>-<topic>.md`, archived ones in `.shared/agent/handoffs/archive/A<NN>-<topic>.md`. For handoffs, `<NN>` is the smallest 2-digit number (01, 02, ...) not already used in `.shared/agent/handoffs/`. For archives, `<NN>` is the smallest 2-digit number not already used in `.shared/agent/handoffs/archive/`. Check the *target* directory, not the source.

## When to write a handoff

- Work was scoped but not yet started (plan is done, implementation is pending)
- Implementation was partially completed and needs to be finished
- Complex findings were uncovered that shouldn't be lost
- A decision was made with rationale that future agents need to understand

## Structure

Every handoff should include these sections when applicable:

**Goal** — What the work aims to accomplish, in one paragraph.

**Deliverables** — Numbered list of files to create or modify, with paths, key content, and exact diffs. Be specific enough that an agent can implement without re-exploring.

**Deployment** — Commands to activate the changes (e.g., stow commands, symlinks, systemctl).

**Key Findings** — Architecture notes, configuration paths, and rationale for decisions made during exploration. This saves the next agent from re-discovering the same things.

**Potential Issues** — Gotchas, edge cases, and risks the next agent should watch for.

**Verification** — Numbered checklist to confirm the work is done correctly.

## Archiving handoffs

When asked to summarize or archive handoffs:

1. **Find handoffs** — Search `.shared/agent/handoffs/` for handoffs matching the topic (by name or keyword). Match against both the `NN-topic` filename and the `# Title`.
2. **Read handoffs** — Read all matching handoffs in full.
3. **Read referenced files** — For each handoff, read the current state of the files it references so the archive reflects what's actually on disk.
4. **Produce archive** — Write to `.shared/agent/handoffs/archive/A<NN>-<topic>.md` with this structure:

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

5. **Remove original** — Delete the original handoff file from `.shared/agent/handoffs/`.
6. **Report** — Tell the user the archive is written.

## Formatting rules

- Use repo-relative paths.
- Show exact diffs or code snippets with language hints.
- Use `**bold**` for file paths in prose.
- Link to any relevant skills, configs, or prior handoffs by path.
- Keep archives concise — under 40 lines total.
- If no handoffs match the topic, report that and list available handoffs.

## Reference

See the existing handoff at `.shared/agent/handoffs/H07-tmux-session-presets.md` for a complete example.
