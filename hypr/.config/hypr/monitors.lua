-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- The panels share omarchy_monitor_scale (the scaling widget drives it), so the
-- ultrawide's top-centre anchor is recomputed from the scale on every reload.
-- Physical modes: eDP-2 2560x1600, HDMI-A-1 3440x1440.
local function round(value)
  return math.floor(value + 0.5)
end

local laptop_width = round(2560 / omarchy_monitor_scale)
local ultrawide_width = round(3440 / omarchy_monitor_scale)
local ultrawide_height = round(1440 / omarchy_monitor_scale)
local ultrawide_x = round((laptop_width - ultrawide_width) / 2)
local ultrawide_y = -ultrawide_height

-- Pinned to 0x0 so the ultrawide sits top-centre above it, edges touching.
hl.monitor({ output = "eDP-2", mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })

-- Specific rule for the LG ultrawide external, after the catch-all.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = ultrawide_x .. "x" .. ultrawide_y, scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
