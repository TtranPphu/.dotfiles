-- https://github.com/mcauley-penney/visual-whitespace.nvim

return {
  {
    'mcauley-penney/visual-whitespace.nvim',
    config = true,
    -- keys = { 'v', 'v', '<c-v>' }, -- optionally, lazy load on visual mode keys
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
  },
}
