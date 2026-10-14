-- Spelling and grammar. Neovim's spell checker underlines misspelt words in
-- prose and in code comments; Harper, a language server, reports grammar in
-- the same places. This module decides where spelling is on and how much of
-- a file it reads, where the words zg adds are kept, and what Harper is told.
local M = {}

-- The words zg adds. Neovim would otherwise write them into the first folder
-- of the runtime path, which is this repository.
M.spellfile = vim.fn.stdpath("data") .. "/spell/en.utf-8.add"

local function kind_of(ft)
  local lang = require("ach.lang")
  if lang.is_manual(ft) then
    return "prose"
  end
  if #lang.parsers_for_ft(ft) > 0 then
    return "code"
  end
  return nil
end

-- What spelling treats a file type as: "prose", where every word is checked
-- and long lines wrap; "code", where only what the parser marks is checked,
-- comments for the most part; or nil, where spelling stays off. A compound
-- file type the table does not name, such as markdown.pandoc, is read by its
-- parts, the first that is known deciding.
function M.kind_for(ft)
  local kind = kind_of(ft)
  if kind or require("ach.lang").for_ft(ft) then
    return kind
  end
  for _, part in ipairs(vim.split(ft, ".", { plain = true })) do
    kind = kind_of(part)
    if kind then
      return kind
    end
  end
  return nil
end

-- The kind of a buffer: nil for one that does not exist or is not a file,
-- such as help, a terminal or a picker.
function M.kind(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return nil
  end
  return M.kind_for(vim.bo[buf].filetype)
end

-- Turns spelling on in the window showing buf, as :setlocal does, so a file
-- opened in that window later starts from the defaults again. Prose also
-- wraps at word boundaries, a list item's continuation lines indented under
-- its text. In code, noplainbuffer leaves the buffer unchecked until a parser
-- or syntax file marks what to check, so names are never underlined, and
-- camel reads a camelCase name in a comment as the words it is made of.
function M.apply(buf)
  local kind = M.kind(buf)
  if not kind then
    return
  end
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.spell = true
    if kind == "prose" then
      vim.opt_local.wrap = true
      vim.opt_local.breakindent = true
      vim.opt_local.breakindentopt = "list:-1"
    else
      vim.opt_local.spelloptions:append({ "camel", "noplainbuffer" })
    end
  end)
end

-- Harper's file types and settings. The file types are the table's, which
-- Neovim puts in place of nvim-lspconfig's longer list. SpellCheck is off
-- because Neovim already underlines misspelt words and keeps the one
-- dictionary; LongSentences because a long sentence is a choice in this
-- author's prose; Spaces because comments here align columns with spaces.
--
-- The rest are off because they misread technical prose. On the sixty-six
-- chapters of a computer architecture book they made 2,303 reports between
-- them, and five were real errors. AnA picks a or an by spelling rather than
-- sound, so it rejects "an x86" and "an SOP", though it did catch "a SRAM".
-- MassNouns rejects "dependences" and "a doubling". OrthographicConsistency
-- wants "PS" for picoseconds and "Na" for nanoamperes. ExpandMemoryShorthands
-- spells out "KiB". CompoundNouns asks for "frontend", where "front end" is
-- standard too. SentenceCapitalization reads a callout label such as
-- [!example], or the "where" after an equation, as a sentence. UseTitleCase
-- asks for title case in every heading, where the case of a heading is each
-- document's choice.
M.harper_off = {
  "SpellCheck", "LongSentences", "Spaces",
  "AnA", "MassNouns", "OrthographicConsistency", "ExpandMemoryShorthands",
  "CompoundNouns", "SentenceCapitalization", "UseTitleCase",
}

function M.harper()
  local linters = {}
  for _, name in ipairs(M.harper_off) do
    linters[name] = false
  end
  return {
    filetypes = require("ach.lang").harper_filetypes(),
    settings = { ["harper-ls"] = { linters = linters } },
  }
end

-- Runs once, before lazy.nvim, so the first file named on the command line
-- gets its spelling, and Harper is narrowed before any server is enabled.
function M.setup()
  vim.opt.spellfile = M.spellfile
  vim.fn.mkdir(vim.fs.dirname(M.spellfile), "p")
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ach_grammar", { clear = true }),
    callback = function(ev) M.apply(ev.buf) end,
  })
  vim.lsp.config("harper_ls", M.harper())
end

return M
