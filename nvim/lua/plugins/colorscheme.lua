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

        -- ----------------------------------------------------------------
        -- blink.cmp
        -- The completion menu, documentation popup, and signature help
        -- popup are themed against the deep-ocean palette: bg_dark for
        -- backgrounds, border for borders, bg_hl for the active selection,
        -- and accent colors (orange/blue/cyan) for fuzzy matches and
        -- source labels. Per-kind icon colors mirror the lualine ocean
        -- theme so completion items echo the editor's mode colors.
        -- ----------------------------------------------------------------
        -- Main completion menu
        hl.BlinkCmpMenu = { bg = bg_dark, fg = fg }
        hl.BlinkCmpMenuBorder = { bg = bg_dark, fg = border }
        hl.BlinkCmpMenuSelection = { bg = bg_hl, bold = true }
        hl.BlinkCmpScrollBarThumb = { bg = border }
        hl.BlinkCmpScrollBarGutter = { bg = bg_dark }
        hl.BlinkCmpCursorLine = { bg = bg_hl }

        -- Item rendering
        hl.BlinkCmpLabel = { bg = bg_dark, fg = fg }
        hl.BlinkCmpLabelDeprecated = { bg = bg_dark, fg = "#627E97", strikethrough = true }
        hl.BlinkCmpLabelMatch = { bg = bg_dark, fg = c.orange, bold = true }
        hl.BlinkCmpLabelDescription = { bg = bg_dark, fg = "#627E97" }
        hl.BlinkCmpLabelDetail = { bg = bg_dark, fg = "#627E97" }
        hl.BlinkCmpKind = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpSource = { bg = bg_dark, fg = "#627E97", italic = true }
        hl.BlinkCmpGhostText = { fg = "#627E97", italic = true }

        -- Documentation popup
        hl.BlinkCmpDoc = { bg = bg_dark, fg = fg }
        hl.BlinkCmpDocBorder = { bg = bg_dark, fg = border }
        hl.BlinkCmpDocSeparator = { bg = bg_dark, fg = border }
        hl.BlinkCmpDocCursorLine = { bg = bg_hl }

        -- Signature help popup
        hl.BlinkCmpSignatureHelp = { bg = bg_dark, fg = fg }
        hl.BlinkCmpSignatureHelpBorder = { bg = bg_dark, fg = border }
        hl.BlinkCmpSignatureHelpActiveParameter = { bg = bg_search, fg = fg, bold = true }

        -- Per-kind icon colors. blink.cmp emits BlinkCmpKind<KindName>
        -- groups for each completion kind so we can color the leading
        -- glyph distinctly. Mirrors lualine's ocean theme: blue for
        -- functions/methods, green for fields/values, purple for classes
        -- /interfaces, orange for keywords, cyan for variables.
        hl.BlinkCmpKindFunction = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpKindMethod = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpKindConstructor = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpKindClass = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindInterface = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindStruct = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindEnum = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindEnumMember = { bg = bg_dark, fg = c.green }
        hl.BlinkCmpKindField = { bg = bg_dark, fg = c.green }
        hl.BlinkCmpKindProperty = { bg = bg_dark, fg = c.green }
        hl.BlinkCmpKindValue = { bg = bg_dark, fg = c.green }
        hl.BlinkCmpKindConstant = { bg = bg_dark, fg = c.orange }
        hl.BlinkCmpKindKeyword = { bg = bg_dark, fg = c.orange }
        hl.BlinkCmpKindOperator = { bg = bg_dark, fg = c.orange }
        hl.BlinkCmpKindVariable = { bg = bg_dark, fg = c.cyan }
        hl.BlinkCmpKindModule = { bg = bg_dark, fg = c.cyan }
        hl.BlinkCmpKindNamespace = { bg = bg_dark, fg = c.cyan }
        hl.BlinkCmpKindReference = { bg = bg_dark, fg = c.cyan }
        hl.BlinkCmpKindSnippet = { bg = bg_dark, fg = c.yellow }
        hl.BlinkCmpKindText = { bg = bg_dark, fg = fg }
        hl.BlinkCmpKindFile = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpKindFolder = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpKindUnit = { bg = bg_dark, fg = c.green }
        hl.BlinkCmpKindEvent = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindColor = { bg = bg_dark, fg = c.red }
        hl.BlinkCmpKindTypeParameter = { bg = bg_dark, fg = c.purple }
        hl.BlinkCmpKindLazyDev = { bg = bg_dark, fg = c.cyan }

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

        -- WhichKey (v3)
        hl.WhichKeyNormal = { bg = bg_dark, fg = fg }
        hl.WhichKey = { fg = c.blue }
        hl.WhichKeyGroup = { fg = c.cyan }
        hl.WhichKeyDesc = { fg = fg }
        hl.WhichKeyFloat = { bg = bg_dark }
        hl.WhichKeyBorder = { bg = bg_dark, fg = border }
        hl.WhichKeySeparator = { fg = "#627E97" }
        hl.WhichKeyValue = { fg = "#627E97" }
        hl.WhichKeyTitle = { bg = bg_dark, fg = c.blue, bold = true }
        -- WhichKey icon color classes (mapped via `color = "..."` in spec)
        hl.WhichKeyIconAzure = { fg = "#89DDFF" }
        hl.WhichKeyIconBlue = { fg = "#82AAFF" }
        hl.WhichKeyIconCyan = { fg = "#89DDFF" }
        hl.WhichKeyIconGreen = { fg = "#C3E88D" }
        hl.WhichKeyIconGrey = { fg = "#627E97" }
        hl.WhichKeyIconOrange = { fg = "#F78C6C" }
        hl.WhichKeyIconPurple = { fg = "#C792EA" }
        hl.WhichKeyIconRed = { fg = "#FF5370" }
        hl.WhichKeyIconYellow = { fg = "#FFCB6B" }

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

        -- Snacks indent (dim, unhighlighted guides)
        hl.SnacksIndent = { fg = "#0d1f33" }

        -- Notify
        hl.NotifyBackground = { bg = bg_dark }

        -- Snacks notifier (themed toast notifications)
        hl.SnacksNotifierInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierTrace = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierIconInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierIconWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierIconError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierIconDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierIconTrace = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierTitleInfo = { bg = bg_dark, fg = c.blue, bold = true }
        hl.SnacksNotifierTitleWarn = { bg = bg_dark, fg = c.yellow, bold = true }
        hl.SnacksNotifierTitleError = { bg = bg_dark, fg = c.red, bold = true }
        hl.SnacksNotifierTitleDebug = { bg = bg_dark, fg = c.purple, bold = true }
        hl.SnacksNotifierTitleTrace = { bg = bg_dark, fg = "#627E97", bold = true }
        hl.SnacksNotifierBorderInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierBorderWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierBorderError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierBorderDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierBorderTrace = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierFooterInfo = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierFooterWarn = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierFooterError = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierFooterDebug = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierFooterTrace = { bg = bg_dark, fg = "#627E97" }
        hl.SnacksNotifierHistory = { bg = bg_dark, fg = fg }
        hl.SnacksNotifierHistoryTitle = { bg = bg_dark, fg = c.blue, bold = true }

        -- Noice
        hl.NoiceCmdlinePopup = { bg = bg_dark, fg = fg }
        hl.NoiceCmdlinePopupBorder = { bg = bg_dark, fg = border }

        -- Trouble
        hl.TroubleNormal = { bg = bg_dark, fg = fg }

        -- ----------------------------------------------------------------
        -- Diffview.nvim
        -- ----------------------------------------------------------------
        hl.DiffviewNormal = { bg = bg_dark, fg = fg }
        hl.DiffviewStatusLine = { bg = bg_dark, fg = fg }
        hl.DiffviewStatusLineNC = { bg = bg_dark, fg = "#627E97" }
        hl.DiffviewWinSeparator = { bg = bg_dark, fg = border }
        hl.DiffviewCursorLine = { bg = bg_hl }
        hl.DiffviewNonText = { bg = bg_dark, fg = "#627E97" }
        hl.DiffviewDim1 = { fg = "#627E97" }

        -- File panel (left sidebar listing changed files)
        hl.DiffviewFilePanelTitle = { bg = bg_dark, fg = c.blue, bold = true }
        hl.DiffviewFilePanelCounter = { bg = bg_dark, fg = c.orange, bold = true }
        hl.DiffviewFilePanelFileName = { bg = bg_dark, fg = fg }
        hl.DiffviewFilePanelRootPath = { bg = bg_dark, fg = "#627E97" }
        hl.DiffviewFilePanelPath = { bg = bg_dark, fg = "#627E97" }
        hl.DiffviewFilePanelSelected = { bg = bg_hl, fg = fg, bold = true }
        hl.DiffviewFilePanelInsertions = { bg = bg_dark, fg = c.green }
        hl.DiffviewFilePanelDeletions = { bg = bg_dark, fg = c.red }

        -- File status indicators (next to file names in the panel)
        hl.DiffviewStatusAdded = { fg = c.green }
        hl.DiffviewStatusModified = { fg = c.blue }
        hl.DiffviewStatusDeleted = { fg = c.red }
        hl.DiffviewStatusRenamed = { fg = c.cyan }
        hl.DiffviewStatusUntracked = { fg = c.orange }
        hl.DiffviewStatusIgnored = { fg = "#627E97" }
        hl.DiffviewStatusUnmerged = { fg = c.yellow }
        hl.DiffviewStatusUnknown = { fg = "#627E97" }
        hl.DiffviewStatusBroken = { fg = c.red }
        hl.DiffviewStatusTypeChange = { fg = c.purple }
        hl.DiffviewStatusCopied = { fg = c.cyan }

        -- Folder tree in the file panel
        hl.DiffviewFolderName = { bg = bg_dark, fg = c.blue }
        hl.DiffviewFolderSign = { bg = bg_dark, fg = border }

        -- File history view (commit list)
        hl.DiffviewHash = { fg = c.orange }
        hl.DiffviewReference = { fg = c.purple }
        hl.DiffviewSecondary = { fg = c.cyan }

        -- ----------------------------------------------------------------
        -- git-conflict.nvim
        -- Tinted backgrounds for the three conflict regions, matching the
        -- DiagnosticVirtualText* convention used above (RGB-darkened tints).
        -- Labels (the <<<<<<<, =======, >>>>>>> markers) get a stronger tint
        -- and bold colored text so they're scannable at a glance.
        -- ----------------------------------------------------------------
        hl.GitConflictCurrent = { bg = "#0a1a0a" } -- ours: green tint
        hl.GitConflictCurrentLabel = { bg = "#0a2a0a", fg = c.green, bold = true }
        hl.GitConflictIncoming = { bg = "#0a0a1a" } -- theirs: blue tint
        hl.GitConflictIncomingLabel = { bg = "#0a0a2a", fg = c.blue, bold = true }
        hl.GitConflictAncestor = { bg = "#1a0a1a" } -- common ancestor: purple tint
        hl.GitConflictAncestorLabel = { bg = "#2a0a2a", fg = c.purple, bold = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
