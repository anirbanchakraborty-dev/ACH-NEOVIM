-- nvim-lint runs each file type's linters. lua/ach/lint.lua decides which,
-- and when.
return {
  {
    "mfussenegger/nvim-lint",
    -- Loaded when a file opens, so the first file is linted and the status
    -- bar can name its linters from the start.
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function() require("ach.lint").setup() end,
  },
}
