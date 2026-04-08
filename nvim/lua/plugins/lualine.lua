-- UI: lualine (statusline)
local icons = require("config.icons")

return {
  {
    "nvim-lualine/lualine.nvim",
    -- File icons are provided by mini.icons (configured in ui.lua), which
    -- mocks the nvim-web-devicons API via package.preload so lualine's
    -- internal `require("nvim-web-devicons")` transparently uses mini.icons.
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    opts = function()
      local colors = {
        bg = "#011423",
        fg = "#CBE0F0",
        blue = "#82AAFF",
        green = "#C3E88D",
        purple = "#C792EA",
        red = "#FF5370",
        orange = "#F78C6C",
        cyan = "#89DDFF",
        yellow = "#FFCB6B",
        midfg = "#627E97",
        mid = "#143652",
      }

      local ocean_theme = {
        normal = {
          a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        insert = {
          a = { bg = colors.green, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        visual = {
          a = { bg = colors.purple, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        replace = {
          a = { bg = colors.red, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        command = {
          a = { bg = colors.orange, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        terminal = {
          a = { bg = colors.cyan, fg = colors.bg, gui = "bold" },
          b = { bg = colors.mid, fg = colors.fg },
          c = { bg = colors.bg, fg = colors.fg },
        },
        inactive = {
          a = { bg = colors.bg, fg = colors.midfg },
          b = { bg = colors.bg, fg = colors.midfg },
          c = { bg = colors.bg, fg = colors.midfg },
        },
      }

      return {
        options = {
          theme = ocean_theme,
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "snacks_dashboard" },
          },
          component_separators = "",
          section_separators = "",
        },
        sections = {
          lualine_a = {
            {
              "mode",
              padding = { left = 1, right = 1 },
            },
          },
          lualine_b = {
            {
              "branch",
              icon = icons.git.branch,
              padding = { left = 1, right = 1 },
            },
            {
              "diff",
              symbols = {
                added = icons.git.added .. " ",
                modified = icons.git.modified .. " ",
                removed = icons.git.removed .. " ",
              },
              padding = { left = 1, right = 1 },
            },
          },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error .. " ",
                warn = icons.diagnostics.Warn .. " ",
                info = icons.diagnostics.Info .. " ",
                hint = icons.diagnostics.Hint .. " ",
              },
              padding = { left = 1, right = 1 },
            },
            {
              "filename",
              path = 1,
              symbols = {
                modified = "",
                readonly = " [-]",
                unnamed = " [No Name]",
                newfile = " [New]",
              },
              color = function()
                if vim.bo.modified then
                  return { fg = colors.orange, gui = "bold" }
                elseif vim.bo.readonly then
                  return { fg = colors.red }
                else
                  return { fg = colors.cyan }
                end
              end,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_x = {
            {
              function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients == 0 then
                  return ""
                end
                local names = {}
                for _, client in ipairs(clients) do
                  table.insert(names, client.name)
                end
                return icons.plugins.lsp .. " " .. table.concat(names, ", ")
              end,
              color = { fg = colors.midfg },
              padding = { left = 1, right = 1 },
            },
          },
          lualine_y = {
            {
              function()
                local row = vim.fn.line(".")
                local col = vim.fn.virtcol(".")
                return "row: " .. row .. "  col: " .. col
              end,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_z = {
            {
              function()
                return " " .. icons.os.mac .. " "
              end,
              padding = 0,
            },
          },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              "filename",
              path = 1,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_x = {
            {
              function()
                local row = vim.fn.line(".")
                local col = vim.fn.virtcol(".")
                return "row: " .. row .. "  col: " .. col
              end,
              padding = { left = 1, right = 1 },
            },
          },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "neo-tree", "lazy", "fzf", "trouble", "quickfix" },
      }
    end,
  },
}
