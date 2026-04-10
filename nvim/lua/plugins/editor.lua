-- Editor: which-key, fzf-lua (fuzzy finder)
local icons = require("config.icons")

return {
  -- which-key: popup keymap helper
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
    keys = {
      -- Show only the keymaps that are bound for the current buffer.
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      -- Window "hydra" mode: holds which-key open on <c-w> so you can chain
      -- window-management commands without re-pressing the prefix every time.
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
    opts = {
      preset = "modern",
      delay = 300,
      icons = {
        mappings = true,
        rules = false,
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      spec = {
        -- Groups
        { "<leader>f", group = "File/Find", icon = { icon = icons.ui.find_file, color = "blue" } },
        { "<leader>s", group = "Search", icon = { icon = icons.find.grep, color = "cyan" } },
        { "<leader>sn", group = "Noice", icon = { icon = icons.plugins.noice, color = "purple" } },
        { "<leader>b", group = "Buffer", icon = { icon = icons.find.buffer, color = "orange" } },
        { "<leader>w", group = "Window", icon = { icon = icons.ui.split_v, color = "cyan" } },
        { "<leader>u", group = "UI/Toggle", icon = { icon = icons.ui.config, color = "yellow" } },
        { "<leader>l", group = "Lazy", icon = { icon = icons.ui.lazy, color = "purple" } },
        { "<leader>x", group = "Diagnostics", icon = { icon = icons.find.diagnostic, color = "red" } },

        -- File/Find individual keymaps
        { "<leader>ff", desc = "Find File", icon = { icon = icons.find.file, color = "blue" } },
        { "<leader>fg", desc = "Live Grep", icon = { icon = icons.find.grep, color = "cyan" } },
        { "<leader>fb", desc = "Buffers", icon = { icon = icons.find.buffer, color = "purple" } },
        { "<leader>fh", desc = "Help Tags", icon = { icon = icons.find.help, color = "yellow" } },
        { "<leader>fr", desc = "Recent Files", icon = { icon = icons.ui.recent, color = "orange" } },
        { "<leader>fc", desc = "Config Files", icon = { icon = icons.ui.config, color = "grey" } },
        { "<leader>fn", desc = "New File", icon = { icon = icons.ui.new_file, color = "green" } },

        -- Search individual keymaps
        { "<leader>sd", desc = "Document Diagnostics", icon = { icon = icons.find.diagnostic, color = "red" } },
        { "<leader>sD", desc = "Workspace Diagnostics", icon = { icon = icons.find.diagnostic, color = "red" } },
        { "<leader>sk", desc = "Keymaps", icon = { icon = icons.find.keymap, color = "blue" } },
        { "<leader>sc", desc = "Command History", icon = { icon = icons.find.cmd_hist, color = "orange" } },
        { "<leader>sC", desc = "Commands", icon = { icon = icons.find.cmd, color = "orange" } },
        { "<leader>sr", desc = "Resume Last", icon = { icon = icons.find.resume, color = "purple" } },
        { "<leader>sR", desc = "Search and Replace", icon = { icon = icons.ui.replace, color = "green" } },
        { "<leader>st", desc = "Todos", icon = { icon = icons.plugins.todo, color = "yellow" } },

        -- Noice (under <leader>sn subgroup)
        { "<leader>snl", desc = "Noice Last Message", icon = { icon = icons.find.cmd_hist, color = "purple" } },
        { "<leader>snh", desc = "Noice History", icon = { icon = icons.ui.recent, color = "purple" } },
        { "<leader>sna", desc = "Noice All", icon = { icon = icons.find.cmd, color = "purple" } },
        { "<leader>snd", desc = "Dismiss All", icon = { icon = icons.ui.close, color = "red" } },

        -- Buffer individual keymaps
        {
          "<leader>bd",
          desc = "Delete Buffer",
          icon = { icon = icons.diagnostics.Error, color = "red" },
        },
        {
          "<leader>bD",
          desc = "Delete Buffer & Window",
          icon = { icon = icons.diagnostics.Error, color = "red" },
        },
        {
          "<leader>bo",
          desc = "Delete Other Buffers",
          icon = { icon = icons.ui.close, color = "grey" },
        },
        {
          "<leader>bb",
          desc = "Switch to Other Buffer",
          icon = { icon = icons.find.buffer, color = "cyan" },
        },
        {
          "<leader>`",
          desc = "Switch to Other Buffer",
          icon = { icon = icons.find.buffer, color = "cyan" },
        },
        -- Bufferline-owned buffer operations
        {
          "<leader>bp",
          desc = "Toggle Pin Buffer",
          icon = { icon = icons.ui.pin, color = "yellow" },
        },
        {
          "<leader>bP",
          desc = "Delete Non-Pinned Buffers",
          icon = { icon = icons.ui.close, color = "red" },
        },
        {
          "<leader>br",
          desc = "Delete Buffers to the Right",
          icon = { icon = icons.misc.arrow_right, color = "orange" },
        },
        {
          "<leader>bl",
          desc = "Delete Buffers to the Left",
          icon = { icon = icons.misc.arrow_left, color = "orange" },
        },
        {
          "<leader>bj",
          desc = "Pick Buffer",
          icon = { icon = icons.ui.eye, color = "cyan" },
        },
        -- Bufferline buffer movement (capital [B/]B)
        { "[B", desc = "Move Buffer Left", icon = { icon = icons.misc.arrow_left, color = "orange" } },
        { "]B", desc = "Move Buffer Right", icon = { icon = icons.misc.arrow_right, color = "orange" } },

        -- Window individual keymaps
        { "<leader>wd", desc = "Delete Window", icon = { icon = icons.diagnostics.Error, color = "red" } },
        { "<leader>ws", desc = "Split Below", icon = { icon = icons.ui.split_h, color = "cyan" } },
        { "<leader>wv", desc = "Split Right", icon = { icon = icons.ui.split_v, color = "cyan" } },
        { "<leader>wm", desc = "Maximize Window", icon = { icon = icons.ui.maximize, color = "green" } },
        { "<leader>w=", desc = "Balance Windows", icon = { icon = icons.git.diff, color = "cyan" } },

        -- UI / toggle individual keymaps
        { "<leader>ul", desc = "Toggle Line Numbers", icon = { icon = icons.statusline.line, color = "blue" } },
        { "<leader>uL", desc = "Toggle Relative Numbers", icon = { icon = icons.statusline.line, color = "blue" } },
        { "<leader>uw", desc = "Toggle Word Wrap", icon = { icon = icons.ui.wrap, color = "cyan" } },
        { "<leader>us", desc = "Toggle Spelling", icon = { icon = icons.find.spell, color = "yellow" } },
        { "<leader>ud", desc = "Toggle Diagnostics", icon = { icon = icons.lsp.diagnostic, color = "red" } },
        { "<leader>uc", desc = "Toggle Color Column", icon = { icon = icons.ui.palette, color = "cyan" } },
        { "<leader>uh", desc = "Toggle Inlay Hints", icon = { icon = icons.diagnostics.Hint, color = "yellow" } },
        { "<leader>uf", desc = "Toggle Format on Save", icon = { icon = icons.lsp.format, color = "blue" } },
        { "<leader>un", desc = "Dismiss Notifications", icon = { icon = icons.find.notify, color = "grey" } },
        { "<leader>ur", desc = "Redraw / Clear hlsearch", icon = { icon = icons.ui.refresh, color = "cyan" } },
        { "<leader>ui", desc = "Inspect Pos", icon = { icon = icons.ui.eye, color = "green" } },
        { "<leader>uI", desc = "Inspect Tree", icon = { icon = icons.find.treesitter, color = "green" } },

        -- Lazy individual keymaps
        { "<leader>ll", desc = "Lazy Home", icon = { icon = icons.ui.lazy, color = "purple" } },
        { "<leader>lu", desc = "Update Plugins", icon = { icon = icons.ui.refresh, color = "cyan" } },
        { "<leader>ls", desc = "Sync Plugins", icon = { icon = icons.git.diff, color = "cyan" } },
        { "<leader>lc", desc = "Check Plugins", icon = { icon = icons.diagnostics.Info, color = "blue" } },
        { "<leader>lp", desc = "Profile", icon = { icon = icons.ui.info, color = "cyan" } },

        -- Diagnostics / Trouble individual keymaps (trouble.nvim owns the
        -- bindings; we register icons + descs here so which-key surfaces them).
        {
          "<leader>xx",
          desc = "Diagnostics (Trouble)",
          icon = { icon = icons.find.diagnostic, color = "red" },
        },
        {
          "<leader>xX",
          desc = "Buffer Diagnostics (Trouble)",
          icon = { icon = icons.find.diagnostic, color = "red" },
        },
        {
          "<leader>xL",
          desc = "Location List (Trouble)",
          icon = { icon = icons.find.loclist, color = "yellow" },
        },
        {
          "<leader>xQ",
          desc = "Quickfix List (Trouble)",
          icon = { icon = icons.find.quickfix, color = "yellow" },
        },
        {
          "<leader>xt",
          desc = "Todo (Trouble)",
          icon = { icon = icons.plugins.todo, color = "yellow" },
        },

        -- Bracket navigation (severity-filtered diagnostics + trouble/quickfix + todos + parameter motion)
        { "]e", desc = "Next Error", icon = { icon = icons.diagnostics.Error, color = "red" } },
        { "[e", desc = "Prev Error", icon = { icon = icons.diagnostics.Error, color = "red" } },
        { "]w", desc = "Next Warning", icon = { icon = icons.diagnostics.Warn, color = "yellow" } },
        { "[w", desc = "Prev Warning", icon = { icon = icons.diagnostics.Warn, color = "yellow" } },
        { "]q", desc = "Next Trouble/Quickfix", icon = { icon = icons.find.quickfix, color = "yellow" } },
        { "[q", desc = "Prev Trouble/Quickfix", icon = { icon = icons.find.quickfix, color = "yellow" } },
        { "]t", desc = "Next Todo Comment", icon = { icon = icons.plugins.todo, color = "yellow" } },
        { "[t", desc = "Prev Todo Comment", icon = { icon = icons.plugins.todo, color = "yellow" } },
        { "]a", desc = "Next Parameter", icon = { icon = icons.kinds.TypeParameter, color = "cyan" } },
        { "[a", desc = "Prev Parameter", icon = { icon = icons.kinds.TypeParameter, color = "cyan" } },
        { "]A", desc = "Next Parameter End", icon = { icon = icons.kinds.TypeParameter, color = "cyan" } },
        { "[A", desc = "Prev Parameter End", icon = { icon = icons.kinds.TypeParameter, color = "cyan" } },

        -- Top-level keymaps without a group prefix
        { "<leader>K", desc = "Keywordprg", icon = { icon = icons.ui.help, color = "yellow" } },
        { "<leader>?", desc = "Buffer Keymaps (which-key)", icon = { icon = icons.find.keymap, color = "cyan" } },
        { "<leader>.", desc = "Toggle Scratch Buffer", icon = { icon = icons.ui.clipboard, color = "green" } },
        { "<leader>S", desc = "Select Scratch Buffer", icon = { icon = icons.find.buffer, color = "green" } },

        -- Commenting (gco/gcO)
        { "gco", desc = "Add Comment Below", icon = { icon = icons.ui.pencil, color = "green" } },
        { "gcO", desc = "Add Comment Above", icon = { icon = icons.ui.pencil, color = "green" } },
      },
    },
  },

  {
    "ibhagwan/fzf-lua",
    -- File icons via mini.icons (mocking nvim-web-devicons through
    -- package.preload, configured in ui.lua).
    dependencies = { "nvim-mini/mini.icons" },
    cmd = "FzfLua",
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find File" },
      { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
      { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fc", "<cmd>FzfLua files cwd=~/.config/nvim<cr>", desc = "Config Files" },
      { "<leader>sd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Document Diagnostics" },
      { "<leader>sD", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
      { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
      { "<leader>sc", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
      { "<leader>sC", "<cmd>FzfLua commands<cr>", desc = "Commands" },
      { "<leader>sr", "<cmd>FzfLua resume<cr>", desc = "Resume Last" },
    },
    opts = {
      -- Global fzf-lua options
      "default-title",
      fzf_colors = true,
      winopts = {
        height = 0.85,
        width = 0.80,
        row = 0.35,
        col = 0.50,
        border = "rounded",
        preview = {
          border = "rounded",
          layout = "flex",
          flip_columns = 120,
          scrollbar = "float",
        },
      },
      files = {
        cwd_prompt = false,
        git_icons = true,
        file_icons = true,
      },
      grep = {
        git_icons = true,
        file_icons = true,
        no_header = true, -- hide the "<ctrl-g> to Fuzzy Search" tip
        no_header_i = true,
      },
      lsp = {
        symbols = {
          symbol_icons = true,
        },
      },
    },
  },

  -- flash.nvim: jump anywhere visible with a 2-character label. `s` jumps,
  -- `S` does treesitter-aware structural jump (whole nodes), `r`/`R` are
  -- operator-pending variants for remote/treesitter motions, and `<C-s>`
  -- toggles flash search inside the cmdline.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = "c",
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },

  -- todo-comments.nvim: highlights TODO/FIXME/HACK/BUG/NOTE/WARN/PERF
  -- comments in distinct colors and provides ]t/[t navigation. Pairs with
  -- trouble.nvim (`<leader>xt`) and fzf-lua (`<leader>st`) for project-wide
  -- listing.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoTrouble", "TodoFzfLua" },
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next Todo Comment",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Prev Todo Comment",
      },
      { "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "Todos" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
    },
  },

  -- trouble.nvim: unified UI for diagnostics, quickfix, location list, LSP
  -- references, document/workspace symbols, and todo-comments. Replaces the
  -- old vanilla quickfix toggles that used to live in keymaps.lua. The
  -- ]q/[q bindings are smart -- they navigate the trouble window when it's
  -- open, otherwise fall back to :cprev/:cnext for vanilla quickfix.
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok and err then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Prev Trouble/Quickfix",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok and err then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next Trouble/Quickfix",
      },
    },
  },

  -- grug-far.nvim: project-wide search & replace UI. Open a buffer, type a
  -- search and replacement, see all matches across all files, accept changes
  -- interactively. Bound to <leader>sR (capital R) so it doesn't collide
  -- with fzf-lua's <leader>sr "Resume Last".
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sR",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "x" },
        desc = "Search and Replace",
      },
    },
  },

  -- harpoon (branch harpoon2): quick file marks. Mark files with
  -- <leader>H, jump to marks 1-9 with <leader>1..<leader>9, or open the
  -- pickable menu with <leader>h. Mental model: browser tabs but for
  -- files -- once you're working in a known set of 3-9 files, jumping by
  -- mark number is faster than fuzzy finding or buffer cycling.
  --
  -- save_on_toggle persists the mark list across sessions so the
  -- numbered jumps survive a restart for any project the user has
  -- harpooned files in. The menu width adapts to the current window
  -- width minus a small margin so the popup never feels cramped.
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    keys = function()
      local keys = {
        {
          "<leader>H",
          function()
            require("harpoon"):list():add()
          end,
          desc = "Harpoon File",
        },
        {
          "<leader>h",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon Quick Menu",
        },
      }
      for i = 1, 9 do
        table.insert(keys, {
          "<leader>" .. i,
          function()
            require("harpoon"):list():select(i)
          end,
          desc = "Harpoon to File " .. i,
        })
      end
      return keys
    end,
  },

  -- outline.nvim: persistent symbol outline sidebar. Toggle with
  -- <leader>cs (which previously dumped vim.lsp.buf.document_symbol to
  -- the quickfix list -- a sidebar tree is much better UX). The icons
  -- table is sourced from icons.kinds so the outline tree uses the same
  -- glyphs as blink.cmp's completion popup.
  --
  -- For ad-hoc fuzzy symbol jumping the user still has fzf-lua's
  -- lsp_document_symbols command (no keybind, run via :FzfLua); outline
  -- is for the "I want to keep this open while navigating a 1500-line
  -- file" workflow.
  {
    "hedyhli/outline.nvim",
    cmd = { "Outline", "OutlineOpen", "OutlineClose" },
    keys = {
      { "<leader>cs", "<cmd>Outline<cr>", desc = "Toggle Outline" },
    },
    opts = function()
      local defaults = require("outline.config").defaults
      local opts = {
        symbols = {
          icons = {},
        },
        keymaps = {
          up_and_jump = "<up>",
          down_and_jump = "<down>",
        },
      }
      -- Merge icons.kinds into outline's per-kind icon table. Falls back
      -- to the upstream default for any kind we haven't defined.
      for kind, symbol in pairs(defaults.symbols.icons) do
        opts.symbols.icons[kind] = {
          icon = (icons.kinds[kind] or symbol.icon):gsub("%s+$", ""),
          hl = symbol.hl,
        }
      end
      return opts
    end,
  },

  -- which-key: extend spec with harpoon + outline icons.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = (function()
        local spec = {
          { "<leader>H", desc = "Harpoon File", icon = { icon = icons.ui.pin, color = "yellow" } },
          { "<leader>h", desc = "Harpoon Quick Menu", icon = { icon = icons.ui.menu, color = "yellow" } },
          { "<leader>cs", desc = "Toggle Outline", icon = { icon = icons.find.lsp_symbols, color = "green" } },
        }
        for i = 1, 9 do
          spec[#spec + 1] = {
            "<leader>" .. i,
            desc = "Harpoon to File " .. i,
            icon = { icon = icons.ui.pin, color = "yellow" },
          }
        end
        return spec
      end)(),
    },
  },
}
