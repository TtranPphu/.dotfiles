local plugins = {
  { src = 'https://github.com/romgrk/barbar.nvim', version = vim.version.range '*' },
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
}

vim.pack.add(plugins)

vim.g.barbar_auto_setup = false

require('barbar').setup {
  opts = {
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
  },
}
