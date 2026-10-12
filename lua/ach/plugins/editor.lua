-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/editor.lua, lua/lazyvim/plugins/util.lua
-- and lua/lazyvim/plugins/extras/editor/snacks_explorer.lua, for the flash, grug-far, trouble,
-- todo-comments, persistence and explorer specs.
local I = require("ach.icons")

local function root()
  return require("ach.util").root()
end

-- [q and ]q walk trouble's list while it is open and the quickfix list otherwise.
-- At either end of the quickfix list Neovim raises E553; that is news, not a fault.
local function step(dir)
  if require("trouble").is_open() then
    require("trouble")[dir]({ jump = true })
    return
  end
  local ok, err = pcall(vim.cmd[dir == "next" and "cnext" or "cprev"])
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

local function mc()
  return require("multicursor-nvim")
end

return {
  -- Jump to any spot on screen by typing two or three of its letters.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Select by Syntax" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
      {
        "R",
        mode = { "o", "x" },
        function() require("flash").treesitter_search() end,
        desc = "Flash Search by Syntax",
      },
      { "<c-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash in Search" },
      {
        "<c-space>",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({ actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" } })
        end,
        desc = "Grow Selection by Syntax",
      },
    },
  },

  -- Project-wide search and replace in a buffer you edit like any other.
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sr",
        function()
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          require("grug-far").open({
            transient = true,
            prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
          })
        end,
        mode = { "n", "x" },
        desc = "Search and Replace",
      },
    },
  },

  -- The problem list: diagnostics, symbols, references, quickfix and location lists.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      modes = { lsp = { win = { position = "right" } } },
      icons = { kinds = I.spaced(I.kinds) },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Problems (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Problems in This Buffer (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "Definitions and References (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      { "[q", function() step("prev") end, desc = "Previous Problem or Quickfix Entry" },
      { "]q", function() step("next") end, desc = "Next Problem or Quickfix Entry" },
    },
  },

  -- TODO, FIX, HACK, NOTE and WARN comments, highlighted and searchable.
  {
    "folke/todo-comments.nvim",
    cmd = "TodoTrouble",
    event = { "BufReadPost", "BufNewFile" },
    -- Only the icons change; the colours and alternate names stay todo-comments' own.
    opts = { keywords = I.todo_keywords() },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO Comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODO Comments (Trouble)" },
      {
        "<leader>xT",
        "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
        desc = "TODO and FIX Comments (Trouble)",
      },
      -- todo-comments registers this picker source with snacks when it loads, and pressing
      -- the key loads it first.
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "TODO Comments" },
      {
        "<leader>sT",
        function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end,
        desc = "TODO and FIX Comments",
      },
    },
  },

  -- A folder as a text buffer: rename a line to rename the file, delete it to delete the file.
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    opts = { default_file_explorer = false, view_options = { show_hidden = true } },
    keys = {
      { "<leader>fo", function() require("oil").open() end, desc = "Open Folder as Text (oil)" },
    },
  },

  -- One session per folder, saved on quit under ~/.local/state/nvim/sessions.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session for This Folder" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Pick a Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save This Session" },
    },
  },

  -- Several cursors that edit together.
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local m = mc()
      m.setup()
      -- These keys exist only while there is more than one cursor.
      m.addKeymapLayer(function(set)
        set({ "n", "x" }, "<left>", m.prevCursor, { desc = "Previous Cursor" })
        set({ "n", "x" }, "<right>", m.nextCursor, { desc = "Next Cursor" })
        set({ "n", "x" }, "<leader>md", m.deleteCursor, { desc = "Delete This Cursor" })
        set("n", "<esc>", function()
          if not m.cursorsEnabled() then
            m.enableCursors()
          else
            m.clearCursors()
          end
        end, { desc = "Clear Cursors" })
      end)
    end,
    keys = {
      { "<leader>mn", function() mc().matchAddCursor(1) end, mode = { "n", "x" }, desc = "Add Cursor at Next Match" },
      {
        "<leader>mN",
        function() mc().matchAddCursor(-1) end,
        mode = { "n", "x" },
        desc = "Add Cursor at Previous Match",
      },
      { "<leader>ms", function() mc().matchSkipCursor(1) end, mode = { "n", "x" }, desc = "Skip to Next Match" },
      { "<leader>mS", function() mc().matchSkipCursor(-1) end, mode = { "n", "x" }, desc = "Skip to Previous Match" },
      {
        "<leader>mA",
        function() mc().matchAllAddCursors() end,
        mode = { "n", "x" },
        desc = "Add Cursors at Every Match",
      },
      { "<leader>mx", function() mc().toggleCursor() end, mode = { "n", "x" }, desc = "Add or Remove a Cursor Here" },
      { "<leader>ma", function() mc().alignCursors() end, desc = "Align Cursors" },
      -- Ctrl with the arrows resizes windows (keymaps.lua), so Option adds cursors.
      { "<A-Up>", function() mc().lineAddCursor(-1) end, mode = { "n", "x" }, desc = "Add Cursor Above" },
      { "<A-Down>", function() mc().lineAddCursor(1) end, mode = { "n", "x" }, desc = "Add Cursor Below" },
    },
  },

  -- The file tree with git status, and two guards for very large or first-opened files.
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = true },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
    },
    keys = {
      { "<leader>fe", function() Snacks.explorer({ cwd = root() }) end, desc = "File Tree (project)" },
      { "<leader>fE", function() Snacks.explorer() end, desc = "File Tree (working folder)" },
      { "<leader>e", "<leader>fe", desc = "File Tree (project)", remap = true },
      { "<leader>E", "<leader>fE", desc = "File Tree (working folder)", remap = true },
    },
  },
}
