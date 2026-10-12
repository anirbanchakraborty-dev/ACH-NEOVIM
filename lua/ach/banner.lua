-- The ACH NEOVIM banner. Each letter is a five-by-seven grid (I is three
-- wide). A filled cell is drawn "██"; an empty cell whose upper-left
-- neighbour is filled gets the shadow "░░"; anything else is two spaces.
local M = {}

M.font = {
  A = { ".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
  C = { ".XXXX", "X....", "X....", "X....", "X....", "X....", ".XXXX" },
  E = { "XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX" },
  H = { "X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
  I = { "XXX", ".X.", ".X.", ".X.", ".X.", ".X.", "XXX" },
  M = { "X...X", "XX.XX", "X.X.X", "X...X", "X...X", "X...X", "X...X" },
  N = { "X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X" },
  O = { ".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX." },
  V = { "X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.." },
}

-- The word's seven rows of cells, letters separated by `gap` empty cells.
function M.grid(word, gap)
  local rows = {}
  for r = 1, 7 do
    local parts = {}
    for i = 1, #word do
      parts[#parts + 1] = M.font[word:sub(i, i)][r]
    end
    rows[r] = table.concat(parts, ("."):rep(gap or 2))
  end
  return rows
end

-- Eight lines: seven of letters and one of shadow. `indent` is in cells.
function M.render(word, indent)
  local g = M.grid(word)
  local cols = #g[1]
  local function filled(r, c) return r >= 1 and r <= 7 and c >= 1 and c <= cols and g[r]:sub(c, c) == "X" end
  local out = {}
  for r = 1, 8 do
    local cells = {}
    for c = 1, cols + 1 do
      cells[c] = filled(r, c) and "██" or (filled(r - 1, c - 1) and "░░" or "  ")
    end
    out[r] = (("  "):rep(indent or 0) .. table.concat(cells)):gsub("%s+$", "")
  end
  return out
end

-- ACH centred over NEOVIM, with one empty line between them.
function M.lines()
  local indent = math.floor((#M.grid("NEOVIM")[1] - #M.grid("ACH")[1]) / 2)
  local out = M.render("ACH", indent)
  out[#out + 1] = ""
  vim.list_extend(out, M.render("NEOVIM"))
  return out
end

function M.width(lines)
  local widest = 0
  for _, line in ipairs(lines) do
    widest = math.max(widest, vim.api.nvim_strwidth(line))
  end
  return widest
end

-- snacks.nvim text chunks: letters in AchBanner, shadow in AchBannerShadow,
-- spaces uncoloured. Every line is padded to the same width so snacks centres
-- the banner as one block, and each line after the first starts with "\n",
-- which is how a snacks text item breaks into rows.
function M.chunks(lines, width)
  width = width or M.width(lines)
  local colour = { ["█"] = "AchBanner", ["░"] = "AchBannerShadow" }
  local out = {}
  for i, line in ipairs(lines) do
    line = line .. (" "):rep(width - vim.api.nvim_strwidth(line))
    local run, group, first = "", false, true
    local function flush()
      if run ~= "" then
        out[#out + 1] = { (first and i > 1) and ("\n" .. run) or run, hl = group or nil }
        first = false
      end
    end
    for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
      local g = colour[ch] or false
      if g ~= group then
        flush()
        run, group = "", g
      end
      run = run .. ch
    end
    flush()
  end
  return out
end

return M
