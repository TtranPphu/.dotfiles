-- PgUp/PgDn for half-page scroll (replace C-u/C-d)
vim.keymap.set('n', '<C-u>', '<Nop>')
vim.keymap.set('n', '<C-d>', '<Nop>')
vim.keymap.set('n', '<PageUp>', '<C-u>', { noremap = true, desc = 'Half-page up' })
vim.keymap.set('n', '<PageDown>', '<C-d>', { noremap = true, desc = 'Half-page down' })

-- Home/End for first/last non-space char
vim.keymap.set({ 'n', 'x' }, '<Home>', '^', { noremap = true, desc = 'First non-space' })
vim.keymap.set({ 'n', 'x' }, '<End>', 'g_', { noremap = true, desc = 'Last non-space' })

-- Toggle line wrap (window-local, <leader>tw is taken by gitsigns)
vim.keymap.set('n', '<leader>tW', function()
  vim.wo.wrap = not vim.wo.wrap
  print(vim.wo.wrap and 'Wrap: ON' or 'Wrap: OFF')
end, { desc = '[T]oggle [W]rap' })
