# Add CLI mistake context to general role

## Change

Add a rule to **`aichat/.config/aichat/roles/general.md`** so aichat knows
input may contain CLI typos and should just hint the correct command.

## File

`aichat/.config/aichat/roles/general.md` — add one rule:

```
- The user may have typed a CLI command with typos or wrong casing. If so, just hint the correct command.
```

## Verification

1. Type `gti status` → hint `git status`, not define "gti"
2. Type `sl` → hint `ls`
3. Normal queries like `list my files` still work as before
