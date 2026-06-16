---
name: dont-dismiss-issues
description: "Don't dismiss user-reported issues as \"not from our changes\" — fix the problem regardless of source"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d906c416-4f56-4b39-9205-31510c0323aa
---

When a user reports a bug, do not say "that's not from our changes" or dismiss it. Fix the issue regardless of where it originates. The user's experience is what matters, not whose code caused it.

**Why:** The user asked for this clearly when they interrupted and corrected this behavior. Dismissing issues wastes time and frustrates the user.

**How to apply:** When a bug is reported, investigate and fix it. If it turns out to be a pre-existing issue in a different part of the codebase, fix it anyway. Only say it's not from your changes if you've already verified the root cause AND fixed it, as context — never as dismissal.
