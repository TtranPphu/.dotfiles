-- WezTerm config mirroring the Ghostty setup.
-- Linux reads the current Omarchy theme; Windows falls back to Everforest,
-- uses PowerShell and keeps a normal titlebar.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find 'windows' ~= nil

-- Ghostty uses Hurmit Nerd Font at 9pt. Fall back to other Nerd Fonts and
-- then the platform defaults.
local font_fallback
if is_windows then
  font_fallback = {
    'Hurmit Nerd Font',
    'JetBrainsMono Nerd Font',
    'Cascadia Mono',
    'Consolas',
    'Segoe UI Emoji',
  }
else
  font_fallback = {
    'Hurmit Nerd Font',
    'JetBrainsMono Nerd Font',
    'Noto Color Emoji',
  }
end

config.font = wezterm.font_with_fallback(font_fallback)
config.font_size = 9.0

-- Window: Ghostty padding 2, no scrollbar, no scrollback, no close prompt.
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }
config.enable_scroll_bar = false
config.scrollback_lines = 0
config.window_close_confirmation = 'NeverPrompt'
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = is_windows and 'TITLE | RESIZE' or 'RESIZE'

-- Cursor: block, no blink.
config.default_cursor_style = 'SteadyBlock'
config.cursor_blink_rate = 0

-- Kitty graphics protocol. On by default in current builds; explicit here.
config.enable_kitty_graphics = true

-- Theme: Omarchy writes the current theme to ghostty.conf. Parse it on Linux;
-- on Windows (or if it is missing) use the Everforest palette.
local fallback_colors = {
  foreground = '#d3c6aa',
  background = '#2d353b',
  cursor_bg = '#d3c6aa',
  cursor_fg = '#2d353b',
  selection_bg = '#3d484d',
  selection_fg = '#d3c6aa',
  ansi = {
    '#2d353b', '#e67e80', '#a7c080', '#dbbc7f',
    '#7fbbb3', '#d699b6', '#83c092', '#d3c6aa',
  },
  brights = {
    '#475258', '#e67e80', '#a7c080', '#dbbc7f',
    '#7fbbb3', '#d699b6', '#83c092', '#d3c6aa',
  },
}

local function parse_ghostty_theme(path)
  local file = io.open(path, 'r')
  if not file then return nil end
  local colors = { ansi = {}, brights = {} }
  for line in file:lines() do
    local key, value = line:match '^%s*([%w%-_]+)%s*=%s*(#%x%x%x%x%x%x)'
    if key == 'background' then
      colors.background = value
    elseif key == 'foreground' then
      colors.foreground = value
    elseif key == 'cursor-color' then
      colors.cursor_bg = value
    elseif key == 'selection-background' then
      colors.selection_bg = value
    elseif key == 'selection-foreground' then
      colors.selection_fg = value
    end
    local index, color = line:match '^%s*palette%s*=%s*(%d+)%s*=%s*(#%x%x%x%x%x%x)'
    if index then
      index = tonumber(index)
      if index < 8 then
        colors.ansi[index + 1] = color
      else
        colors.brights[index - 7] = color
      end
    end
  end
  file:close()
  if not colors.background or not colors.foreground then return nil end
  if #colors.ansi < 8 or #colors.brights < 8 then return nil end
  colors.cursor_fg = colors.background
  if not colors.selection_fg then colors.selection_fg = colors.foreground end
  return colors
end

local theme = parse_ghostty_theme(
  wezterm.home_dir .. '/.local/state/omarchy/current/theme/ghostty.conf'
)
config.colors = theme or fallback_colors

-- Windows: PowerShell 7 when present, otherwise Windows PowerShell.
-- Linux keeps the login shell.
if is_windows then
  local function have(exe)
    local ok, success = pcall(wezterm.run_child_process, { 'where', exe })
    return ok and success
  end
  config.default_prog = have 'pwsh.exe'
    and { 'pwsh.exe', '-NoLogo' }
    or { 'powershell.exe', '-NoLogo' }
end

-- Ghostty keybindings.
config.keys = {
  { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom 'Clipboard' },
  { key = 'Insert', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
  { key = 'DownArrow', mods = 'SUPER|CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Down', 100 } },
  { key = 'UpArrow', mods = 'SUPER|CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Up', 100 } },
  { key = 'LeftArrow', mods = 'SUPER|CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Left', 100 } },
  { key = 'RightArrow', mods = 'SUPER|CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Right', 100 } },
}

-- Mouse: no app mouse reporting, no wheel, no links, no click-to-move.
-- Left drag selects (no copy on release), right click copies or pastes,
-- middle click pastes. Each event is registered for both mouse-reporting
-- states so applications cannot receive it when they request mouse tracking.
config.disable_default_mouse_bindings = true

local mouse = {}
local function bind(event, action, mods)
  for _, reporting in ipairs { false, true } do
    table.insert(mouse, {
      event = event,
      mods = mods or 'NONE',
      mouse_reporting = reporting,
      action = action,
    })
  end
end

local selection_modes = { 'Cell', 'Word', 'Line' }
for streak = 1, 3 do
  local mode = selection_modes[streak]
  bind({ Down = { streak = streak, button = 'Left' } }, act.SelectTextAtMouseCursor(mode))
  bind({ Drag = { streak = streak, button = 'Left' } }, act.ExtendSelectionToMouseCursor(mode))
  bind({ Up = { streak = streak, button = 'Left' } }, act.Nop)
  bind({ Down = { streak = streak, button = 'Left' } }, act.SelectTextAtMouseCursor(mode), 'SHIFT')
  bind({ Drag = { streak = streak, button = 'Left' } }, act.ExtendSelectionToMouseCursor(mode), 'SHIFT')
  bind({ Up = { streak = streak, button = 'Left' } }, act.Nop, 'SHIFT')
  for _, mods in ipairs { 'CTRL', 'ALT', 'SUPER' } do
    bind({ Down = { streak = streak, button = 'Left' } }, act.Nop, mods)
    bind({ Drag = { streak = streak, button = 'Left' } }, act.Nop, mods)
    bind({ Up = { streak = streak, button = 'Left' } }, act.Nop, mods)
  end
end

local copy_or_paste = wezterm.action_callback(function(window, pane)
  local selection = window:get_selection_text_for_pane(pane)
  if selection and selection ~= '' then
    window:perform_action(act.CopyTo 'Clipboard', pane)
    window:perform_action(act.ClearSelection, pane)
  else
    window:perform_action(act.PasteFrom 'Clipboard', pane)
  end
end)

bind({ Down = { streak = 1, button = 'Right' } }, copy_or_paste)
bind({ Up = { streak = 1, button = 'Right' } }, act.Nop)
for _, mods in ipairs { 'SHIFT', 'CTRL', 'ALT', 'SUPER' } do
  bind({ Down = { streak = 1, button = 'Right' } }, act.Nop, mods)
  bind({ Up = { streak = 1, button = 'Right' } }, act.Nop, mods)
end

local paste_target = is_windows and 'Clipboard' or 'PrimarySelection'
bind({ Down = { streak = 1, button = 'Middle' } }, act.PasteFrom(paste_target))
bind({ Up = { streak = 1, button = 'Middle' } }, act.Nop)
for _, mods in ipairs { 'SHIFT', 'CTRL', 'ALT', 'SUPER' } do
  bind({ Down = { streak = 1, button = 'Middle' } }, act.Nop, mods)
  bind({ Up = { streak = 1, button = 'Middle' } }, act.Nop, mods)
end

for _, button in ipairs { 'WheelUp', 'WheelDown', 'WheelLeft', 'WheelRight' } do
  for _, mods in ipairs { 'NONE', 'SHIFT', 'CTRL', 'ALT', 'SUPER' } do
    bind({ Down = { streak = 1, button = { [button] = 1 } } }, act.Nop, mods)
  end
end

config.mouse_bindings = mouse

return config
