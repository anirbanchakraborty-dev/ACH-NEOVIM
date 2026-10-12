-- Two tools that are not about the file being edited: Intel's manual on
-- Space c x and the feed reader on Space N. Both are keys on snacks.nvim,
-- which is already loaded at start, so neither adds a plugin.
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>cx",
        function() require("ach.x86").lookup() end,
        desc = "x86 Manual",
      },
      {
        "<leader>N",
        function() require("ach.news").open() end,
        desc = "News",
      },
    },
  },
}
