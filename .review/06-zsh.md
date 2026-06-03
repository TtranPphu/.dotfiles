# Zsh — Review Findings

## 🟢 Remaining — Low severity

### Dead function `_fzf_strip_history`

**File:** `zsh/.config/zsh/fzf.zsh:7-9`

```zsh
_fzf_strip_history() {
    echo "$1" | sed 's/^[0-9 ]*//'
}
```

Defined but never called. The stripping is done inline in `FZF_CTRL_R_OPTS`.

---

### `install.sh` dead logic in inner case

**File:** `zsh/.local/share/zsh/install.sh:150-154`

```bash
apt|dnf|pacman|zypper|apk)
    case "$tool" in
      hyprland|starship|bat|...) echo "$base_name" ;;
      *) echo "$base_name" ;;
    esac
```

Both branches return `$base_name`. The inner `case` is entirely redundant.

---

### `install.sh` uses GNU-only flags

**File:** `zsh/.local/share/zsh/install.sh` (various)

Uses `grep -oP` (GNU-only) and `sed -i` (needs backup arg on BSD). These are fallbacks when `jq` is unavailable. Fine on Linux.

---

### Install script errors hidden from user

**File:** `zsh/.zshrc:119-121`

```zsh
"$HOME/.local/share/zsh/install.sh" 2>/dev/null || true
```

`2>/dev/null` plus `|| true` makes installation failures invisible. Intentional for silent startup.
