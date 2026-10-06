-- Default colorscheme for machines without an Omarchy theme; omarchy-theme.lua
-- applies the staged Omarchy theme instead when one is available.
local omarchy_spec = vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua'
if vim.fn.filereadable(omarchy_spec) == 0 then
  vim.pack.add { { src = 'https://github.com/sainnhe/everforest' } }
  vim.g.everforest_disable_italic_comment = 1
  vim.cmd.colorscheme 'everforest'
end
