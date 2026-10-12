-- which-key draws every key that can follow Space after a short pause, and
-- snacks.picker is the finder behind the f and s menus.
-- The picker keys are adapted from LazyVim (Apache-2.0),
-- lua/lazyvim/plugins/extras/editor/snacks_picker.lua.
-- Every icon comes from lua/ach/icons.lua: the groups' icons directly, each
-- key's through the rules which-key tries before its own.
local I = require("ach.icons")

local function root() return require("ach.util").root() end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    -- A later plugin file may add groups with its own which-key spec; this makes
    -- lazy.nvim join the lists instead of letting the later one replace this one.
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      spec = {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "tabs", icon = I.group("tabs") },
          { "<leader>a", group = "claude", icon = I.group("claude") },
          {
            "<leader>b",
            group = "buffer",
            icon = I.group("buffer"),
            expand = function() return require("which-key.extras").expand.buf() end,
          },
          { "<leader>c", group = "code", icon = I.group("code") },
          { "<leader>d", group = "debug", icon = I.group("debug") },
          { "<leader>f", group = "file/find", icon = I.group("file/find") },
          { "<leader>g", group = "git", icon = I.group("git") },
          { "<leader>gh", group = "hunks", icon = I.group("hunks") },
          { "<leader>m", group = "multicursor", icon = I.group("multicursor") },
          { "<leader>q", group = "quit/session", icon = I.group("quit/session") },
          { "<leader>s", group = "search", icon = I.group("search") },
          { "<leader>u", group = "toggles", icon = I.group("toggles") },
          {
            "<leader>w",
            group = "windows",
            icon = I.group("windows"),
            proxy = "<c-w>",
            expand = function() return require("which-key.extras").expand.win() end,
          },
          { "<leader>x", group = "diagnostics/quickfix", icon = I.group("diagnostics/quickfix") },
          { "[", group = "prev", icon = I.group("prev") },
          { "]", group = "next", icon = I.group("next") },
          { "g", group = "goto", icon = I.group("goto") },
          { "z", group = "fold", icon = I.group("fold") },
        },
      },
    },
    -- The icon rules are built when which-key loads, after the first screen,
    -- rather than when this file is read during the start.
    config = function(_, opts)
      opts.icons = vim.tbl_extend("force", opts.icons or {}, { rules = I.which_key_rules() })
      require("which-key").setup(opts)
    end,
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function() require("which-key").show({ keys = "<c-w>", loop = true }) end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        enabled = true,
        icons = { kinds = I.spaced(I.kinds), diagnostics = I.spaced(I.diagnostics) },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader><space>", function() Snacks.picker.files({ cwd = root() }) end, desc = "Find Files (Root Dir)" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() Snacks.picker.grep({ cwd = root() }) end, desc = "Grep (Root Dir)" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- find
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.g.ach_root }) end, desc = "Find Config File" },
      { "<leader>ff", function() Snacks.picker.files({ cwd = root() }) end, desc = "Find Files (Root Dir)" },
      { "<leader>fF", function() Snacks.picker.files() end, desc = "Find Files (cwd)" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
      -- search
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sg", function() Snacks.picker.grep({ cwd = root() }) end, desc = "Grep (Root Dir)" },
      { "<leader>sG", function() Snacks.picker.grep() end, desc = "Grep (cwd)" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
      { "<leader>sw", function() Snacks.picker.grep_word({ cwd = root() }) end, desc = "Selection or Word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", function() Snacks.picker.grep_word() end, desc = "Selection or Word (cwd)", mode = { "n", "x" } },
    },
  },
}
