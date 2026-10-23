-- Inline color previews via mini.hipatterns: hex, xterm 256 and terminal names.

local hipatterns = require 'mini.hipatterns'

-- Classic xterm colors 0-15, used when the colorscheme does not define
-- `vim.g.terminal_color_N`.
local fallback = {
  '#000000',
  '#800000',
  '#008000',
  '#808000',
  '#000080',
  '#800080',
  '#008080',
  '#c0c0c0',
  '#808080',
  '#ff0000',
  '#00ff00',
  '#ffff00',
  '#0000ff',
  '#ff00ff',
  '#00ffff',
  '#ffffff',
}

local function index_to_hex(i)
  if i < 16 then return vim.g['terminal_color_' .. i] or fallback[i + 1] end
  if i < 232 then
    local n = i - 16
    local channels = { math.floor(n / 36), math.floor(n / 6) % 6, n % 6 }
    for k, v in ipairs(channels) do
      channels[k] = ('%02x'):format(v == 0 and 0 or 55 + 40 * v)
    end
    return '#' .. table.concat(channels)
  end
  local gray = ('%02x'):format(8 + 10 * (i - 232))
  return '#' .. gray .. gray .. gray
end

local function group_for_index(i)
  if not i or i < 0 or i > 255 then return nil end
  return hipatterns.compute_hex_color_group(index_to_hex(i), 'bg')
end

local xterm_group = function(_, match) return group_for_index(tonumber(match:match '^colour(%d+)$')) end

local names = {}
for i, name in ipairs { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' } do
  names[name] = i - 1
  names['bright' .. name] = i + 7
end

-- The catalog is also prose in other files, so only preview its names there.
local name_group = function(buf_id, match)
  if vim.fs.basename(vim.api.nvim_buf_get_name(buf_id)) ~= 'color.csv' then return nil end
  return group_for_index(names[match])
end

hipatterns.setup {
  highlighters = {
    hex = hipatterns.gen_highlighter.hex_color { style = 'bg' },
    xterm = { pattern = '%f[%w]()colour%d+%f[%W]()', group = xterm_group },
    names = { pattern = '%f[%a]()%a+()%f[%A]', group = name_group },
  },
}
