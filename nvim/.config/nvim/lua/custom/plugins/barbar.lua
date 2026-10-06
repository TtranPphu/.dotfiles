local plugins = {
  { src = 'https://github.com/romgrk/barbar.nvim', version = vim.version.range '*' },
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
}

-- Must be set before the plugin loads; vim.pack.add() loads it immediately
-- when called after init.lua.
vim.g.barbar_auto_setup = false

vim.pack.add(plugins)

require('barbar').setup {
  opts = {
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
  },
}
