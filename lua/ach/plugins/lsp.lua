-- nvim-lspconfig supplies each server's command, file types and root
-- markers; SchemaStore.nvim the JSON and YAML schema catalogue; lazydev.nvim
-- the types of Neovim's API, snacks and lazy.nvim when editing this
-- configuration, as a completion source.
return {
  {
    "neovim/nvim-lspconfig",
    -- Not lazy: its lsp/ folder must be on the runtime path before the first
    -- server is enabled, which happens during startup when a file is named on
    -- the command line. Loading it runs one small plugin file.
    lazy = false,
    config = function() require("ach.lsp").setup() end,
  },

  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        "lazy.nvim",
      },
    },
  },

  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = { "lazydev" },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
    },
  },
}
