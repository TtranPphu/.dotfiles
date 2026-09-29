-- Telegram app rule. Mirrors the legacy hypr apps/telegram.conf: keep it fully
-- opaque, floating, centred, 450x650, and inhibit idle while fullscreen.
o.window("org.telegram.desktop", {
  tag = "-default-opacity",
  opacity = "1 1",
  float = true,
  center = true,
  idle_inhibit = "fullscreen",
  size = { 450, 650 },
})
