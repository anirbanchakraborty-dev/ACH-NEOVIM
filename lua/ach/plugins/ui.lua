-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/ui/edgy.lua, for the edgy spec.
-- The panes for plugins this configuration does not use are left out.

return {
  -- Help, the terminal, the problem list and search-and-replace dock into fixed panes.
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>ue", function() require("edgy").toggle() end, desc = "Toggle Docked Panes" },
      { "<leader>uE", function() require("edgy").select() end, desc = "Pick a Docked Pane" },
    },
    opts = function()
      local opts = {
        bottom = {
          { ft = "qf", title = "QuickFix" },
          {
            ft = "help",
            size = { height = 20 },
            -- A help file opened for editing is an ordinary file, not a docked page.
            filter = function(buf) return vim.bo[buf].buftype == "help" end,
          },
        },
        right = {
          -- The Claude Code panel's view comes first, so it claims the panel
          -- before the generic terminal view the loop below appends, which
          -- names no width and would leave the panel 30 columns wide.
          require("ach.claude").view(),
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
        -- Inside a docked pane, Ctrl and the arrows resize the pane.
        keys = {
          ["<c-Right>"] = function(win) win:resize("width", 2) end,
          ["<c-Left>"] = function(win) win:resize("width", -2) end,
          ["<c-Up>"] = function(win) win:resize("height", 2) end,
          ["<c-Down>"] = function(win) win:resize("height", -2) end,
        },
      }
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "trouble",
          filter = function(_, win)
            local w = vim.w[win].trouble
            return w
              and w.position == pos
              and w.type == "split"
              and w.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
        table.insert(opts[pos], {
          ft = "snacks_terminal",
          size = { height = 0.4 },
          title = "%{b:snacks_terminal.id}: %{b:term_title}",
          filter = function(_, win)
            local w = vim.w[win].snacks_win
            return w and w.position == pos and w.relative == "editor" and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },

  -- Each nesting level of brackets in its own colour, from tokyonight's rainbow groups.
  -- It reads no options, so lazy.nvim only has to put it on the runtime path.
  { "HiPhish/rainbow-delimiters.nvim", event = { "BufReadPre", "BufNewFile" } },

  -- A swatch behind every hex colour such as #rrggbb.
  {
    "nvim-mini/mini.hipatterns",
    event = { "BufReadPre", "BufNewFile" },
    opts = function() return { highlighters = { hex_color = require("mini.hipatterns").gen_highlighter.hex_color() } } end,
  },

  -- Indent guides, the current scope, highlights on other uses of the word under the
  -- cursor, the line-number column and the input box.
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = true },
      scope = { enabled = true },
      words = { enabled = true },
      statuscolumn = { enabled = true },
      input = { enabled = true },
    },
  },
}
