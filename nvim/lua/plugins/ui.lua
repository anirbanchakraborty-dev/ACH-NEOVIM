-- UI: Dashboard, Noice, Rainbow Delimiters, Indent Lines, Colorizer
local icons = require("config.icons")

return {
  -- Dashboard (snacks.nvim)
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
 █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝██║  ██║
███████║██║     ███████║
██╔══██║██║     ██╔══██║
██║  ██║╚██████╗██║  ██║
╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

Powered by 󰏖 Lazy Package Manager ]],
          keys = {
            { icon = icons.ui.find_file .. " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = icons.ui.new_file .. " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = icons.ui.find_text .. " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = icons.ui.recent .. " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = icons.ui.config .. " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = icons.ui.lazy .. " ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = icons.ui.quit .. " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup", icon = icons.ui.startup .. " " },
        },
      },
      indent = {
        enabled = true,
        char = "│",
        only_scope = false,
        hl = "SnacksIndentDim",
        scope = {
          enabled = true,
          char = "│",
          hl = {
            "RainbowDelimiterRed",
            "RainbowDelimiterOrange",
            "RainbowDelimiterYellow",
            "RainbowDelimiterGreen",
            "RainbowDelimiterCyan",
            "RainbowDelimiterBlue",
            "RainbowDelimiterViolet",
          },
        },
        chunk = {
          enabled = true,
          hl = {
            "RainbowDelimiterRed",
            "RainbowDelimiterOrange",
            "RainbowDelimiterYellow",
            "RainbowDelimiterGreen",
            "RainbowDelimiterCyan",
            "RainbowDelimiterBlue",
            "RainbowDelimiterViolet",
          },
          char = {
            corner_top = "┌",
            corner_bottom = "└",
            horizontal = "─",
            vertical = "│",
            arrow = ">",
          },
        },
        animate = {
          enabled = true,
          style = "out",
          easing = "linear",
          duration = {
            step = 20,
            total = 500,
          },
        },
      },
    },
    config = function(_, opts)
      -- Set up rainbow highlight groups for indent/scope
      vim.api.nvim_set_hl(0, "SnacksIndentDim", { fg = "#1a2a3a" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#FF5370" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#F78C6C" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#FFCB6B" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#C3E88D" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#89DDFF" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#82AAFF" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#C792EA" })
      require("snacks").setup(opts)
    end,
  },

  -- Noice (floating cmdline, messages, notifications)
  {
    "folke/noice.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = "VeryLazy",
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
          cmdline = { icon = icons.noice.cmdline },
          search_down = { icon = icons.noice.search_down },
          search_up = { icon = icons.noice.search_up },
          filter = { icon = icons.noice.filter },
          lua = { icon = icons.noice.lua },
          help = { icon = icons.noice.help },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        progress = {
          enabled = true,
        },
        hover = {
          enabled = true,
        },
        signature = {
          enabled = true,
        },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      views = {
        cmdline_popup = {
          position = {
            row = "40%",
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "rounded",
          },
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            kind = "",
            find = "written",
          },
          opts = { skip = true },
        },
      },
    },
  },

  -- Rainbow Delimiters (treesitter-based rainbow brackets)
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "BufReadPost",
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
          vim = rainbow.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterOrange",
          "RainbowDelimiterYellow",
          "RainbowDelimiterGreen",
          "RainbowDelimiterCyan",
          "RainbowDelimiterBlue",
          "RainbowDelimiterViolet",
        },
      }
    end,
  },

  -- Colorizer (inline color preview)
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = {
      filetypes = {
        "*",
        css = { css = true },
        scss = { css = true },
        html = { css = true },
        javascript = { css = true },
        typescript = { css = true },
        lua = { css = true },
      },
      user_default_options = {
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        AARRGGBB = true,
        names = false,
        rgb_fn = true,
        hsl_fn = true,
        css = false,
        css_fn = false,
        mode = "background",
        virtualtext = "■",
      },
    },
  },
}
