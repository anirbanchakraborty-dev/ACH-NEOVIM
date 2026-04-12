-- Colorscheme: tokyonight driven by the theme loader.
--
-- The active palette is sourced from `lua/themes/init.lua`, which reads
-- vendored NvChad/base46 palette files (dark-only) and adapts them onto
-- tokyonight's `colors.*` slots. Every highlight override below
-- references `c.*` (tokyonight's colors table) rather than hardcoded hex
-- values, so swapping themes via `<leader>uC` re-applies the full UI
-- against the new palette. The default theme is `deep-ocean`
-- (ACH-NEOVIM's signature palette, authored in the same base46 format
-- and stored alongside the vendored themes at
-- `lua/themes/nvchad/deep-ocean.lua`).
--
-- The picker lives at `<leader>uC` and uses snacks.picker with live
-- preview. Cycle forward/back via `<leader>uN` / `<leader>uP`.

local icons = require("config.icons")
local themes = require("themes")

-- Initial palette load happens at module require time so tokyonight's
-- on_colors closure below has a populated `themes.current_palette` the
-- first time it fires.
themes.setup()

-- ---------------------------------------------------------------
-- Theme picker
-- Snacks.picker with a custom preview that calls themes.preview() on
-- cursor move and restores the original theme if the picker is cancelled.
-- ---------------------------------------------------------------
local function open_picker()
  local list = themes.list()
  local items = {}
  for _, it in ipairs(list) do
    table.insert(items, {
      text = it.name,
      preview = { text = it.name, ft = "text" },
    })
  end

  -- Remember the theme we opened with so cancellation (Esc / window
  -- close without confirm) can restore it.
  local original = themes.current_name
  local committed = false

  Snacks.picker.pick({
    source = "ach-themes",
    items = items,
    format = function(item)
      local ret = {}
      ret[#ret + 1] = { item.text, "Normal" }
      return ret
    end,
    preview = function(ctx)
      -- Live-apply the highlighted theme (side effect, not persistence).
      if ctx.item and ctx.item.text then
        themes.preview(ctx.item.text)
      end
      -- Render summary content via snacks' preview helpers -- directly
      -- calling `nvim_buf_set_lines(ctx.buf, ...)` fails with "Buffer is
      -- not 'modifiable'" because the preview buffer is created nomodifiable
      -- and only `ctx.preview:set_lines()` knows to flip the flag around
      -- the write. Pattern mirrors snacks/picker/preview.lua:M.preview.
      ctx.preview:reset()
      ctx.preview:set_lines({
        "Theme: " .. ctx.item.text,
        "",
        "<CR>  apply",
        "<Esc> cancel (restores " .. original .. ")",
      })
      ctx.preview:highlight({ ft = "markdown" })
    end,
    confirm = function(picker, item)
      picker:close()
      if item and item.text then
        committed = true
        themes.set_manual(item.text)
      end
    end,
    on_close = function()
      if not committed and themes.current_name ~= original then
        themes.apply(original)
      end
    end,
  })
end

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

      -- on_colors reads the active palette from the theme loader on EVERY
      -- colorscheme re-apply, so `<leader>uC` can switch themes without a
      -- tokyonight re-setup -- just `themes.apply()` mutates current_palette
      -- and re-fires `:colorscheme tokyonight`, and this closure picks up
      -- the change.
      on_colors = function(colors)
        themes.to_tokyonight(colors, themes.current_palette)
      end,

      on_highlights = function(hl, c)
        -- Pull palette-driven slots into locals for the override block.
        -- All backgrounds / borders / dim text derive from `c.*` so every
        -- highlight below adapts to whatever theme the loader applied.
        local bg_dark = c.bg_dark
        local fg = c.fg
        local border = c.border
        local bg_hl = c.bg_highlight
        local bg_search = c.bg_search
        local dim = c.fg_gutter
        local bg_visual = c.bg_visual

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
        -- popup are themed against the active palette: bg_dark for
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
        hl.BlinkCmpLabelDeprecated = { bg = bg_dark, fg = dim, strikethrough = true }
        hl.BlinkCmpLabelMatch = { bg = bg_dark, fg = c.orange, bold = true }
        hl.BlinkCmpLabelDescription = { bg = bg_dark, fg = dim }
        hl.BlinkCmpLabelDetail = { bg = bg_dark, fg = dim }
        hl.BlinkCmpKind = { bg = bg_dark, fg = c.blue }
        hl.BlinkCmpSource = { bg = bg_dark, fg = dim, italic = true }
        hl.BlinkCmpGhostText = { fg = dim, italic = true }

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
        hl.LineNr = { fg = dim }

        -- Search
        hl.Search = { bg = bg_search, fg = fg }
        hl.IncSearch = { bg = c.orange, fg = bg_dark }
        hl.CurSearch = { bg = c.orange, fg = bg_dark }

        -- Visual selection
        hl.Visual = { bg = bg_visual }

        -- Snacks picker (explorer) cursorline. Remap the picker list's
        -- cursorline from its default `Visual` link to `bg_hl` so the
        -- explorer row reads as a normal cursorline instead of mirroring
        -- a visual selection in the main editor.
        hl.SnacksPickerListCursorLine = { bg = bg_hl }

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
        hl.WhichKeySeparator = { fg = dim }
        hl.WhichKeyValue = { fg = dim }
        hl.WhichKeyTitle = { bg = bg_dark, fg = c.blue, bold = true }
        -- WhichKey icon color classes (mapped via `color = "..."` in spec).
        -- Every class derives from a palette slot so which-key icons recolor
        -- with the active theme.
        hl.WhichKeyIconAzure = { fg = c.cyan }
        hl.WhichKeyIconBlue = { fg = c.blue }
        hl.WhichKeyIconCyan = { fg = c.cyan }
        hl.WhichKeyIconGreen = { fg = c.green }
        hl.WhichKeyIconGrey = { fg = dim }
        hl.WhichKeyIconOrange = { fg = c.orange }
        hl.WhichKeyIconPurple = { fg = c.purple }
        hl.WhichKeyIconRed = { fg = c.red }
        hl.WhichKeyIconYellow = { fg = c.yellow }

        -- Diagnostics. Virtual-text backgrounds are hand-picked RGB tints
        -- originally tuned for the deep-ocean palette. They stay hardcoded
        -- for now; swap to palette-derived tints if they clash on a theme
        -- you actually use.
        -- TODO: derive virtual-text bg tints from palette accent colors.
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
        hl.StatusLineNC = { bg = bg_dark, fg = dim }

        -- ----------------------------------------------------------------
        -- Lualine palette-driven section groups (NvChad-inspired aesthetic)
        -- lualine's theme table below references these by name via the
        -- `{ link = "..." }` form, so `hi! link lualine_a_normal LualineModeNormal`
        -- flows through on every `:colorscheme tokyonight` re-apply and the
        -- statusline recolors automatically when themes switch. No ColorScheme
        -- autocmd / lualine.setup() rerun needed.
        -- ----------------------------------------------------------------
        -- Mode badge (section a) -- one group per mode, with colored bg + bold fg
        hl.LualineModeNormal = { bg = c.blue, fg = bg_dark, bold = true }
        hl.LualineModeInsert = { bg = c.green, fg = bg_dark, bold = true }
        hl.LualineModeVisual = { bg = c.purple, fg = bg_dark, bold = true }
        hl.LualineModeReplace = { bg = c.red, fg = bg_dark, bold = true }
        hl.LualineModeCommand = { bg = c.orange, fg = bg_dark, bold = true }
        hl.LualineModeTerminal = { bg = c.cyan, fg = bg_dark, bold = true }
        hl.LualineModeInactive = { bg = bg_dark, fg = dim }

        -- Section b (middle): git branch / diff on subtle raised bg
        hl.LualineB = { bg = bg_hl, fg = fg }
        hl.LualineBInactive = { bg = bg_dark, fg = dim }

        -- Section c (center stretch): file info, diagnostics on editor bg
        hl.LualineC = { bg = bg_dark, fg = fg }
        hl.LualineCInactive = { bg = bg_dark, fg = dim }

        -- Section z (right edge): cwd / macro indicator, mirror-colored to
        -- the mode badge intensity but using a constant blue so the visual
        -- balance stays consistent regardless of mode.
        hl.LualineZ = { bg = c.blue, fg = bg_dark, bold = true }
        hl.LualineZInactive = { bg = bg_dark, fg = dim }

        -- Accent groups used by individual components (filename color,
        -- cursor position, lsp progress spinner, etc.)
        hl.LualineFilename = { bg = bg_dark, fg = c.cyan }
        hl.LualineFilenameModified = { bg = bg_dark, fg = c.orange, bold = true }
        hl.LualineFilenameReadonly = { bg = bg_dark, fg = c.red }
        hl.LualineBranch = { bg = bg_hl, fg = c.purple }
        hl.LualineDiffAdd = { bg = bg_hl, fg = c.green }
        hl.LualineDiffChange = { bg = bg_hl, fg = c.blue }
        hl.LualineDiffDelete = { bg = bg_hl, fg = c.red }
        hl.LualineLsp = { bg = bg_dark, fg = c.teal or c.cyan }
        hl.LualineLspProgress = { bg = bg_dark, fg = c.yellow, italic = true }
        hl.LualineDiagError = { bg = bg_dark, fg = c.error }
        hl.LualineDiagWarn = { bg = bg_dark, fg = c.warning }
        hl.LualineDiagInfo = { bg = bg_dark, fg = c.info }
        hl.LualineDiagHint = { bg = bg_dark, fg = c.hint }
        hl.LualineFiletype = { bg = bg_dark, fg = c.magenta or c.purple }
        hl.LualineCursor = { bg = bg_dark, fg = c.blue, bold = true }

        -- Tabline / bufferline
        hl.TabLine = { bg = bg_dark, fg = dim }
        hl.TabLineSel = { bg = bg_hl, fg = fg }
        hl.TabLineFill = { bg = bg_dark }

        -- Snacks dashboard
        hl.SnacksDashboardHeader = { fg = c.blue }
        hl.SnacksDashboardIcon = { fg = c.blue }
        hl.SnacksDashboardKey = { fg = c.orange }
        hl.SnacksDashboardDesc = { fg = fg }
        hl.SnacksDashboardFooter = { fg = dim }

        -- Snacks indent (dim guide). Uses a very dark blend of bg_dark.
        -- TODO: derive from palette instead of the deep-ocean-specific hex.
        hl.SnacksIndent = { fg = "#0d1f33" }

        -- Notify
        hl.NotifyBackground = { bg = bg_dark }

        -- Snacks notifier (themed toast notifications)
        hl.SnacksNotifierInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierTrace = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierIconInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierIconWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierIconError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierIconDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierIconTrace = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierTitleInfo = { bg = bg_dark, fg = c.blue, bold = true }
        hl.SnacksNotifierTitleWarn = { bg = bg_dark, fg = c.yellow, bold = true }
        hl.SnacksNotifierTitleError = { bg = bg_dark, fg = c.red, bold = true }
        hl.SnacksNotifierTitleDebug = { bg = bg_dark, fg = c.purple, bold = true }
        hl.SnacksNotifierTitleTrace = { bg = bg_dark, fg = dim, bold = true }
        hl.SnacksNotifierBorderInfo = { bg = bg_dark, fg = c.blue }
        hl.SnacksNotifierBorderWarn = { bg = bg_dark, fg = c.yellow }
        hl.SnacksNotifierBorderError = { bg = bg_dark, fg = c.red }
        hl.SnacksNotifierBorderDebug = { bg = bg_dark, fg = c.purple }
        hl.SnacksNotifierBorderTrace = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierFooterInfo = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierFooterWarn = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierFooterError = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierFooterDebug = { bg = bg_dark, fg = dim }
        hl.SnacksNotifierFooterTrace = { bg = bg_dark, fg = dim }
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
        hl.DiffviewStatusLineNC = { bg = bg_dark, fg = dim }
        hl.DiffviewWinSeparator = { bg = bg_dark, fg = border }
        hl.DiffviewCursorLine = { bg = bg_hl }
        hl.DiffviewNonText = { bg = bg_dark, fg = dim }
        hl.DiffviewDim1 = { fg = dim }

        -- File panel (left sidebar listing changed files)
        hl.DiffviewFilePanelTitle = { bg = bg_dark, fg = c.blue, bold = true }
        hl.DiffviewFilePanelCounter = { bg = bg_dark, fg = c.orange, bold = true }
        hl.DiffviewFilePanelFileName = { bg = bg_dark, fg = fg }
        hl.DiffviewFilePanelRootPath = { bg = bg_dark, fg = dim }
        hl.DiffviewFilePanelPath = { bg = bg_dark, fg = dim }
        hl.DiffviewFilePanelSelected = { bg = bg_hl, fg = fg, bold = true }
        hl.DiffviewFilePanelInsertions = { bg = bg_dark, fg = c.green }
        hl.DiffviewFilePanelDeletions = { bg = bg_dark, fg = c.red }

        -- File status indicators (next to file names in the panel)
        hl.DiffviewStatusAdded = { fg = c.green }
        hl.DiffviewStatusModified = { fg = c.blue }
        hl.DiffviewStatusDeleted = { fg = c.red }
        hl.DiffviewStatusRenamed = { fg = c.cyan }
        hl.DiffviewStatusUntracked = { fg = c.orange }
        hl.DiffviewStatusIgnored = { fg = dim }
        hl.DiffviewStatusUnmerged = { fg = c.yellow }
        hl.DiffviewStatusUnknown = { fg = dim }
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
        -- Tinted backgrounds for the three conflict regions. Same deep-
        -- ocean-tuned RGB tints as the diagnostic virtual-text bgs above.
        -- TODO: derive from palette accent colors if any active theme
        -- clashes with these tints.
        -- ----------------------------------------------------------------
        hl.GitConflictCurrent = { bg = "#0a1a0a" }  -- ours: green tint
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
    keys = {
      {
        "<leader>uC",
        open_picker,
        desc = "Colorscheme Picker",
      },
      {
        "<leader>uN",
        function()
          require("themes").cycle(1)
        end,
        desc = "Next Theme",
      },
      {
        "<leader>uP",
        function()
          require("themes").cycle(-1)
        end,
        desc = "Previous Theme",
      },
    },
  },

  -- which-key spec entries for the theme switcher bindings. Kept in a
  -- separate optional block so removing which-key doesn't break the
  -- colorscheme itself.
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "<leader>uC", desc = "Colorscheme Picker", icon = { icon = icons.theme.picker, color = "blue" } },
        { "<leader>uN", desc = "Next Theme",         icon = { icon = icons.theme.next, color = "cyan" } },
        { "<leader>uP", desc = "Previous Theme",     icon = { icon = icons.theme.prev, color = "cyan" } },
      },
    },
  },
}
