-- conform.nvim runs each file type's formatters. lua/ach/format.lua decides
-- which, with what arguments, and when.
return {
  {
    "stevearc/conform.nvim",
    -- Loaded when a file opens rather than at the first save, so the status
    -- bar can name the formatter from the start.
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true }) end,
        mode = { "n", "x" },
        desc = "Format",
      },
      {
        "<leader>cF",
        function() require("conform").format({ formatters = { "injected" }, async = true }) end,
        mode = { "n", "x" },
        desc = "Format Injected Langs",
      },
    },
    init = function() require("ach.format").setup() end,
    opts = function() return require("ach.format").opts() end,
  },
}
