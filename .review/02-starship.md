# Starship — Review Findings

## 🟢 Remaining — Low severity

### Module invisible on first prompt (cold cache)

**File:** `starship/.config/starship/deepseek-balance.sh:43-44`

```bash
refresh_cache &>/dev/null &
exit 1
```

When no cache file exists, spawns background refresh and exits 1. Starship suppresses the module on exit 1, so balance only appears on the **second** prompt.

---

### Inconsistent shebang

**File:** `starship/.config/starship/deepseek-balance.sh:1`

Uses `#!/bin/bash`. Battery scripts use `#!/usr/bin/env bash`. Inconsistent.
