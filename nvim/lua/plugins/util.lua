-- Utility plugins: persistence (sessions), vim-sleuth, snacks notifier keymap.
--
-- Git-related plugins (gitsigns, lazygit, gitbrowse) and their which-key spec
-- entries live in git.lua, which is the single source of truth for the git
-- story. snacks.nvim itself is configured in ui.lua; here we only register
-- the snacks `<leader>un` keymap so lazy.nvim merges it onto the existing spec.

local icons = require("config.icons")

return {
  -- persistence.nvim: session save/restore. Autosaves on VimLeavePre unless
  -- you opt out via `:lua require('persistence').stop()` (bound to <leader>qd).
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Last Session" },
      { "<leader>qS", function() require("persistence").select() end,              desc = "Select Session" },
      { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't Save Session" },
      { "<leader>qq", "<cmd>qa<cr>",                                                desc = "Quit All" },
    },
  },

  -- vim-sleuth: detects tab width / expandtab per file by sniffing siblings.
  {
    "tpope/vim-sleuth",
    event = { "BufReadPre", "BufNewFile" },
  },

  -- snacks.nvim keys-only layer for the notification dismissal keymap,
  -- the scratch-buffer keymaps, and the file explorer launcher. The
  -- plugin itself is configured in ui.lua; lazy.nvim merges this `keys`
  -- block onto the existing spec without re-running opts.
  --
  -- The explorer keys mirror the LazyVim convention: <leader>fe and
  -- <leader>fE are the canonical names (root dir vs cwd), and
  -- <leader>e / <leader>E remap to them so the dashboard's reserved
  -- "Explorer" key actually opens something. The cwd-vs-root distinction
  -- matters in monorepos: <leader>e roots at the project (where .git
  -- lives), <leader>E uses whatever vim's cwd is currently set to.
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>un", function() Snacks.notifier.hide() end,  desc = "Dismiss Notifications" },
      { "<leader>.",  function() Snacks.scratch() end,        desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },

      -- snacks.explorer
      {
        "<leader>fe",
        function()
          -- Resolve project root from .git, falling back to cwd. Mirrors
          -- LazyVim's pick-the-right-root pattern without depending on
          -- the LazyVim helper module.
          local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
          Snacks.explorer({ cwd = root })
        end,
        desc = "Explorer (root)",
      },
      { "<leader>fE", function() Snacks.explorer() end, desc = "Explorer (cwd)" },
      { "<leader>e",  "<leader>fe", desc = "Explorer (root)", remap = true },
      { "<leader>E",  "<leader>fE", desc = "Explorer (cwd)",  remap = true },
    },
  },

  -- overseer.nvim: task runner. Wraps make / npm scripts / cargo / go
  -- test / language test runners with a unified UI. Wires up the
  -- <leader>o group that's now the home for build/run/test (CLAUDE.md's
  -- old <leader>r "Run/Build" placeholder was reassigned to refactoring
  -- in coding.lua, so build/run/test moved here under <leader>o).
  --
  -- The two <C-j>/<C-k> keymap unbinds in opts.task_list.keymaps prevent
  -- overseer from stealing those bindings inside its task list buffer --
  -- they're owned by global window navigation in keymaps.lua and getting
  -- them rebound inside a single buffer breaks muscle memory.
  --
  -- dap = false skips overseer's nvim-dap integration since DAP isn't
  -- installed (see project_deferred_dap memory). Re-enable when DAP
  -- adoption happens.
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerRun",
      "OverseerRunCmd",
      "OverseerTaskAction",
      "OverseerQuickAction",
      "OverseerInfo",
    },
    opts = {
      dap = false,
      task_list = {
        keymaps = {
          ["<C-j>"] = false,
          ["<C-k>"] = false,
        },
      },
      form = {
        win_opts = { winblend = 0 },
      },
      task_win = {
        win_opts = { winblend = 0 },
      },
    },
    keys = {
      { "<leader>oo", "<cmd>OverseerRun<cr>",        desc = "Run Task" },
      { "<leader>ow", "<cmd>OverseerToggle!<cr>",    desc = "Task List" },
      { "<leader>ot", "<cmd>OverseerTaskAction<cr>", desc = "Task Action" },
      { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Quick Action" },
      { "<leader>oi", "<cmd>OverseerInfo<cr>",       desc = "Overseer Info" },
    },
  },

  -- which-key: Session, Explorer, Overseer groups + per-key icons.
  -- Git groups are owned by git.lua.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Session group
        { "<leader>q", group = "Session", icon = { icon = icons.ui.quit, color = "red" } },

        { "<leader>qs", desc = "Restore Session",    icon = { icon = icons.ui.undo,    color = "green" } },
        { "<leader>ql", desc = "Last Session",       icon = { icon = icons.ui.recent,  color = "cyan"  } },
        { "<leader>qS", desc = "Select Session",     icon = { icon = icons.find.buffer, color = "blue" } },
        { "<leader>qd", desc = "Don't Save Session", icon = { icon = icons.ui.close,   color = "red"   } },
        { "<leader>qq", desc = "Quit All",           icon = { icon = icons.ui.quit,    color = "red"   } },

        -- Explorer (snacks.explorer) -- the dashboard already reserves
        -- the icon under <leader>e in CLAUDE.md, this just labels it.
        { "<leader>e",  desc = "Explorer (root)",     icon = { icon = icons.ui.tree,         color = "blue"  } },
        { "<leader>E",  desc = "Explorer (cwd)",      icon = { icon = icons.ui.folder_open,  color = "blue"  } },
        { "<leader>fe", desc = "Explorer (root)",     icon = { icon = icons.ui.tree,         color = "blue"  } },
        { "<leader>fE", desc = "Explorer (cwd)",      icon = { icon = icons.ui.folder_open,  color = "blue"  } },

        -- Overseer (build / run / test). Replaces the old <leader>r
        -- "Run/Build" placeholder from CLAUDE.md, which is now the
        -- refactoring group in coding.lua.
        { "<leader>o",  group = "Overseer (Tasks)", icon = { icon = icons.ui.rocket,    color = "orange" } },
        { "<leader>oo", desc = "Run Task",          icon = { icon = icons.ui.play,      color = "green"  } },
        { "<leader>ow", desc = "Task List",         icon = { icon = icons.find.cmd,     color = "blue"   } },
        { "<leader>ot", desc = "Task Action",       icon = { icon = icons.ui.menu,      color = "purple" } },
        { "<leader>oq", desc = "Quick Action",      icon = { icon = icons.ui.lightbulb, color = "yellow" } },
        { "<leader>oi", desc = "Overseer Info",     icon = { icon = icons.ui.info,     color = "cyan"   } },
      },
    },
  },
}
