# H06 - Tmux window navigation key triggers session switch popup

## Goal

Investigate and fix a spurious `M-s` (session switch fzf popup) trigger when
navigating between windows with `M-j`/`M-k`.

## Deliverables

1. Root-cause the phantom `M-s` activation.
2. Apply the fix — likely a key repeat / debounce config change, or a binding
   guard, or a keyboard hardware/software workaround.

## Key Findings

- `M-j`/`M-k` are bound to `select-window -t -1` / `select-window -t +1`
  (`bindings.conf:60-61`)
- `M-s` is bound to `run-shell -b '#{@tmux-control}/switch-session.sh'`
  (`bindings.conf:84`) — launches the fzf-tmux session picker popup
- The popup only appears **briefly and sporadically** during rapid window
  switching, suggesting a key repeat / keyboard matrix ghosting issue rather
  than a tmux config conflict
- The `s` key on QWERTY is adjacent to `j` — if the keyboard's key repeat
  or debounce is slow, releasing `j` while holding `M-` could register a
  brief `M-s` press

## Potential Issues

- **Keyboard hardware/software** — if using a mechanical keyboard with
  certain switches or a laptop keyboard, adjacent key release can cause
  ghost presses. Try `xev` or `wev` (Wayland) to monitor raw key events
- **Xorg key repeat** — `xset r rate <delay> <rate>` may help; check
  current settings with `xset q`
- **Wayland** — key repeat is managed by the compositor; check
  `hyprland.conf` for `repeat_rate` and `repeat_delay` settings
- **tmux workaround** — could add a small debounce delay or change `M-s`
  to a non-adjacent trigger like `M-S-s` (but that changes UX)
- **Simple test** — run `tmux display-message` on M-j/M-k instead of
  select-window to see if M-s still fires (isolate tmux from keyboard)

## Verification

- [ ] Reproduce the issue: rapid `M-j`/`M-k` presses while watching for
      the fzf popup
- [ ] Capture key events with `xev` / `wev` during reproduction to confirm
      `M-s` is being sent by the keyboard
- [ ] Adjust `repeat_rate` / `repeat_delay` and retest
- [ ] If keyboard-level fix works, document the new settings
- [ ] If not, implement a tmux-side guard and verify popup no longer appears
