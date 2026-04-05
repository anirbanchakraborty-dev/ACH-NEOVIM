-- UI: Dashboard (snacks.nvim)
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        width = 64,
        preset = {
          header = [[
      █████╗  ██████╗██╗  ██╗      ██╗   ██╗██╗███╗   ███╗
     ██╔══██╗██╔════╝██║  ██║      ██║   ██║██║████╗ ████║
     ███████║██║     ███████║█████╗██║   ██║██║██╔████╔██║
     ██╔══██║██║     ██╔══██║╚════╝╚██╗ ██╔╝██║██║╚██╔╝██║
     ██║  ██║╚██████╗██║  ██║       ╚████╔╝ ██║██║ ╚═╝ ██║
     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝        ╚═══╝  ╚═╝╚═╝     ╚═╝

              Neovim, supercharged. ]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
