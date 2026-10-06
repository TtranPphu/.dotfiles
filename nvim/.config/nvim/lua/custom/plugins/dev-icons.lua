-- Upstream init.lua only mocks nvim-web-devicons via mini.icons; this config
-- uses the real plugin (e.g. for telescope), so install it here.
vim.pack.add { 'https://github.com/nvim-tree/nvim-web-devicons' }

local devicons = require('nvim-web-devicons')

local icons = devicons.get_icons()
local ext_icons = devicons.get_icons_by_extension()

local overrides = {
  css = '',
  yaml = '',
  yml = '',
}

for ext, icon in pairs(overrides) do
  if icons[ext] then icons[ext].icon = icon end
  if ext_icons[ext] then ext_icons[ext].icon = icon end
end

devicons.set_up_highlights(true)
