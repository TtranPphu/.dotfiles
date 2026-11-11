-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

-- Per-output scales. scripts/monitor-scale edits these constants; one variable
-- per output so each display scales independently.
local scale_eDP_2 = 2
local scale_HDMI_A_1 = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Positions are derived from the physical modes and each output's own scale, so
-- the laptop panel sits left of the ultrawide with their edges touching and the
-- ultrawide vertically centred against it.
-- Physical modes: eDP-2 2560x1600, HDMI-A-1 3440x1440.
local function round(value)
  return math.floor(value + 0.5)
end

local laptop_width = round(2560 / scale_eDP_2)
local laptop_height = round(1600 / scale_eDP_2)
local ultrawide_height = round(1440 / scale_HDMI_A_1)
local hdmi_x = laptop_width
local hdmi_y = round((laptop_height - ultrawide_height) / 2)

-- Pinned to 0x0 so the laptop panel sits left of the ultrawide, edges touching.
hl.monitor({ output = "eDP-2", mode = "preferred", position = "0x0", scale = scale_eDP_2 })

-- Specific rule for the LG ultrawide external, after the catch-all.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = hdmi_x .. "x" .. hdmi_y, scale = scale_HDMI_A_1 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
