-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Laptop panel runs at 2; specific rules come after the catch-all.
-- Pinned to 0x0 so the ultrawide's -435 x-offset centres over it.
hl.monitor({ output = "eDP-2", mode = "preferred", position = "0x0", scale = 2 })

-- Specific rule for the LG ultrawide external, after the catch-all.
-- 3440/1.6 = 2150, 1440/1.6 = 900 logical; top-centre above the laptop panel
-- (2560/2 = 1280 wide): x = (1280 - 2150) / 2 = -435, y = 0 - 900 = -900.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", scale = 1.6, position = "-435x-900" })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
