-- Smart split that chooses horizontal or vertical based on window dimensions
local function auto_split()
  local win_width = vim.fn.winwidth(0)
  local win_height = vim.fn.winheight(0)
  local threshold = win_height * 2

  if win_width > threshold then
    -- Wide window: split vertically (left-right / side by side)
    vim.cmd 'vsplit'
    vim.notify(
      string.format('Vertical split (width %d > height*2 %d)', win_width, threshold),
      vim.log.levels.INFO
    )
  else
    -- Tall or square window: split horizontally (top-bottom / stacked)
    vim.cmd 'split'
    vim.notify(
      string.format('Horizontal split (width %d ≤ height*2 %d)', win_width, threshold),
      vim.log.levels.INFO
    )
  end
end

-- Map ss to auto-split
vim.keymap.set('n', 'ss', auto_split, { silent = true, desc = 'Auto split window' })
