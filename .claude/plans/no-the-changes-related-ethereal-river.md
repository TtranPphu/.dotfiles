# Fix fzf widget popup display

## Context

The fzf git branch/commit picker widgets (Ctrl+B, Ctrl+G) stopped showing popups after the refactor commit 92068cd. The working version is 993ee4a.

The diff between 993ee4a and 92068cd shows the refactor introduced literal single quotes around `'down:40%,wrap'` in `FZF_DEFAULT_OPTS`. In the original, it was `--preview-window down:40%,wrap` (no quotes inside the double-quoted string). Since `FZF_DEFAULT_OPTS` is a double-quoted zsh string, the `'down:40%,wrap'` contains literal quote characters that fzf's option parser sees as part of the token rather than as shell delimiters.

## Fix

In `zsh/.config/zsh/fzf.zsh`, remove the literal single quotes around the `--preview-window` value in `FZF_DEFAULT_OPTS`:

**Line 41 (current):**
```
    --preview-window 'down:40%,wrap' \
```
**Change to:**
```
    --preview-window down:40%,wrap \
```

That's the only change needed — the single quotes on other options (`--wrap-sign=''`, `--ellipsis='··'`, `--preview-wrap-sign=''`, `--bind '...'`) are harmless because those values don't contain commas that would be affected, and they'll continue to work as before.

## Verification

1. Source the file: `source ~/.config/zsh/fzf.zsh`
2. Test Ctrl+B in a git repo — should show fzf popup with branch list
3. Test Ctrl+G — should show fzf popup with commit list
4. Test Ctrl+F / Ctrl+R / tab completion — should still work (these use FZF_DEFAULT_OPTS)
