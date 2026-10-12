-- Starts Tree-sitter on a buffer: highlighting, indentation and the moves,
-- each only when the parser loads and the query that feature reads exists.
-- A file type with no parser, such as Snacks' "bigfile", gets nothing and
-- keeps Neovim's own syntax.
local M = {}

-- Moves between functions, classes and parameters, from
-- nvim-treesitter-textobjects. Each row is the key, the move, the query
-- capture and the description, which has a line in M.keys in icons.lua.
M.moves = {
  { "]f", "goto_next_start", "@function.outer", "Next Function Start" },
  { "]c", "goto_next_start", "@class.outer", "Next Class Start" },
  { "]a", "goto_next_start", "@parameter.inner", "Next Parameter Start" },
  { "]F", "goto_next_end", "@function.outer", "Next Function End" },
  { "]C", "goto_next_end", "@class.outer", "Next Class End" },
  { "]A", "goto_next_end", "@parameter.inner", "Next Parameter End" },
  { "[f", "goto_previous_start", "@function.outer", "Prev Function Start" },
  { "[c", "goto_previous_start", "@class.outer", "Prev Class Start" },
  { "[a", "goto_previous_start", "@parameter.inner", "Prev Parameter Start" },
  { "[F", "goto_previous_end", "@function.outer", "Prev Function End" },
  { "[C", "goto_previous_end", "@class.outer", "Prev Class End" },
  { "[A", "goto_previous_end", "@parameter.inner", "Prev Parameter End" },
}

-- Adds the table's own parsers, the ones nvim-treesitter does not carry, to
-- its parser list. Runs on every User TSUpdate event.
function M.register_custom()
  local parsers = require("nvim-treesitter.parsers")
  for name, p in pairs(require("ach.lang").custom_parsers()) do
    parsers[name] = { install_info = { url = p.url, revision = p.revision, queries = p.queries } }
  end
end

local function has_query(lang, name)
  local ok, query = pcall(vim.treesitter.query.get, lang, name)
  return ok and query ~= nil
end

-- The moves as buffer keys. In a diff, ]c and [c keep Neovim's meaning, the
-- next and previous change, which matters more there than classes do.
function M.moves_for(buf)
  for _, move in ipairs(M.moves) do
    local key, method, query, desc = unpack(move)
    vim.keymap.set({ "n", "x", "o" }, key, function()
      if vim.wo.diff and key:find("[cC]") then
        vim.cmd("normal! " .. vim.v.count1 .. key)
        return
      end
      require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
    end, { buffer = buf, desc = desc, silent = true })
  end
end

function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if not (ok and added) then
    return
  end
  if has_query(lang, "highlights") then
    pcall(vim.treesitter.start, buf, lang)
  end
  if has_query(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  if has_query(lang, "textobjects") then
    M.moves_for(buf)
  end
end

return M
