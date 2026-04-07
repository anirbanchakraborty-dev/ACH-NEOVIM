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

  -- snacks.nvim keys-only layer for the notification dismissal keymap and
  -- the scratch-buffer keymaps. The plugin itself is configured in ui.lua;
  -- lazy.nvim merges this `keys` block onto the existing spec without
  -- re-running opts.
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>un", function() Snacks.notifier.hide() end,  desc = "Dismiss Notifications" },
      { "<leader>.",  function() Snacks.scratch() end,        desc = "Toggle Scratch Buffer" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    },
  },

  -- which-key: Session group + per-key icons. Git groups are owned by git.lua.
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
      },
    },
  },
}
