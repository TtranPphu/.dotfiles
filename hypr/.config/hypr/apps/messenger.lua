-- Facebook Messenger web app rule. Mirrors the Telegram rule: keep it fully
-- opaque, floating, centred, 450x650, and inhibit idle while fullscreen.
o.window("chrome-www.messenger.com__-Default", {
  tag = "-default-opacity",
  opacity = "1 1",
  float = true,
  center = true,
  idle_inhibit = "fullscreen",
  size = { 450, 650 },
})
