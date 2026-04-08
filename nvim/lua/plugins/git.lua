-- Git: gitsigns, diffview, git-conflict + snacks lazygit/gitbrowse + which-key
local icons = require("config.icons")

return {
  -- gitsigns.nvim: hunk signs, inline blame, staging
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      -- Hunk navigation. ]H/[H jump to last/first hunk in buffer.
      {
        "]h",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next Hunk",
      },
      {
        "[h",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Prev Hunk",
      },
      {
        "]H",
        function()
          require("gitsigns").nav_hunk("last")
        end,
        desc = "Last Hunk",
      },
      {
        "[H",
        function()
          require("gitsigns").nav_hunk("first")
        end,
        desc = "First Hunk",
      },
      -- Toggle inline blame
      { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Line Blame" },
      -- Hunk actions
      { "<leader>ghs", ":Gitsigns stage_hunk<cr>", mode = { "n", "v" }, desc = "Stage Hunk" },
      { "<leader>ghr", ":Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "Reset Hunk" },
      { "<leader>ghS", "<cmd>Gitsigns stage_buffer<cr>", desc = "Stage Buffer" },
      { "<leader>ghR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Reset Buffer" },
      { "<leader>ghu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "Undo Stage Hunk" },
      -- Inline preview shows the hunk virtually at cursor instead of in a popup.
      { "<leader>ghp", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "Preview Hunk Inline" },
      {
        "<leader>ghb",
        function()
          require("gitsigns").blame_line({ full = true })
        end,
        desc = "Blame Line (popup)",
      },
      {
        "<leader>ghB",
        function()
          require("gitsigns").blame()
        end,
        desc = "Blame Buffer",
      },
      { "<leader>ghd", "<cmd>Gitsigns diffthis<cr>", desc = "Diff This" },
      {
        "<leader>ghD",
        function()
          require("gitsigns").diffthis("~")
        end,
        desc = "Diff This ~",
      },
      -- `ih` text object: vih selects a hunk, dih deletes it, etc.
      { "ih", ":<C-U>Gitsigns select_hunk<cr>", mode = { "o", "x" }, desc = "Select Hunk" },
    },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
      },
      signs_staged_enable = true,
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
        ignore_whitespace = false,
      },
      preview_config = {
        border = "rounded",
        style = "minimal",
      },
    },
  },

  -- diffview.nvim: git diff / merge / file-history viewer
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diffview Close" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History (current)" },
      { "<leader>gl", "<cmd>DiffviewFileHistory<cr>", desc = "Repo Log" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        merge_tool = {
          layout = "diff3_mixed",
          disable_diagnostics = true,
        },
      },
    },
  },

  -- git-conflict.nvim: inline merge conflict resolution
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPre",
    keys = {
      { "<leader>gxo", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" },
      { "<leader>gxt", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" },
      { "<leader>gxb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" },
      { "<leader>gxn", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" },
      { "<leader>gxl", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts" },
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next Conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Prev Conflict" },
    },
    opts = {
      default_mappings = false,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
      highlights = {
        incoming = "DiffAdd",
        current = "DiffText",
      },
    },
  },

  -- snacks.nvim: LazyGit + GitBrowse keymaps (modules enabled in ui.lua)
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "LazyGit",
      },
      {
        "<leader>gG",
        function()
          Snacks.lazygit({ cwd = vim.fn.getcwd() })
        end,
        desc = "LazyGit (cwd)",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        mode = { "n", "v" },
        desc = "Browse on GitHub",
      },
    },
  },

  -- octo.nvim: GitHub PR/issue/repo management inside nvim. Authenticates
  -- via the `gh` CLI (run `gh auth login` once before first use). Uses
  -- fzf-lua as the picker since that's what this config ships -- LazyVim
  -- has a runtime check (`LazyVim.has_extra("editor.fzf")`) that we don't
  -- need because we know which picker we have.
  --
  -- The keymap surface adds six top-level <leader>g* bindings (issues,
  -- PRs, repos, search) and a set of <localleader>* group labels that
  -- only show up inside `octo` filetype buffers (which-key picks them up
  -- via the `ft = "octo"` filter). The @ and # mappings remap to the
  -- omnicompletion trigger so typing @ or # inside an octo buffer fires
  -- the user/issue/PR completion popup automatically.
  --
  -- The ExitPre autocmd flips octo buffers to `buftype = ""` right before
  -- nvim quits so persistence.nvim sessions can save them as regular
  -- file buffers (without this, octo's `acwrite` buftype gets serialized
  -- and the next session restore tries to fetch the URL again).
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    opts = {
      enable_builtin = true,
      default_to_projects_v2 = true,
      default_merge_method = "squash",
      picker = "fzf-lua",
    },
    config = function(_, opts)
      require("octo").setup(opts)
      -- Render octo buffer bodies (PR/issue descriptions, comments) as
      -- markdown. Without this they show as plain text since octo's
      -- own filetype isn't a treesitter language.
      vim.treesitter.language.register("markdown", "octo")

      -- Keep octo windows around when nvim exits so persistence.nvim
      -- can restore them. Borrowed from LazyVim's extras/util/octo.lua.
      vim.api.nvim_create_autocmd("ExitPre", {
        group = vim.api.nvim_create_augroup("ACHOctoExitPre", { clear = true }),
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "octo" then
              vim.bo[buf].buftype = ""
            end
          end
        end,
      })
    end,
    keys = {
      -- Top-level entry points
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "List Issues (Octo)" },
      { "<leader>gI", "<cmd>Octo issue search<CR>", desc = "Search Issues (Octo)" },
      { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
      { "<leader>gP", "<cmd>Octo pr search<CR>", desc = "Search PRs (Octo)" },
      { "<leader>gr", "<cmd>Octo repo list<CR>", desc = "List Repos (Octo)" },
      { "<leader>gS", "<cmd>Octo search<CR>", desc = "Search (Octo)" },

      -- Localleader group labels inside octo buffers (which-key picks
      -- these up only when buffer filetype == "octo"). The actions
      -- themselves are bound by octo.nvim's own mappings module.
      { "<localleader>a", "", desc = "+assignee (Octo)", ft = "octo" },
      { "<localleader>c", "", desc = "+comment/code (Octo)", ft = "octo" },
      { "<localleader>l", "", desc = "+label (Octo)", ft = "octo" },
      { "<localleader>i", "", desc = "+issue (Octo)", ft = "octo" },
      { "<localleader>r", "", desc = "+react (Octo)", ft = "octo" },
      { "<localleader>p", "", desc = "+pr (Octo)", ft = "octo" },
      { "<localleader>pr", "", desc = "+rebase (Octo)", ft = "octo" },
      { "<localleader>ps", "", desc = "+squash (Octo)", ft = "octo" },
      { "<localleader>v", "", desc = "+review (Octo)", ft = "octo" },
      { "<localleader>g", "", desc = "+goto_issue (Octo)", ft = "octo" },

      -- @ and # in insert mode trigger omnicompletion (user / issue / PR pickers).
      { "@", "@<C-x><C-o>", mode = "i", ft = "octo", silent = true },
      { "#", "#<C-x><C-o>", mode = "i", ft = "octo", silent = true },
    },
  },

  -- which-key.nvim: extend spec with git groups + individual keymap icons
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        -- Groups
        { "<leader>g", group = "Git", icon = { icon = icons.devtools.git, color = "orange" } },
        { "<leader>gh", group = "Hunks", icon = { icon = icons.git.diff, color = "cyan" } },
        { "<leader>gx", group = "Conflicts", icon = { icon = icons.git.conflict, color = "red" } },

        -- Git actions
        { "<leader>gg", desc = "LazyGit", icon = { icon = icons.devtools.git, color = "orange" } },
        { "<leader>gG", desc = "LazyGit (cwd)", icon = { icon = icons.devtools.git, color = "orange" } },
        { "<leader>gb", desc = "Toggle Line Blame", icon = { icon = icons.git.commit, color = "blue" } },
        { "<leader>gB", desc = "Browse on GitHub", icon = { icon = icons.ui.globe, color = "purple" } },
        { "<leader>gf", desc = "File History (current)", icon = { icon = icons.ui.recent, color = "blue" } },
        { "<leader>gl", desc = "Repo Log", icon = { icon = icons.git.log, color = "blue" } },
        { "<leader>gd", desc = "Diffview Open", icon = { icon = icons.git.diff, color = "green" } },
        { "<leader>gD", desc = "Diffview Close", icon = { icon = icons.ui.quit, color = "red" } },

        -- Octo (GitHub PR/issue/repo management)
        { "<leader>gi", desc = "List Issues (Octo)", icon = { icon = icons.git.issue_open, color = "green" } },
        { "<leader>gI", desc = "Search Issues (Octo)", icon = { icon = icons.git.issue_open, color = "yellow" } },
        { "<leader>gp", desc = "List PRs (Octo)", icon = { icon = icons.git.pull_request, color = "purple" } },
        { "<leader>gP", desc = "Search PRs (Octo)", icon = { icon = icons.git.pull_request, color = "yellow" } },
        { "<leader>gr", desc = "List Repos (Octo)", icon = { icon = icons.git.repo, color = "blue" } },
        { "<leader>gS", desc = "Search (Octo)", icon = { icon = icons.find.grep, color = "yellow" } },

        -- Hunk actions
        { "<leader>ghs", desc = "Stage Hunk", icon = { icon = icons.git.added, color = "green" } },
        { "<leader>ghS", desc = "Stage Buffer", icon = { icon = icons.git.added, color = "green" } },
        { "<leader>ghr", desc = "Reset Hunk", icon = { icon = icons.ui.undo, color = "orange" } },
        { "<leader>ghR", desc = "Reset Buffer", icon = { icon = icons.ui.undo, color = "orange" } },
        { "<leader>ghu", desc = "Undo Stage Hunk", icon = { icon = icons.ui.undo, color = "orange" } },
        { "<leader>ghp", desc = "Preview Hunk Inline", icon = { icon = icons.ui.eye, color = "cyan" } },
        { "<leader>ghb", desc = "Blame Line (popup)", icon = { icon = icons.git.commit, color = "blue" } },
        { "<leader>ghB", desc = "Blame Buffer", icon = { icon = icons.git.commit, color = "blue" } },
        { "<leader>ghd", desc = "Diff This", icon = { icon = icons.git.diff, color = "purple" } },
        { "<leader>ghD", desc = "Diff This ~", icon = { icon = icons.git.diff, color = "purple" } },

        -- Conflict actions
        { "<leader>gxo", desc = "Choose Ours", icon = { icon = icons.ui.check, color = "green" } },
        { "<leader>gxt", desc = "Choose Theirs", icon = { icon = icons.misc.arrow_right, color = "blue" } },
        { "<leader>gxb", desc = "Choose Both", icon = { icon = icons.git.merge, color = "purple" } },
        { "<leader>gxn", desc = "Choose None", icon = { icon = icons.ui.close, color = "red" } },
        { "<leader>gxl", desc = "List Conflicts", icon = { icon = icons.git.log, color = "yellow" } },

        -- Hunk/Conflict navigation
        { "]h", desc = "Next Hunk", icon = { icon = icons.misc.arrow_right, color = "cyan" } },
        { "[h", desc = "Prev Hunk", icon = { icon = icons.misc.arrow_left, color = "cyan" } },
        { "]H", desc = "Last Hunk", icon = { icon = icons.misc.arrow_right, color = "cyan" } },
        { "[H", desc = "First Hunk", icon = { icon = icons.misc.arrow_left, color = "cyan" } },
        { "]x", desc = "Next Conflict", icon = { icon = icons.misc.arrow_right, color = "red" } },
        { "[x", desc = "Prev Conflict", icon = { icon = icons.misc.arrow_left, color = "red" } },
      },
    },
  },
}
