-- No Rest for the Wicked (Steam 1371980) opens in windowed fullscreen:
-- compositor fullscreen (2) with the client left in windowed state (0), so
-- the game keeps running borderless instead of switching display modes.
o.window("steam_app_1371980", { fullscreen_state = "2 0" })
