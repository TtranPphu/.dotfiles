-- Local deltas that used to live in the root init.lua. init.lua now tracks
-- upstream kickstart.nvim (minus the header art), so they are applied here
-- instead (after init.lua's own setup calls have run).

-- `vim.g.have_nerd_font = true` is set in plugin/custom-plugins.lua before this
-- directory loads, but upstream's which-key and mini.statusline setups already
-- ran with the upstream default of `false` and cached it. Nudge both consumers.
require('which-key.config').options.icons.mappings = true
require('mini.statusline').config.use_icons = true

-- Editor options.
vim.o.relativenumber = true -- hybrid line numbers
vim.o.mouse = '' -- disable mouse

-- Global 2-space indentation; language overrides live in language-indent.lua.
vim.o.expandtab = true -- use spaces instead of tabs
vim.o.shiftwidth = 2 -- spaces per indent step
vim.o.softtabstop = 2 -- spaces per <Tab> while editing
vim.o.tabstop = 8 -- keep real tabs wide and visible

-- Route notifications through fidget.nvim.
vim.notify = require('fidget').notify
