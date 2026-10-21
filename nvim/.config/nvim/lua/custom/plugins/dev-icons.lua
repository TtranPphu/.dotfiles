-- Upstream init.lua only mocks nvim-web-devicons via mini.icons; this config
-- uses the real plugin (e.g. for telescope), so install it here.
--
-- Follow the per-client font type (nerd|mono|lame) from the same resolver the
-- tmux/starship renderers use. Clients without a Nerd Font (lame) get
-- mini.icons' ASCII fallback so plugins show text icons instead of tofu.
-- A failing resolver (e.g. missing script) falls back to the Nerd Font path.
local ok, out = pcall(vim.fn.system, { vim.fn.expand '~/.config/zsh/icon.sh', 'type' })
local font_type = ok and vim.v.shell_error == 0 and vim.trim(out) or 'nerd'

if font_type == 'lame' then
  -- Plugins loaded earlier (e.g. barbar) may already hold a reference to the
  -- real module table; mirror the mock into it so they render ASCII too.
  local prior = package.loaded['nvim-web-devicons']
  require('mini.icons').setup { style = 'ascii' }
  require('mini.icons').mock_nvim_web_devicons()
  if prior then
    for k, v in pairs(package.loaded['nvim-web-devicons']) do prior[k] = v end
  end
  return
end

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
