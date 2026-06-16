---
name: respect-user-changes
description: Always preserve user modifications to files — never overwrite their changes during the session.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec2ada90-84b8-45c0-8545-da4ceb11711a
---

Always preserve any changes the user makes to files during the session. Never overwrite their edits with my own.

**Why:** The user has had their modifications overridden multiple times in a single session, which is disruptive and wastes their work.

**How to apply:** Before editing a file, check if the user has made uncommitted changes. When reverting or checking out files, prefer targeted edits over full-file reverts. Read the current state before writing. If unsure, ask.
