# Hyprland — Review Findings

## 🟢 Remaining — Low severity

### GDK_SCALE toggle has no runtime effect

**File:** `hypr/.config/hypr/scripts/toggle-internal-display.sh:8,12`

```bash
hyprctl keyword env "GDK_SCALE,1.5"
hyprctl keyword env "GDK_SCALE,2"
```

Setting env vars via `hyprctl keyword env` at runtime does not apply to running processes and is unreliable for new ones. These lines are effectively dead code.

---

### Hard Omarchy dependencies

**File:** `hypr/.config/hypr/hyprland.conf:4-13`

10 files sourced from Omarchy paths — if Omarchy is not installed, all produce startup warnings. Intentional design choice.
