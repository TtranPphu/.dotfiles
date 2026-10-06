-- The root init.lua tracks upstream kickstart.nvim (minus the header art), and
-- upstream leaves the `require 'custom.plugins'` convenience loader commented
-- out.
-- plugin/ files are sourced automatically after init.lua, so load the custom
-- plugin directory from here instead.
--
-- `vim.g.have_nerd_font` is a local delta (upstream defaults to false). Set it
-- before custom plugins load so they see it, exactly as they did while the
-- assignment lived in init.lua.
vim.g.have_nerd_font = true
require 'custom.plugins'
