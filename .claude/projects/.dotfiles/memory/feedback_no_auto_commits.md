---
name: no-auto-commits
description: Never create git commits unless explicitly asked by the user.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec2ada90-84b8-45c0-8545-da4ceb11711a
---

Never create git commits unless explicitly asked. The user had a commit skill auto-trigger and rejected it — this applies across all contexts.

**Why:** The user manages their own commit workflow and commits when they're ready. Auto-committing interrupts their flow and has caused friction.

**How to apply:** Never stage, commit, or call the commit skill unless the user explicitly says "commit", "make a commit", or asks you to save changes to git.
