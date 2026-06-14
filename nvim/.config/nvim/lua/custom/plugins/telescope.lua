-- Match Telescope background to the normal editor background.
-- Some colorschemes (like Tokyonight) set Telescope-specific backgrounds
-- that differ from the main Normal background.
--
-- The fix runs immediately (since this file loads after the colorscheme)
-- and also hooks ColorScheme for future theme changes.
local api = vim.api

local function fix_telescope_bg()
  local normal_bg = api.nvim_get_hl(0, { name = 'Normal' }).bg
  if not normal_bg then
    return
  end

  local groups = {
    'TelescopeNormal',
    'TelescopePromptNormal',
    'TelescopeResultsNormal',
    'TelescopePreviewNormal',
    'TelescopeBorder',
    'TelescopePromptBorder',
    'TelescopeResultsBorder',
    'TelescopePreviewBorder',
    'TelescopePromptTitle',
    'TelescopeResultsTitle',
    'TelescopePreviewTitle',
  }

  for _, group in ipairs(groups) do
    local hl = api.nvim_get_hl(0, { name = group })
    hl.bg = normal_bg
    api.nvim_set_hl(0, group, hl)
  end
end

-- Run immediately (colorscheme already applied before this file loads)
fix_telescope_bg()

-- Also re-apply on future colorscheme changes
api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = fix_telescope_bg,
})
