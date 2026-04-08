-- Terminal: toggleterm.nvim with general terminals + language-specific REPLs.
-- General terminals come in four orientations (float/horizontal/vertical/tab).
-- Named REPLs are lazy-created on first use and persist across toggles, so
-- state survives when you hide and reopen them.
local icons = require("config.icons")

-- Lazy cache of named REPL terminals. The Terminal class is only required when
-- a REPL keymap actually fires, which is after toggleterm has been lazy-loaded.
local repls = {}

local function get_repl(name, cmd)
  if not repls[name] then
    local Terminal = require("toggleterm.terminal").Terminal
    repls[name] = Terminal:new({
      cmd = cmd,
      display_name = name,
      direction = "float",
      hidden = true,
      float_opts = {
        border = "rounded",
        title = " " .. name .. " ",
        title_pos = "center",
      },
    })
  end
  return repls[name]
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      -- General terminals
      {
        [[<C-\>]],
        "<cmd>ToggleTerm direction=float<cr>",
        mode = { "n", "t" },
        desc = "Toggle Float Terminal",
      },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Float Terminal" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Horizontal Terminal" },
      { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Vertical Terminal" },
      { "<leader>tT", "<cmd>ToggleTerm direction=tab<cr>", desc = "Tab Terminal" },

      -- Language REPLs (lazy-created on first invocation)
      {
        "<leader>tp",
        function()
          get_repl("Python", "python3"):toggle()
        end,
        desc = "Python REPL",
      },
      {
        "<leader>tn",
        function()
          get_repl("Node", "node"):toggle()
        end,
        desc = "Node REPL",
      },
      {
        "<leader>tl",
        function()
          get_repl("Lua", "lua"):toggle()
        end,
        desc = "Lua REPL",
      },
      {
        "<leader>tr",
        function()
          get_repl("IRB", "irb"):toggle()
        end,
        desc = "Ruby IRB",
      },
      {
        "<leader>tR",
        function()
          get_repl("R", "R"):toggle()
        end,
        desc = "R Console",
      },
      {
        "<leader>tP",
        function()
          get_repl("Perl", "perl -de 0"):toggle()
        end,
        desc = "Perl REPL",
      },
      {
        "<leader>ts",
        function()
          get_repl("Swift", "swift"):toggle()
        end,
        desc = "Swift REPL",
      },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return math.floor(vim.o.lines * 0.30)
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.40)
        end
      end,
      hide_numbers = true,
      shade_terminals = false,
      start_in_insert = true,
      insert_mappings = false,
      terminal_mappings = false,
      persist_size = true,
      persist_mode = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "rounded",
        winblend = 0,
        title_pos = "center",
      },
      highlights = {
        Normal = { link = "NormalFloat" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      -- Terminal-mode ergonomics: <Esc><Esc> drops to normal mode, and
      -- <C-h/j/k/l> navigates out to adjacent windows. Set globally so the
      -- mappings apply to every terminal buffer without relying on autocmd
      -- pattern matching against toggleterm's internal buffer URLs.
      local km = { silent = true }
      vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], vim.tbl_extend("force", km, { desc = "Exit terminal mode" }))
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], vim.tbl_extend("force", km, { desc = "Window left" }))
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], vim.tbl_extend("force", km, { desc = "Window down" }))
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], vim.tbl_extend("force", km, { desc = "Window up" }))
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], vim.tbl_extend("force", km, { desc = "Window right" }))
    end,
  },

  -- which-key: extend spec with terminal group + individual keymap icons.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Group
        { "<leader>t", group = "Terminal", icon = { icon = icons.ui.terminal, color = "green" } },

        -- General terminals
        { "<leader>tf", desc = "Float Terminal", icon = { icon = icons.ui.terminal, color = "green" } },
        { "<leader>th", desc = "Horizontal Terminal", icon = { icon = icons.ui.terminal, color = "green" } },
        { "<leader>tv", desc = "Vertical Terminal", icon = { icon = icons.ui.terminal, color = "green" } },
        { "<leader>tT", desc = "Tab Terminal", icon = { icon = icons.ui.terminal, color = "green" } },

        -- Language REPLs
        { "<leader>tp", desc = "Python REPL", icon = { icon = icons.filetypes.python, color = "yellow" } },
        { "<leader>tn", desc = "Node REPL", icon = { icon = icons.devtools.nodejs, color = "green" } },
        { "<leader>tl", desc = "Lua REPL", icon = { icon = icons.filetypes.lua, color = "blue" } },
        { "<leader>tr", desc = "Ruby IRB", icon = { icon = icons.filetypes.ruby, color = "red" } },
        { "<leader>tR", desc = "R Console", icon = { icon = icons.filetypes.r, color = "cyan" } },
        { "<leader>tP", desc = "Perl REPL", icon = { icon = icons.filetypes.perl, color = "purple" } },
        { "<leader>ts", desc = "Swift REPL", icon = { icon = icons.filetypes.swift, color = "orange" } },
      },
    },
  },
}
