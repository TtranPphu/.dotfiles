-- Floating command line (centered, rounded border)
-- Disables noice's own messages/notifications — fidget.nvim handles those.

vim.pack.add {
  'https://github.com/folke/noice.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

require('noice').setup({
  cmdline = {
    enabled = true,
    view = 'cmdline_popup',
    opts = {
      position = { row = '99%', col = '50%' },
      border = { style = 'none' },
      size = { width = '100%', height = 'auto' },
    },
    format = {
      cmdline = { icon = ':' },
      search_down = { icon = '/' },
      search_up = { icon = '?' },
    },
  },
  -- Disable features already handled by other plugins
  messages = { enabled = false },
  notify = { enabled = false },
  lsp = { progress = { enabled = false } },
  popupmenu = { enabled = false },
})
