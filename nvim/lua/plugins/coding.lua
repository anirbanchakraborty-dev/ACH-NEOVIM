-- Coding: the IDE interaction layer. Completion + signature help + snippets
-- via blink.cmp, autopairs via mini.pairs, surround operator via mini.surround,
-- richer a/i text objects via mini.ai, and auto-closing HTML/JSX tags via
-- nvim-ts-autotag.
--
-- blink.cmp is listed as a dependency of nvim-lspconfig in lsp.lua so it
-- loads before the LSP config runs and its get_lsp_capabilities() can be
-- merged into vim.lsp.config("*"). That way every language server learns
-- about snippet + resolve support from the get-go.

local icons = require("config.icons")

return {
  -- blink.cmp: Rust-powered completion engine. Ships its own snippet engine
  -- that consumes friendly-snippets directly (no LuaSnip needed).
  {
    "saghen/blink.cmp",
    version = "*", -- pull the pre-built fuzzy matcher binary
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    event = "InsertEnter",
    opts = {
      -- "enter" preset: <CR> accepts the current selection (falls back to
      -- inserting a newline when no menu is open). Tab/Shift-Tab navigate
      -- snippet placeholders.
      keymap = {
        preset = "enter",
        ["<Tab>"]   = { "snippet_forward",  "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "lazydev" },
        providers = {
          -- lazydev.nvim feeds Neovim runtime / plugin globals into completion
          -- when editing Lua config files. score_offset boosts these above
          -- generic LSP results so vim.api / Snacks.* surface near the top.
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },

      -- Inline signature help as you type function arguments.
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },

      completion = {
        -- Insert () (and placeholders) after accepting a function.
        accept = {
          auto_brackets = { enabled = true },
        },

        -- Doc popup auto-opens after a short delay on the highlighted item.
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },

        -- VSCode-style inline preview of the current selection.
        ghost_text = { enabled = true },

        list = {
          selection = { preselect = true, auto_insert = false },
        },

        menu = {
          border = "rounded",
          winblend = 0,
          draw = {
            treesitter = { "lsp" },
          },
        },
      },
    },
  },

  -- mini.pairs: autopairs. ( -> (), [ -> [], " -> "", etc. Smart about
  -- context so it doesn't double up on existing closers, doesn't autopair
  -- inside string nodes, and handles markdown code fences specially.
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- Skip autopair when the next character is one of these (alphanumerics,
      -- existing quotes/brackets, etc) so we don't double up on identifiers.
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- Skip autopair when the cursor is inside a string treesitter node
      -- (e.g. don't insert a `)` when typing `(` inside a quoted string).
      skip_ts = { "string" },
      -- Skip when there are already more closers than openers on the line.
      skip_unbalanced = true,
      -- Better handling for markdown code fences (```).
      markdown = true,
    },
  },

  -- mini.surround: add / delete / change surroundings under the "gs" prefix.
  -- Left unprefixed (the default "sa/sd/sr/..." conflict with useful s
  -- motions that flash-style plugins rely on), so gs here is a deliberate
  -- mapping choice for clarity.
  {
    "echasnovski/mini.surround",
    event = "BufReadPost",
    opts = {
      mappings = {
        add            = "gsa", -- Add surrounding
        delete         = "gsd", -- Delete surrounding
        find           = "gsf", -- Find surrounding (right)
        find_left      = "gsF", -- Find surrounding (left)
        highlight      = "gsh", -- Highlight surrounding
        replace        = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update n_lines
      },
    },
  },

  -- mini.ai: richer a/i text objects. The custom_textobjects table layers
  -- treesitter-powered targets on top of mini.ai's defaults so daf deletes a
  -- whole function, cic changes inside a class, vao selects an if/loop block,
  -- etc. Tag/digit/usage are regex-based fallbacks that work even without
  -- treesitter parsers loaded.
  {
    "echasnovski/mini.ai",
    event = "BufReadPost",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          -- o: cOde block (conditionals + loops + plain blocks)
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          -- f: Function definition
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          -- c: Class definition
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          -- t: HTML/JSX Tag (regex-based, parser-free)
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          -- d: Digits run
          d = { "%f[%d]%d+" },
          -- u: function call ("Usage")
          u = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  -- nvim-ts-autotag: auto-close and auto-rename HTML / JSX / Vue / Svelte
  -- tags using treesitter, so typing <div> inserts </div> automatically and
  -- renaming the opener also renames the closer.
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    opts = {},
  },

  -- ts-comments.nvim: treesitter-aware commenting on top of Neovim 0.10+'s
  -- built-in `gc` operator. Picks the right commentstring for embedded
  -- languages (JSX inside JS, CSS inside HTML, code fences in markdown, etc.)
  -- so the gco/gcO keymaps in keymaps.lua produce the right comment syntax.
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- lazydev.nvim: teaches lua_ls about the Neovim runtime API plus selected
  -- plugin globals (Snacks, lazy.nvim, vim.uv) so editing this config gets
  -- full completion + type-checking and the "Undefined global vim" warnings
  -- go away. Loads only on Lua filetypes so it has zero startup cost
  -- elsewhere. Pairs with the blink.cmp `lazydev` source above.
  {
    "folke/lazydev.nvim",
    ft  = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim",        words = { "Snacks" } },
        { path = "lazy.nvim",          words = { "Lazy" } },
      },
    },
  },

  -- which-key: announce the surround group under "gs".
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "gs", group = "Surround", icon = { icon = icons.ui.code, color = "cyan" } },
      },
    },
  },
}
