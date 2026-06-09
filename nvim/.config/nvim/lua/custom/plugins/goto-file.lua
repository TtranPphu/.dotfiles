-- Enhanced gf/gF that expands environment variables in file paths.
--
-- Built-in gf treats $HOME, $XDG_CONFIG_HOME, etc. as literal directory
-- names. This replacement expands $VAR, ${VAR}, and ~ before opening.

local function expand_path(path)
  if path == '' then return nil end

  -- Expand $VAR and ${VAR}
  path = path:gsub('%$%{([%w_]+)%}', function(var)
    return os.getenv(var) or vim.fn.environ()[var] or '$' .. '{' .. var .. '}'
  end)
  path = path:gsub('%$([%w_]+)', function(var)
    return os.getenv(var) or vim.fn.environ()[var] or '$' .. var
  end)
  -- Expand ~ to home directory
  path = path:gsub('^~', os.getenv 'HOME')

  return path
end

---@param path string
---@return string fnameescaped path
local function esc(path)
  return vim.fn.fnameescape(path)
end

local function goto_file()
  local file = vim.fn.expand '<cfile>'
  local expanded = expand_path(file)
  if not expanded then return end
  vim.cmd.edit(esc(expanded))
end

local function goto_file_split()
  local file = vim.fn.expand '<cfile>'
  local expanded = expand_path(file)
  if not expanded then return end
  vim.cmd.split(esc(expanded))
end

local function goto_file_vsplit()
  local file = vim.fn.expand '<cfile>'
  local expanded = expand_path(file)
  if not expanded then return end
  vim.cmd.vsplit(esc(expanded))
end

local function goto_file_tab()
  local file = vim.fn.expand '<cfile>'
  local expanded = expand_path(file)
  if not expanded then return end
  vim.cmd.tabedit(esc(expanded))
end

-- gF: open file and jump to line number (e.g. /path/file.txt:42 or file.txt|42)
local function goto_file_with_line()
  local raw = vim.fn.expand '<cfile>'
  if raw == '' then return end

  -- gF uses the full text including the line number suffix,
  -- so we need to grab the raw word before expand() truncates it.
  -- Get the whole line and extract the file:line portion manually.
  local line = vim.fn.getline '.'
  local col = vim.fn.col '.'
  local rest = line:sub(col)

  -- Try to find file:line or file|line at the cursor position
  local filepath, linenum = rest:match '^(%S+)[: |](%d+)'
  if filepath then
    filepath = expand_path(filepath)
    if not filepath then return end
    vim.cmd.edit(esc(filepath))
    vim.cmd('+' .. linenum)
  else
    -- Fall back to regular gf behavior
    goto_file()
  end
end

vim.keymap.set('n', 'gf', goto_file, { desc = 'Go to file (expand env vars)' })
vim.keymap.set('n', 'gF', goto_file_with_line, { desc = 'Go to file with line (expand env vars)' })
vim.keymap.set('n', '<C-w>f', goto_file_split, { desc = 'Go to file in split (expand env vars)' })
vim.keymap.set('n', '<C-w><C-f>', goto_file_split, { desc = 'Go to file in split (expand env vars)' })
vim.keymap.set('n', '<C-w>F', goto_file_vsplit, { desc = 'Go to file in vsplit (expand env vars)' })
vim.keymap.set('n', '<C-w>gf', goto_file_tab, { desc = 'Go to file in tab (expand env vars)' })
vim.keymap.set('n', '<C-w><C-gf>', goto_file_tab, { desc = 'Go to file in tab (expand env vars)' })
