-- Eden Switch emulator: games open in a full-width column. Eden runs under
-- XWayland by default (its AppImage hook forces QT_QPA_PLATFORM=xcb), where
-- the class is "eden"; with I_WANT_A_BROKEN_WAYLAND_UI=1 the Wayland app id
-- "dev.eden_emu.eden" is used instead.
o.window("eden|dev\\.eden_emu\\.eden", { scrolling_width = 1.0 })
