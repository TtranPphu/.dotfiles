local plugins = {
  { src = 'https://github.com/romgrk/barbar.nvim', version = vim.version.range '*' },
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
}

vim.pack.add(plugins)

require('barbar').setup {
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  opts = {
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
  },
  version = '^1.0.0',
}
