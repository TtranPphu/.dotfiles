# Remote Desktop

## Direct path (todo, router)

Both peers are behind symmetric NAT (`MappingVariesByDestIP: true`), so Tailscale
currently relays through `DERP(sin)` at about 86 ms RTT and reports "direct
connection not established". One reachable side is enough for a direct path. On
the omarchy-iv router:

- Forward UDP `41641` to `192.168.100.162:41641` (omarchy-iv's LAN address;
  Tailscale listens on UDP 41641 there).
- Public IPv4 at the time of writing: `42.118.190.13`.
- Verify with `tailscale ping omarchy-iv`; expect a direct address instead of
  `via DERP(sin)`.

The LAN and public addresses are DHCP values; re-check them with
`tailscale netcheck` on omarchy-iv before changing the forward.

## Current path

- wayvnc on omarchy-iv serves a Hyprland headless output over Tailscale
  (`HEADLESS-*`, 640x480, `--max-fps=60`).
- Remmina in WSL connects to `omarchy-iv:5900` with `quality=0`, `colordepth=32`.
