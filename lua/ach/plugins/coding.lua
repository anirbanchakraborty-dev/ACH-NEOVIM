-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/coding/blink.lua and
-- lua/lazyvim/plugins/coding.lua, for the blink.cmp and mini.ai specs.

return {
  -- The completion menu, fed by the language server, file paths, snippets and words in open buffers.
  {
    "saghen/blink.cmp",
    -- Releases carry the compiled matcher; scripts/fetch-matcher downloads the one for this tag.
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts_extend = { "sources.default" },
    opts = {
      keymap = { preset = "enter" },
      -- The kind icons are the icon database's, bare, since blink adds its own spacing.
      appearance = { nerd_font_variant = "mono", kind_icons = require("ach.icons").kinds },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
        menu = { draw = { treesitter = { "lsp" } } },
      },
      signature = { enabled = true },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          -- The repository's own folder, so the snippets are found through the link and under nvim -u alike.
          snippets = { opts = { search_paths = { vim.g.ach_root .. "/snippets" } } },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = { enabled = true },
    },
  },

  -- Closes brackets and quotes as they open.
  {
    "nvim-mini/mini.pairs",
    event = "VeryLazy",
    opts = { modes = { insert = true, command = true, terminal = false } },
  },

  -- Text objects: af and if for a function, ac and ic for a class, ao and io for a block,
  -- au and iu for a call, on top of mini.ai's brackets, quotes and arguments.
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        -- Look this far for an object, so a long function still counts as one.
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          u = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  -- The right comment marker inside embedded languages, such as Lua inside Markdown.
  { "folke/ts-comments.nvim", event = "VeryLazy", opts = {} },
}
