-- Change the default Omarchy look'n'feel.

hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 4,

    -- Change to niri-like side-scrolling layout.
    layout = "scrolling",
  },
})

hl.config({
  decoration = {
    rounding = 8,
  },
})

-- The Display widget's WIDTH selector persists its choice here; reading it back
-- makes the selection survive `hyprctl reload` (which re-runs this file and
-- would otherwise reset the width to the default).
local function remembered_column_width()
  local state_home = os.getenv("XDG_STATE_HOME")
  if state_home == nil or state_home == "" then
    state_home = (os.getenv("HOME") or "") .. "/.local/state"
  end

  local file = io.open(state_home .. "/omarchy/column-width", "r")
  if file == nil then return nil end

  local value = tonumber(file:read("*a"))
  file:close()
  if value == nil or value < 0.3 or value > 1 then return nil end
  return value
end

hl.config({
  scrolling = {
    -- Default column width (fraction of screen width), overridden by the
    -- Display widget's remembered choice when present.
    column_width = remembered_column_width() or 0.8,

    -- Keep a lone column at column_width instead of stretching it to full width.
    fullscreen_on_one_column = false,

    -- Center the focused column instead of only fitting it into view.
    -- 0 = center, 1 = fit.
    focus_fit_method = 0,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
