-- Eden Switch emulator: games open in a full-width column. The nightly
-- wrapper (I_WANT_A_BROKEN_WAYLAND_UI=1, QT_QPA_PLATFORM=wayland) runs native
-- Wayland with app id "dev.eden_emu.eden"; it only falls back to X11/class
-- "eden" if the AppImage hook is used.
o.window("eden|dev\\.eden_emu\\.eden", { scrolling_width = 1.0 })
