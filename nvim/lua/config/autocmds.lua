-- Global autocommands.
--
-- Runs at init time, before plugins, so anything in here uses pure vim APIs.
-- Each group is cleared on reload so :source $MYVIMRC is idempotent.

local function augroup(name)
  return vim.api.nvim_create_augroup("ACH_" .. name, { clear = true })
end

-- ---------------------------------------------------------------------------
-- Treesitter language aliases
-- ---------------------------------------------------------------------------

-- nvim-treesitter only ships a `systemverilog` parser; there is no separate
-- `verilog` parser. Register the alias so .v / .vh files (filetype = verilog)
-- use the systemverilog parser via the existing on-demand installer in
-- treesitter.lua. pcall'd because the call is harmless when no parser is
-- installed yet -- the alias just sits idle until the parser arrives, and
-- then highlighting + folds + indent kick in for both filetypes.
pcall(vim.treesitter.language.register, "systemverilog", "verilog")

-- ---------------------------------------------------------------------------
-- Auto-open explorer sidebar
-- ---------------------------------------------------------------------------

-- Open the snacks explorer on startup when nvim was invoked with a file or
-- directory argument. Bare `nvim` (no args) shows the dashboard instead, so
-- we skip in that case to avoid the explorer covering the dashboard.
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup("ExplorerAutoOpen"),
  callback = function()
    if vim.fn.argc() > 0 then
      vim.schedule(function()
        local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
        Snacks.explorer({ cwd = root })
      end)
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Visual feedback
-- ---------------------------------------------------------------------------

-- Briefly highlight yanked text. `vim.hl` is the new namespace in 0.11+;
-- fall back to `vim.highlight` for older releases.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("HighlightYank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Restore last cursor position when opening a file (skip commit messages
-- and files whose saved position is past the current EOF).
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("RestoreCursor"),
  callback = function(args)
    local exclude = { "gitcommit", "gitrebase" }
    local buf = args.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].ach_last_loc then
      return
    end
    vim.b[buf].ach_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ---------------------------------------------------------------------------
-- Window / buffer housekeeping
-- ---------------------------------------------------------------------------

-- Equalize splits when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("ResizeSplits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Reload the buffer if the file changed on disk while we had focus elsewhere
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("Checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Close utility filetypes with `q`. The keymap.set is wrapped in vim.schedule
-- to avoid timing issues where the buffer isn't fully ready when the FileType
-- event fires. The callback closes the window AND deletes the buffer so it
-- doesn't linger in the buffer list (already buflisted = false, but a hard
-- delete keeps things tidier across sessions).
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("CloseWithQ"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dap-float",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "neotest-summary",
    "neotest-output-panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- Auto-create missing parent directories on :w
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("AutoMkdir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end -- skip URIs
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ---------------------------------------------------------------------------
-- Filetype tweaks
-- ---------------------------------------------------------------------------

-- Soft wrap + spellcheck in prose filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("ProseMode"),
  pattern = { "markdown", "markdown.mdx", "gitcommit", "text", "tex", "plaintex" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.linebreak = true
  end,
})

-- Disable concealment in JSON: the global conceallevel = 2 hides string
-- quotes and other punctuation that you actually need to read in data files.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("JsonConceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Treesitter-aware folds: when a buffer has a treesitter parser available,
-- swap the buffer-local foldmethod to expr + vim.treesitter.foldexpr() so
-- folds follow syntactic structure (functions, classes, blocks) instead of
-- pure indentation. Files without a parser fall back to the global
-- foldmethod = "indent" set in options.lua.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("TreesitterFolds"),
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})

-- Four-space indent for languages whose communities expect it
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("Indent4"),
  pattern = { "python", "c", "cpp", "rust", "java" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- Go prefers hard tabs and gofmt / gofumpt enforces tab indentation
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("GoTabs"),
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- SystemVerilog / VHDL: set a sensible commentstring (neither is shipped
-- with a default by Neovim).
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("HdlCommentstring"),
  pattern = { "systemverilog", "verilog" },
  callback = function()
    vim.bo.commentstring = "// %s"
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("VhdlCommentstring"),
  pattern = { "vhdl" },
  callback = function()
    vim.bo.commentstring = "-- %s"
  end,
})

-- ---------------------------------------------------------------------------
-- Performance: downgrade heavy features on very large files
-- ---------------------------------------------------------------------------

local bigfile_group = augroup("BigFile")
local bigfile_limit = 1.5 * 1024 * 1024 -- 1.5 MiB

vim.api.nvim_create_autocmd("BufReadPre", {
  group = bigfile_group,
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > bigfile_limit then
      vim.b[args.buf].ach_bigfile = true
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.spell = false
      vim.opt_local.swapfile = false
      vim.opt_local.undofile = false
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = bigfile_group,
  callback = function(args)
    if vim.b[args.buf].ach_bigfile then
      vim.cmd("syntax clear")
      vim.opt_local.syntax = "off"
      pcall(vim.treesitter.stop, args.buf)
    end
  end,
})
