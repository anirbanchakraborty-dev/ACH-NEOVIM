-- Colorscheme: tokyonight with deep ocean palette

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
      sidebars = { "qf", "help", "neo-tree", "terminal", "trouble", "Outline" },

      on_colors = function(colors)
        colors.bg = "#011628"
        colors.bg_dark = "#011423"
        colors.bg_highlight = "#143652"
        colors.bg_search = "#0A64AC"
        colors.bg_visual = "#275378"
        colors.fg = "#CBE0F0"
        colors.fg_dark = "#B4D0E9"
        colors.fg_gutter = "#627E97"
        colors.border = "#547998"
      end,

      on_highlights = function(hl, c)
        local bg_dark = "#011423"
        local fg = "#CBE0F0"
        local border = "#547998"
        local bg_hl = "#143652"
        local bg_search = "#0A64AC"

        -- Floating windows (Lazy, Mason, LSP info, etc.)
        hl.NormalFloat = { bg = bg_dark, fg = fg }
        hl.FloatBorder = { bg = bg_dark, fg = border }
        hl.FloatTitle = { bg = bg_dark, fg = fg, bold = true }

        -- Fuzzy finder (fzf-lua)
        hl.FzfLuaNormal = { bg = bg_dark, fg = fg }
        hl.FzfLuaBorder = { bg = bg_dark, fg = border }
        hl.FzfLuaTitle = { bg = bg_search, fg = fg, bold = true }
        hl.FzfLuaPreviewNormal = { bg = bg_dark }
        hl.FzfLuaPreviewBorder = { bg = bg_dark, fg = border }
        hl.FzfLuaPreviewTitle = { bg = bg_dark, fg = fg, bold = true }
        hl.FzfLuaCursorLine = { bg = bg_hl }
        hl.FzfLuaScrollFloatFull = { fg = border }
        hl.FzfLuaScrollFloatEmpty = { fg = bg_dark }
        hl.FzfLuaHeaderBind = { fg = c.green }
        hl.FzfLuaHeaderText = { fg = c.orange }

        -- Popup / completion menu
        hl.Pmenu = { bg = bg_dark, fg = fg }
        hl.PmenuSel = { bg = bg_hl }
        hl.PmenuSbar = { bg = bg_dark }
        hl.PmenuThumb = { bg = border }

        -- Cursor line and line numbers
        hl.CursorLine = { bg = bg_hl }
        hl.CursorLineNr = { fg = fg, bold = true }
        hl.LineNr = { fg = "#627E97" }

        -- Search
        hl.Search = { bg = bg_search, fg = fg }
        hl.IncSearch = { bg = c.orange, fg = bg_dark }
        hl.CurSearch = { bg = c.orange, fg = bg_dark }

        -- Visual selection
        hl.Visual = { bg = "#275378" }

        -- Window separators
        hl.WinSeparator = { fg = border }

        -- Telescope (fallback if ever used)
        hl.TelescopeNormal = { bg = bg_dark, fg = fg }
        hl.TelescopeBorder = { bg = bg_dark, fg = border }
        hl.TelescopePromptNormal = { bg = bg_hl }
        hl.TelescopePromptBorder = { bg = bg_hl, fg = bg_hl }
        hl.TelescopePromptTitle = { bg = bg_search, fg = fg }
        hl.TelescopePreviewTitle = { bg = bg_dark, fg = fg }
        hl.TelescopeResultsTitle = { bg = bg_dark, fg = fg }
        hl.TelescopeSelection = { bg = bg_hl }

        -- Lazy.nvim UI
        hl.LazyNormal = { bg = bg_dark, fg = fg }
        hl.LazyButton = { bg = bg_hl, fg = fg }
        hl.LazyButtonActive = { bg = bg_search, fg = fg, bold = true }
        hl.LazyH1 = { bg = bg_search, fg = fg, bold = true }
        hl.LazySpecial = { fg = c.blue }

        -- Mason UI
        hl.MasonNormal = { bg = bg_dark, fg = fg }
        hl.MasonHeader = { bg = bg_search, fg = fg, bold = true }
        hl.MasonHighlight = { fg = c.blue }
        hl.MasonHighlightBlock = { bg = bg_search, fg = fg }
        hl.MasonHighlightBlockBold = { bg = bg_search, fg = fg, bold = true }

        -- WhichKey
        hl.WhichKey = { fg = c.blue }
        hl.WhichKeyGroup = { fg = c.cyan }
        hl.WhichKeyDesc = { fg = fg }
        hl.WhichKeyFloat = { bg = bg_dark }
        hl.WhichKeyBorder = { bg = bg_dark, fg = border }
        hl.WhichKeySeparator = { fg = "#627E97" }
        hl.WhichKeyValue = { fg = "#627E97" }

        -- Diagnostics
        hl.DiagnosticVirtualTextError = { bg = "#1a0a1a", fg = c.error }
        hl.DiagnosticVirtualTextWarn = { bg = "#1a1a0a", fg = c.warning }
        hl.DiagnosticVirtualTextInfo = { bg = "#0a1a1a", fg = c.info }
        hl.DiagnosticVirtualTextHint = { bg = "#0a1a2a", fg = c.hint }

        -- Git signs
        hl.GitSignsAdd = { fg = c.green }
        hl.GitSignsChange = { fg = c.blue }
        hl.GitSignsDelete = { fg = c.red }

        -- Statusline (lualine reads these)
        hl.StatusLine = { bg = bg_dark, fg = fg }
        hl.StatusLineNC = { bg = bg_dark, fg = "#627E97" }

        -- Tabline / bufferline
        hl.TabLine = { bg = bg_dark, fg = "#627E97" }
        hl.TabLineSel = { bg = bg_hl, fg = fg }
        hl.TabLineFill = { bg = bg_dark }

        -- Snacks dashboard
        hl.SnacksDashboardHeader = { fg = c.blue }
        hl.SnacksDashboardIcon = { fg = c.blue }
        hl.SnacksDashboardKey = { fg = c.orange }
        hl.SnacksDashboardDesc = { fg = fg }
        hl.SnacksDashboardFooter = { fg = "#627E97" }

        -- Notify
        hl.NotifyBackground = { bg = bg_dark }

        -- Noice
        hl.NoiceCmdlinePopup = { bg = bg_dark, fg = fg }
        hl.NoiceCmdlinePopupBorder = { bg = bg_dark, fg = border }

        -- Trouble
        hl.TroubleNormal = { bg = bg_dark, fg = fg }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
