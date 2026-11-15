-- The Quake console: a dimmed overlay that drops down over whatever workspace
-- you are on. It is its own special workspace, separate from the full-size
-- scratchpad on Super + S. Its bindings live in bindings/tiling.lua, and its
-- slide is animated below.
--
-- This replaces Omarchy's panel. omarchy.lua hardcodes the console to half the
-- usable height in a centered box and has no setting to change it, so rather
-- than fighting it from a module loaded afterwards, hyprland.lua marks
-- "default.hypr.qconsole" as loaded and the bundled module never runs. With no
-- panel math left, the console is just a workspace: dwindle fills the usable
-- area with one window and splits it evenly between several.

-- Dimming only applies while a special workspace is open, so the console gets
-- its separation from the workspace underneath without costing anything the
-- rest of the time.
hl.config({
  decoration = {
    dim_special = 0.6,
  },
})

-- No gaps: the console covers the whole usable area, below the bar. The layout
-- is named because a bare rule would fall back to the global one.
hl.workspace_rule({
  workspace = "special:qconsole",
  layout = "dwindle",
  gaps_in = 0,
  gaps_out = { top = 0, right = 0, bottom = 0, left = 0 },

  -- Nothing to highlight in a console that is only ever focused when it is
  -- open, and the active border reads as a stray frame around a panel that is
  -- already set apart by the dimming behind it.
  no_border = true,
})

-- The direction names the edge the offset is measured from, not where the
-- workspace goes: "slide top" drops it down into view, and "slide bottom"
-- retracts it back up the way a Quake console does.
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "slide bottom" })
