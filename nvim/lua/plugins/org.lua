-- Org mode: full knowledge base stack.
--
--   * orgmode               -- core Emacs Org mode reimplementation
--   * org-bullets.nvim       -- conceals heading stars with unicode bullets
--   * org-roam.nvim          -- bidirectional linking / knowledge graph
--   + fzf-lua scoped search  -- grep / file-find narrowed to ~/org
--   + blink.cmp source       -- completion (lives in coding.lua)
--
-- All plugins lazy-load on the `org` filetype or via `keys` so they cost
-- nothing at startup unless you actually open an `.org` file or press a
-- `<leader>n*` binding. The `<leader>n` prefix stands for "Notes / Org".
--
-- orgmode's default global prefix is `<leader>o` which collides with
-- Overseer in this config. We remap it to `<leader>n` via
-- `mappings.global`. org-roam's default prefix is also `<leader>n` so
-- it mostly aligns, but its capture binding (`<leader>nc`) is disabled
-- to avoid colliding with orgmode's capture -- find_node creates new
-- nodes on the fly, so a separate roam-capture binding is unnecessary.

local icons = require("config.icons")

return {
  -- ──────────────────────────────────────────────────────────────────
  -- orgmode
  --
  -- Core Org mode engine: agenda, capture, TODO cycling, date stamps,
  -- clock, refile, tags, properties, export. The two global commands
  -- (agenda + capture) live in `keys` so they trigger plugin load from
  -- any buffer; `ft` ensures the plugin also loads when directly
  -- opening an .org file.
  -- ──────────────────────────────────────────────────────────────────
  {
    "nvim-orgmode/orgmode",
    ft = { "org" },
    dependencies = {
      {
        "nvim-orgmode/org-bullets.nvim",
        ft = { "org" },
        opts = {
          concealcursor = false,
          symbols = {
            checkboxes = {
              half = { "", "OrgTSCheckboxHalfChecked" },
              done = { icons.ui.checkbox, "@org.keyword.done" },
              todo = { icons.ui.checkbox_blank, "@org.keyword.todo" },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>na",
        "<cmd>Org agenda<cr>",
        desc = "Org Agenda",
      },
      {
        "<leader>nc",
        "<cmd>Org capture<cr>",
        desc = "Org Capture",
      },
      -- fzf-lua scoped search: reuses existing fzf infra, no extra plugin
      {
        "<leader>nf",
        function()
          require("fzf-lua").files({ cwd = vim.fn.expand("~/org") })
        end,
        desc = "Find Org Files",
      },
      {
        "<leader>ns",
        function()
          require("fzf-lua").live_grep({ cwd = vim.fn.expand("~/org") })
        end,
        desc = "Search Org Files",
      },
    },
    opts = {
      org_agenda_files = "~/org/**/*",
      org_default_notes_file = "~/org/refile.org",
      org_capture_templates = {
        t = {
          description = "Todo",
          template = "* TODO %?\n  %u",
          target = "~/org/todos.org",
        },
        n = {
          description = "Note",
          template = "* %?\n  %u",
          target = "~/org/notes.org",
        },
        j = {
          description = "Journal",
          template = "* %<%Y-%m-%d %A>\n  %?",
          target = "~/org/journal.org",
          datetree = true,
        },
      },
      mappings = {
        global = {
          org_agenda = "<Leader>na",
          org_capture = "<Leader>nc",
        },
      },
    },
  },

  -- ──────────────────────────────────────────────────────────────────
  -- org-roam.nvim
  --
  -- Bidirectional linking and knowledge graph on top of orgmode.
  -- Stores roam-specific notes (with :ID: properties) under ~/org/roam.
  -- The bindings table disables the default `<leader>nc` capture to
  -- avoid colliding with orgmode's capture above; find_node creates
  -- new nodes on the fly when the search comes up empty.
  -- ──────────────────────────────────────────────────────────────────
  {
    "chipsenkbeil/org-roam.nvim",
    ft = { "org" },
    dependencies = {
      "nvim-orgmode/orgmode",
    },
    keys = {
      {
        "<leader>nr",
        function()
          require("org-roam").api.find_node()
        end,
        desc = "Roam: Find Node",
      },
      {
        "<leader>ni",
        function()
          require("org-roam").api.insert_node()
        end,
        desc = "Roam: Insert Link",
        ft = "org",
      },
      {
        "<leader>nl",
        function()
          require("org-roam").api.toggle_roam_buffer()
        end,
        desc = "Roam: Toggle Buffer",
      },
    },
    opts = {
      directory = "~/org/roam",
      bindings = {
        -- Disable default prefix keymaps -- we define our own via lazy keys
        prefix = false,
      },
    },
  },

  -- ──────────────────────────────────────────────────────────────────
  -- which-key: register the <leader>n group and all org-related
  -- keymap icons so the discoverable popup shows friendly entries.
  -- ──────────────────────────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Group
        { "<leader>n", group = "Notes/Org", icon = { icon = icons.org.org, color = "green" } },

        -- Core orgmode
        { "<leader>na", desc = "Org Agenda", icon = { icon = icons.org.agenda, color = "cyan" } },
        { "<leader>nc", desc = "Org Capture", icon = { icon = icons.org.capture, color = "green" } },

        -- fzf-lua search
        { "<leader>nf", desc = "Find Org Files", icon = { icon = icons.find.file, color = "blue" } },
        { "<leader>ns", desc = "Search Org Files", icon = { icon = icons.find.grep, color = "cyan" } },

        -- Org Roam
        { "<leader>nr", desc = "Roam: Find Node", icon = { icon = icons.org.roam, color = "purple" } },
        { "<leader>ni", desc = "Roam: Insert Link", icon = { icon = icons.org.roam, color = "purple" } },
        { "<leader>nl", desc = "Roam: Toggle Buffer", icon = { icon = icons.org.note, color = "green" } },
      },
    },
  },
}
