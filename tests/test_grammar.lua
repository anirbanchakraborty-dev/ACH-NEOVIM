-- Spelling and grammar. The spell file is kept in the data folder; prose is
-- checked word by word and wraps, code has only its comments checked, and
-- buffers that are not files, or files the table does not know, get no
-- spelling; Harper comes from Mason, only for a file it checks, and checks
-- the table's file types with three of its rules off.
local opened = {}

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- Writes lines to a new file called name and opens it in the current window.
local function open(t, name, lines)
  local path = t.tmpdir() .. "/" .. name
  vim.fn.writefile(lines, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  opened[#opened + 1] = buf
  return buf
end

-- The first misspelling on the current window's first line, and where it
-- starts, as { word, kind, column }. The column is zero-based.
local function first_misspelling()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local bad = vim.fn.spellbadword()
  return { bad[1], bad[2], vim.api.nvim_win_get_cursor(0)[2] }
end

return {
  ["the words zg adds are kept in the data folder"] = function(t)
    local G = require("ach.grammar")
    t.eq(G.spellfile, vim.fn.stdpath("data") .. "/spell/en.utf-8.add")
    t.eq(vim.go.spellfile, G.spellfile, "the spell file")
    t.ok(not vim.startswith(G.spellfile, t.root), "not in this repository")
    t.eq(vim.fn.isdirectory(vim.fs.dirname(G.spellfile)), 1, "its folder exists, so the first zg can write it")
    t.ok(#vim.api.nvim_get_runtime_file("spell/en.utf-8.spl", false) > 0, "Neovim's English word list")
  end,

  ["each file type is prose, code or neither"] = function(t)
    local G = require("ach.grammar")
    local cases = {
      text = "prose",
      markdown = "prose",
      ["markdown.mdx"] = "prose",
      tex = "prose",
      bib = "prose",
      typst = "prose",
      lua = "code",
      python = "code",
      gitcommit = "code",
      systemverilog = "code",
      lean = false,
      help = false,
      [""] = false,
      ["markdown.pandoc"] = "prose",
      ["lua.achtest"] = "code",
    }
    local got = {}
    for ft in pairs(cases) do
      got[ft] = G.kind_for(ft) or false
    end
    t.eq(got, cases)
    for _, ft in ipairs(require("ach.lang").manual_filetypes()) do
      t.eq(G.kind_for(ft), "prose", ft .. " is formatted by hand, so it is prose")
    end
  end,

  ["prose windows wrap, and code windows check only what the parser marks"] = function(t)
    tidy(function()
      local md = open(t, "notes.md", { "# Notes", "", "- one item" })
      t.ok(vim.wo.spell, "spelling in a Markdown window")
      t.ok(vim.wo.wrap, "long lines wrap")
      t.ok(vim.wo.breakindent, "wrapped lines keep their indent")
      t.eq(vim.wo.breakindentopt, "list:-1", "a list item's continuation lines sit under its text")
      t.eq(vim.bo[md].spellfile, vim.go.spellfile, "a new buffer gets the spell file")
      t.ok(not vim.tbl_contains(vim.opt_local.spelloptions:get(), "camel"), "camel is for code")

      local lua = open(t, "sample.lua", { "local x = 1" })
      t.ok(vim.wo.spell, "spelling in a Lua window")
      t.ok(not vim.wo.wrap, "code does not wrap, though the window showed prose before")
      local options = vim.opt_local.spelloptions:get()
      t.ok(vim.tbl_contains(options, "camel"), "camelCase names are checked part by part")
      t.ok(vim.tbl_contains(options, "noplainbuffer"), "only what the parser marks is checked")
      t.eq(vim.bo[lua].filetype, "lua")

      local txt = open(t, "sample.txt", { "one two" })
      t.ok(vim.wo.spell, "spelling in a text window")
      t.ok(vim.wo.wrap, "text wraps")
      t.ok(
        not vim.tbl_contains(vim.opt_local.spelloptions:get(), "noplainbuffer"),
        "text has no parser, so every word is checked"
      )
      t.eq(vim.bo[txt].filetype, "text")
      t.ok(not vim.go.spell and not vim.go.wrap, "only the windows changed, not the defaults")
    end)
  end,

  ["a misspelt comment is found and a misspelt name is not"] = function(t)
    tidy(function()
      local buf = open(t, "sample.lua", { "local teh = 1 -- one teh two" })
      vim.treesitter.start(buf, "lua")
      vim.treesitter.get_parser(buf, "lua"):parse(true)
      t.eq(first_misspelling(), { "teh", "bad", 21 }, "the word in the comment, not the name at column 6")
    end)
  end,

  ["plain text is checked word by word"] = function(t)
    tidy(function()
      -- Capitalised, since Neovim reports a lowercase sentence start first.
      open(t, "sample.txt", { "One teh two" })
      t.eq(first_misspelling(), { "teh", "bad", 4 })
    end)
  end,

  ["buffers that are not files, and files the table does not know, get no spelling"] = function(t)
    local G = require("ach.grammar")
    tidy(function()
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.api.nvim_win_set_buf(0, scratch)
      vim.bo[scratch].filetype = "markdown"
      t.eq(G.kind(scratch), nil, "a scratch buffer")
      t.ok(not vim.wo.spell, "no spelling in its window")

      local file = open(t, "notes.achtest", { "one teh two" })
      t.eq(vim.bo[file].filetype, "", "a file Neovim does not recognise")
      t.eq(G.kind(file), nil, "a file the table does not know")
      t.ok(not vim.wo.spell, "no spelling in its window")
      t.eq(G.kind(-1), nil, "a buffer that does not exist")
    end)
  end,

  ["Harper comes from Mason, for the file types it checks and no others"] = function(t)
    local install = require("ach.install")
    t.eq(require("ach.languages").grammar.package, "harper-ls", "the Mason package")
    local saved_dry, saved_map = install.dry, install.server_packages
    install.dry = true
    install.server_packages = function() return {} end
    local ok, err = pcall(tidy, function()
      install.reset()
      open(t, "data.json", { "{}" })
      t.ok(not vim.list_contains(install.requests.packages, "harper-ls"), "nothing of Harper's for a JSON file")
      open(t, "notes.md", { "# Notes" })
      t.ok(vim.list_contains(install.requests.packages, "harper-ls"), "harper-ls for a Markdown file")
    end)
    install.dry, install.server_packages = saved_dry, saved_map
    install.reset()
    if not ok then
      error(err, 0)
    end
  end,

  ["Harper checks only the table's file types, with three rules off"] = function(t)
    local config = vim.lsp.config.harper_ls
    t.eq(config.cmd[1], "harper-ls", "nvim-lspconfig's command")
    t.eq(config.filetypes, require("ach.lang").harper_filetypes(), "the table's file types")
    t.eq(config.settings, {
      ["harper-ls"] = { linters = { SpellCheck = false, LongSentences = false, Spaces = false } },
    })
  end,
}
