return {
  vim.keymap.set('n', 'T', function()
    vim.cmd ':24split | term btop'
    vim.cmd 'startinsert!'
    vim.cmd ':vsplit | term gdu'
    vim.cmd 'startinsert!'
  end, { desc = 'Open [T]erminal (full)' }),
  vim.keymap.set('n', 't', function()
    vim.cmd ':24split | term'
    vim.cmd 'startinsert!'
  end, { desc = 'Open [T]erminal (split)' }),
}
