return {
  vim.keymap.set('n', 'T', function()
    vim.cmd ':80vsplit | term'
    vim.cmd 'startinsert!'
  end, { desc = 'Open [T]erminal (vertical)' }),
  vim.keymap.set('n', 't', function()
    vim.cmd ':24split | term'
    vim.cmd 'startinsert!'
  end, { desc = 'Open [T]erminal (horizontal)' }),
}
