local plugins = {
  { src = 'https://github.com/mcauley-penney/visual-whitespace.nvim' },
}

vim.pack.add(plugins)

require('visual-whitespace').setup {
  config = true,

  opts = {
    enabled = true,
    highlight = { link = 'visual', default = true },
    match_types = {
      space = true,
      tab = true,
      nbsp = true,
      lead = false,
      trail = false,
    },
    list_chars = {
      space = '·',
      tab = '↦',
      nbsp = '␣',
      lead = '‹',
      trail = '›',
    },
    fileformat_chars = {
      unix = '¬',
      mac = '¤',
      dos = '¤¬',
    },
    ignore = { filetypes = {}, buftypes = {} },
  },
}
