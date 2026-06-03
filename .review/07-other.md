# Other Tools — Review Findings

## 🟢 Remaining — Low severity

### Waybar unused `custom/expand-icon` module

**File:** `waybar/.config/waybar/config.jsonc:142-149`

Module defined but never referenced in any `modules-*` list. Dead config.

---

### Niri Alt+Shift+Tab does same thing as Alt+Tab

**File:** `niri/.config/niri/config.kdl:422-423`

Both `focus-window-previous`. Not a bug — Niri has no native reverse-cycle action, but if the expectation is "go backwards" in history, it won't work that way.
