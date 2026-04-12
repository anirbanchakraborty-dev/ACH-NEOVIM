-- UI: lualine (statusline), NvChad-inspired default aesthetic.
--
-- Visual design:
--   mode-badge (round sep) ▸ branch ▸ diff ▸ diag ▸ file ▸ …lsp_msg… ▸ lsp ▸ filetype ▸ Ln:Col ▸ cwd
--   [──────────────]      [────── bg_hl ──────]   [──── bg (editor bg) ────]   [────── bg_hl ──────]   [─ blue ─]
--
-- Layout mirrors NvChad/ui's `stl/default.lua`: a colored mode badge on
-- the far left with a Powerline round right-separator, a raised middle
-- band for git info, a transparent center for filename / diagnostics /
-- LSP progress, and a raised right band ending in a blue cwd block.
--
-- Color flow: every section references palette-driven highlight groups
-- (`LualineModeNormal`, `LualineB`, `LualineC`, `LualineZ`, etc.) defined
-- in `colorscheme.lua`'s `on_highlights` block via the `{ link = "..." }`
-- form in lualine's theme config. Lualine stamps `hi! link
-- lualine_a_normal LualineModeNormal`, so when the theme loader flips to
-- a different palette and re-applies tokyonight, our palette-driven
-- groups update and every lualine section recolors automatically -- no
-- lualine.setup() rerun, no ColorScheme autocmd needed.

local icons = require("config.icons")

-- Lualine's custom-theme format. Every entry is a PLAIN STRING hl-group
-- name (not a `{ link = "..." }` table) because lualine's
-- `create_component_highlight_group` only takes the fast link path when
-- `type(color) == 'string'` at highlight.lua:318. The table form skips
-- that path and falls into per-mode sub-group creation, which produces
-- empty `lualine_a_normal` groups that never pick up the link target.
local ocean_theme = {
  normal = {
    a = "LualineModeNormal",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  insert = {
    a = "LualineModeInsert",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  visual = {
    a = "LualineModeVisual",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  replace = {
    a = "LualineModeReplace",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  command = {
    a = "LualineModeCommand",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  terminal = {
    a = "LualineModeTerminal",
    b = "LualineB",
    c = "LualineC",
    x = "LualineC",
    y = "LualineB",
    z = "LualineZ",
  },
  inactive = {
    a = "LualineModeInactive",
    b = "LualineBInactive",
    c = "LualineCInactive",
    x = "LualineCInactive",
    y = "LualineBInactive",
    z = "LualineZInactive",
  },
}

-- ---------------------------------------------------------------
-- LSP progress state (populated by the LspProgress autocmd at the
-- bottom, read by the lsp_progress component in section c).
-- Mirrors NvChad/ui stl/utils.lua's spinner + percent + title format.
-- ---------------------------------------------------------------
local lsp_state = { msg = "" }
local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥", "" }

-- ---------------------------------------------------------------
-- Custom components
-- ---------------------------------------------------------------

-- Mode component: NvChad-style " <MODE>" text with a leading space so
-- the mode name sits a little off the left edge.
local mode = {
  "mode",
  fmt = function(s)
    return " " .. s
  end,
  padding = { left = 1, right = 1 },
  separator = { left = "", right = "" },
}

-- Branch component: colored purple on the raised bg_hl band.
local branch = {
  "branch",
  icon = icons.git.branch,
  color = { link = "LualineBranch" },
  padding = { left = 1, right = 1 },
}

-- Diff component: per-kind colors match the palette's green/blue/red.
local diff = {
  "diff",
  symbols = {
    added = icons.git.added .. " ",
    modified = icons.git.modified .. " ",
    removed = icons.git.removed .. " ",
  },
  diff_color = {
    added = { link = "LualineDiffAdd" },
    modified = { link = "LualineDiffChange" },
    removed = { link = "LualineDiffDelete" },
  },
  padding = { left = 1, right = 1 },
}

-- Diagnostics component: per-severity colors, only shows severities with
-- nonzero counts.
local diagnostics = {
  "diagnostics",
  sources = { "nvim_diagnostic" },
  sections = { "error", "warn", "info", "hint" },
  symbols = {
    error = icons.diagnostics.Error .. " ",
    warn = icons.diagnostics.Warn .. " ",
    info = icons.diagnostics.Info .. " ",
    hint = icons.diagnostics.Hint .. " ",
  },
  diagnostics_color = {
    error = { link = "LualineDiagError" },
    warn = { link = "LualineDiagWarn" },
    info = { link = "LualineDiagInfo" },
    hint = { link = "LualineDiagHint" },
  },
  padding = { left = 1, right = 1 },
}

-- Filename with a color that flips based on buffer state.
local filename = {
  "filename",
  path = 0, -- just the basename -- cwd section covers the folder context
  symbols = {
    modified = " " .. icons.statusline.modified,
    readonly = " " .. icons.statusline.readonly,
    unnamed = "[No Name]",
    newfile = "[New]",
  },
  color = function()
    if vim.bo.modified then
      return { link = "LualineFilenameModified" }
    elseif vim.bo.readonly then
      return { link = "LualineFilenameReadonly" }
    else
      return { link = "LualineFilename" }
    end
  end,
  padding = { left = 1, right = 1 },
}

-- LSP progress spinner + title (populated by the LspProgress autocmd).
-- Hidden when the editor is too narrow to avoid clipping the file column.
local lsp_progress = {
  function()
    if vim.o.columns < 120 then
      return ""
    end
    return lsp_state.msg or ""
  end,
  color = { link = "LualineLspProgress" },
  padding = { left = 1, right = 1 },
}

-- Compact list of attached LSP clients for the current buffer.
local lsp_clients = {
  function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      return ""
    end
    local names = {}
    for _, client in ipairs(clients) do
      table.insert(names, client.name)
    end
    return icons.plugins.lsp .. "  " .. table.concat(names, ", ")
  end,
  color = { link = "LualineLsp" },
  padding = { left = 1, right = 1 },
}

-- Filetype indicator with a distinct accent color so the right band
-- reads as (filetype ▸ position ▸ cwd) instead of blurring into one.
local filetype = {
  "filetype",
  icon_only = false,
  colored = false,
  color = { link = "LualineFiletype" },
  padding = { left = 1, right = 1 },
}

-- Cursor position: "  row:col" with a blue accent that matches the
-- cwd badge so the right edge feels visually anchored.
local cursor_pos = {
  function()
    local row = vim.fn.line(".")
    local col = vim.fn.virtcol(".")
    return "  " .. row .. ":" .. col
  end,
  color = { link = "LualineCursor" },
  padding = { left = 1, right = 1 },
}

-- Current working directory basename, rendered as a colored right-badge
-- with a round separator. Hidden on narrow terminals (< 85 columns) to
-- match NvChad's default behavior.
local cwd = {
  function()
    if vim.o.columns < 85 then
      return ""
    end
    local dir = vim.uv.cwd() or ""
    local name = dir:match("([^/\\]+)[/\\]*$") or dir
    return " " .. icons.ui.folder_open .. "  " .. name .. " "
  end,
  padding = 0,
  separator = { left = "", right = "" },
}

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    event = "VeryLazy",
    opts = function()
      -- Install the LspProgress autocmd once so the `lsp_progress`
      -- component has something to display. Fires on LSP progress
      -- events and rebuilds a compact "<spinner> <percent>% <title>"
      -- string, clearing it on `end`. Triggers a statusline redraw so
      -- the spinner animates smoothly without waiting for a normal
      -- statusline refresh tick.
      vim.api.nvim_create_autocmd("LspProgress", {
        group = vim.api.nvim_create_augroup("ACHLualineLspProgress", { clear = true }),
        pattern = { "begin", "report", "end" },
        callback = function(args)
          if not args.data or not args.data.params then
            return
          end
          local data = args.data.params.value
          if not data then
            return
          end
          if data.kind == "end" then
            lsp_state.msg = ""
          else
            local progress = ""
            if data.percentage then
              local idx = math.max(1, math.floor(data.percentage / 10))
              progress = spinners[idx] .. " " .. data.percentage .. "%% "
            end
            lsp_state.msg = progress .. (data.title or "")
          end
          vim.cmd.redrawstatus()
        end,
        desc = "Update lualine LSP progress spinner",
      })

      return {
        options = {
          theme = ocean_theme,
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "snacks_dashboard" },
          },
          -- Thin component separators inside each section, Powerline
          -- round separators between sections. This gives the mode
          -- badge and cwd badge their curved edges while keeping
          -- components inside the middle bands cleanly separated by a
          -- dim glyph.
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          refresh = {
            statusline = 200,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { mode },
          lualine_b = { branch, diff },
          lualine_c = { diagnostics, filename, lsp_progress },
          lualine_x = { lsp_clients, filetype },
          lualine_y = { cursor_pos },
          lualine_z = { cwd },
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
                return "  " .. vim.fn.line(".") .. ":" .. vim.fn.virtcol(".")
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
