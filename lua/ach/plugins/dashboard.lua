-- snacks.nvim loads first of all: its notifier must catch the first message,
-- and its dashboard opens at UIEnter, after a private .nvim.lua has had the
-- chance to add a button. Other plugin files add their own snacks options.
return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      notifier = { enabled = true, timeout = 3000 },
      dashboard = {
        enabled = true,
        sections = {
          function(self) return require("ach.dashboard").sections(self) end,
        },
      },
    },
  },
}
