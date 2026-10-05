# Tailscale Omarchy Widget (user clone)

Clone of the built-in `omarchy.tailscale` bar widget with tracked Taildrop
transfers: a progress bar and a cancel button on the machine being sent to.

Kept as `ttranpphu.tailscale` because the `omarchy.*` plugin id namespace is
reserved for built-ins; `omarchy.clonedFrom` lets the shell route the widget's
own `omarchy.tailscale` IPC target and settings calls to this clone.

## Features

- Shows Tailscale connection state in the bar
- Left click opens a keyboard-friendly panel
- Right click toggles Tailscale on/off
- Switch between available Tailscale connections when multiple are available
- Browse machines from `tailscale status --json`
- Copy a machine's Tailscale IP, host name, or DNS name
- Send files to a machine with Taildrop, when the tailnet allows file sharing
- Live per-machine transfer progress, with the byte counts read from the
  Tailscale IPN bus (`tailscale debug watch-ipn`, the only place tailscaled
  exposes `OutgoingFiles`; `tailscale file cp` itself prints no progress)
- Cancel a running transfer, killing only that transfer's `tailscale file cp`
- "not responding…" state while `tailscale file cp` retries a receiver that
  stopped reading the file

## Keyboard shortcuts

Inside the panel:

- `j` / `k` or arrows: move cursor
- `enter` / `space`: activate current row
- `c`: copy selected peer IP
- `n`: copy selected peer name
- `d`: copy selected peer DNS name
- `s`: send files to selected peer
- `x`: cancel the selected peer's running transfer
- `t`: toggle Tailscale
- `r`: refresh status
- `esc`: close

## Requirements

- `tailscale` CLI on `PATH`
- `wl-copy` for clipboard copy actions
- Taildrop enabled for the tailnet, to send files

## Sending files

`send.sh` is a copy of `omarchy-tailscale-send` that runs `tailscale file cp`
as a tracked child and prints its pid, so the widget can cancel exactly that
transfer. Notifications match the stock command: "Sent to <machine>" on
success, a critical "Could not send to <machine>" on failure, and a plain
"Cancelled sending to <machine>" when cancelled.

## Receiving files

Incoming Taildrop files are saved to `~/Downloads` by the
`omarchy-tailscale-receive` service, which announces each one with a
notification (an image preview when the file is an image, and a click to open
it). The Tailscale service install enables it; `omarchy tailscale receive`
runs the same loop by hand.

## Icon

Renders the Tailscale mark natively as a theme-colored 3×3 dot grid, matching the official SVG silhouette while avoiding tiny-SVG rendering quirks in the bar.

## Add to the bar

This clone replaces the built-in `omarchy.tailscale` entry in `shell.json`;
manage it like any other widget (`omarchy bar move ttranpphu.tailscale`).
