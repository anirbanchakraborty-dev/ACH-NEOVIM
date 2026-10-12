-- tokyonight in its night style with the deep-navy overrides. on_colors runs
-- after tokyonight derives its panel colours, so each override below sticks.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local p = require("ach.palette")
      return {
        style = "night",
        on_colors = function(c)
          c.bg = p.bg
          c.bg_dark = p.bg_dark
          c.bg_float = p.bg_dark
          c.bg_popup = p.bg_dark
          c.bg_sidebar = p.bg_dark
          c.bg_statusline = p.bg_dark
          c.bg_highlight = p.bg_highlight
          c.bg_search = p.bg_search
          c.bg_visual = p.bg_visual
          c.border = p.border
          c.fg = p.fg
          c.fg_dark = p.fg_dark
          c.fg_float = p.fg
          c.fg_gutter = p.fg_gutter
          c.fg_sidebar = p.fg_dark
          c.comment = p.comment
          c.dark3 = p.dark3
        end,
        on_highlights = function(hl)
          hl.AchBanner = { fg = p.banner }
          hl.AchBannerShadow = { fg = p.border }
          hl.AchBannerCaption = { fg = p.fg_dark }
          -- Math drawn by snacks.image takes the text colour, so a formula
          -- reads as part of the page.
          hl.SnacksImageMath = { fg = p.fg }
        end,
      }
    end,
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
}
