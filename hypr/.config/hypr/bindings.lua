-- Personal keybinding overrides, loaded after Omarchy's defaults.
-- See current bindings: omarchy menu keybindings --print

-- Unbind Omarchy defaults that this keymap replaces or drops.
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + ALT + SPACE")
hl.unbind("SUPER + ALT + K")
hl.unbind("SUPER + CTRL + K")
hl.unbind("SUPER + CTRL + BACKSPACE")
hl.unbind("SUPER + CTRL + DELETE")
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + ALT + RETURN")
hl.unbind("SUPER + CTRL + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
hl.unbind("SUPER + mouse:272")
hl.unbind("SUPER + mouse:273")
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
hl.unbind("SUPER + W")
hl.unbind("SUPER + A")
hl.unbind("SUPER + S")
hl.unbind("SUPER + D")
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SHIFT + W")
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + S")
hl.unbind("SUPER + SHIFT + D")
hl.unbind("SUPER + SHIFT + H")
hl.unbind("SUPER + SHIFT + J")
hl.unbind("SUPER + SHIFT + K")
hl.unbind("SUPER + SHIFT + L")
hl.unbind("SUPER + SHIFT + N")
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + SLASH")
hl.unbind("SUPER + code:20")
hl.unbind("SUPER + code:21")
hl.unbind("SUPER + ALT + code:20")
hl.unbind("SUPER + ALT + code:21")
hl.unbind("SUPER + CTRL + code:20")
hl.unbind("SUPER + CTRL + code:21")
hl.unbind("SUPER + SHIFT + code:20")
hl.unbind("SUPER + SHIFT + code:21")
hl.unbind("SUPER + SHIFT + ALT + code:20")
hl.unbind("SUPER + SHIFT + ALT + code:21")
hl.unbind("SUPER + CTRL + SHIFT + code:20")
hl.unbind("SUPER + CTRL + SHIFT + code:21")

-- Menus
o.bind("SUPER + SPACE", "Launch apps", "omarchy-menu toggle apps")
o.bind("SUPER + ALT + SPACE", "Omarchy menu", "omarchy-menu")

-- Focus
o.bind("SUPER + A", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + D", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + J", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + K", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Workspaces
o.bind("SUPER + H", "Workspace previous", hl.dsp.focus({ workspace = "-1" }))
o.bind("SUPER + L", "Workspace next", hl.dsp.focus({ workspace = "+1" }))
o.bind("SUPER + W", "Workspace next", hl.dsp.focus({ workspace = "+1" }))
o.bind("SUPER + S", "Workspace previous", hl.dsp.focus({ workspace = "-1" }))

-- Swap windows
o.bind("SUPER + SHIFT + A", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + D", "Swap window right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + J", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + K", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Move window to workspace
o.bind("SUPER + SHIFT + H", "Move window to previous workspace", hl.dsp.window.move({ workspace = "-1" }))
o.bind("SUPER + SHIFT + L", "Move window to next workspace", hl.dsp.window.move({ workspace = "+1" }))
o.bind("SUPER + SHIFT + W", "Move window to next workspace", hl.dsp.window.move({ workspace = "+1" }))
o.bind("SUPER + SHIFT + S", "Move window to previous workspace", hl.dsp.window.move({ workspace = "-1" }))

-- Windows and layout
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + SEMICOLON", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + BACKSLASH", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + SLASH", "Show key bindings", "omarchy-menu-keybindings")
o.bind("SUPER + mouse:273", "Move window", hl.dsp.window.drag(), { mouse = true })

-- Resize the focused window about its centre. In the scrolling layout the
-- x-axis keys change the focused column's width and re-centre it, so a
-- floating window (which has no column) gets its own path. Hyprland's own
-- relative resize rounds the half-delta on every step, which walks the centre
-- by a pixel on odd steps, so for a float the goal rect is set exactly: resize
-- to the new size, then move to the half-delta-shifted position. On a float
-- the plain/ALT/CTRL chords resize both dimensions at once; on a tiled column
-- they stay width-only and the SHIFT chords stay Omarchy's relative y resize.
-- Values keep the old magnitudes: ±100 plain, ±25 ALT, ±300 CTRL; colresize
-- takes fractions of the monitor's width (100px / 1280px = 0.078125).
local function half(step)
  -- Truncated, so shrink then expand returns to the exact original rect.
  return step < 0 and -math.floor(-step / 2) or math.floor(step / 2)
end

local function resize(step_x, step_y, column_fraction)
  return function()
    local window = hl.get_active_window()
    if column_fraction and (not window or not window.floating) then
      return hl.dispatch(hl.dsp.layout("colresize " .. column_fraction))
    end
    if not window or not window.floating then
      return hl.dispatch(hl.dsp.window.resize({ x = step_x, y = step_y, relative = true }))
    end

    local size_x, size_y = window.size.x + step_x, window.size.y + step_y
    if size_x < 1 or size_y < 1 then
      return
    end
    local position_x, position_y = window.at.x - half(step_x), window.at.y - half(step_y)

    hl.dispatch(hl.dsp.window.resize({ x = size_x, y = size_y }))
    return hl.dispatch(hl.dsp.window.move({ x = position_x, y = position_y }))
  end
end

o.bind("SUPER + code:20", "Shrink window", resize(-100, -100, "-0.078125"))
o.bind("SUPER + code:21", "Expand window", resize(100, 100, "+0.078125"))
o.bind("SUPER + ALT + code:20", "Shrink window a little", resize(-25, -25, "-0.01953125"))
o.bind("SUPER + ALT + code:21", "Expand window a little", resize(25, 25, "+0.01953125"))
o.bind("SUPER + CTRL + code:20", "Shrink window a lot", resize(-300, -300, "-0.234375"))
o.bind("SUPER + CTRL + code:21", "Expand window a lot", resize(300, 300, "+0.234375"))

o.bind("SUPER + SHIFT + code:20", "Shrink window up", resize(0, -100))
o.bind("SUPER + SHIFT + code:21", "Expand window down", resize(0, 100))
o.bind("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", resize(0, -25))
o.bind("SUPER + SHIFT + ALT + code:21", "Expand window down a little", resize(0, 25))
o.bind("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", resize(0, -300))
o.bind("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", resize(0, 300))

-- Displays
-- Replaces Omarchy's laptop-display toggle; enables every display even when
-- the screen is blank (see the script for details).
o.bind("SUPER + CTRL + DELETE", "Enable all displays", os.getenv("HOME") .. "/.config/hypr/scripts/enable-all-displays")

-- Apps
o.bind("SUPER + SHIFT + T", "Terminal", "omarchy-launch-or-focus ghostty")
o.bind("SUPER + SHIFT + Z", "Zsh", 'uwsm-app -- ghostty --command="/usr/bin/zsh --login"')
o.bind("SUPER + SHIFT + M", "Telegram", "uwsm-app -- Telegram")
