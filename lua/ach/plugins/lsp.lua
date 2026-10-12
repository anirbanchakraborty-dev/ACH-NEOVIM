-- nvim-lspconfig supplies each server's command, file types and root
-- markers; SchemaStore.nvim the JSON and YAML schema catalogue; lazydev.nvim
-- the types of Neovim's API, snacks and lazy.nvim when editing this
-- configuration, as a completion source.
return {
  {
    "neovim/nvim-lspconfig",
    -- Loaded as the first file is read, so the diagnostics' look and the
    -- servers' settings are in place before anything reports on it, and with
    -- no file after the first screen. Its lsp/ folder must be on the runtime
    -- path before the first server is enabled, so lua/ach/lsp.lua loads it
    -- then too, for a file type set on a buffer with no file.
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
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
