-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/lang/markdown.lua.
-- Markdown: render-markdown.nvim draws headings, lists, tables and code blocks
-- in the editor, snacks draws pictures and formulas, and live-preview.nvim
-- shows the page in the browser. The preview's guard, Space c p and the check
-- for the drawing programs live in ach.preview.
local P = require("ach.preview")
local I = require("ach.icons")

-- How long render-markdown waits between two drawings, in milliseconds.
local debounce = 100

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = P.file_types,
    opts = {
      file_types = P.file_types,
      debounce = debounce,
      completions = { blink = { enabled = true } },
      -- snacks draws formulas as pictures, and two drawings would overlap.
      latex = { enabled = false },
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      I.toggle(Snacks.toggle({
        id = "render_markdown",
        name = "Render Markdown",
        get = function() return require("render-markdown").get() end,
        set = function(state)
          require("render-markdown").set(state)
          -- render-markdown drops a drawing asked for within debounce of the
          -- last one, so a press straight after scrolling would change the
          -- setting and leave the old drawing up. Asking again once that
          -- window has passed makes the press land.
          vim.defer_fn(function() require("render-markdown").set(state) end, debounce + 50)
        end,
      })):map("<leader>um")
    end,
  },
  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    opts = P.opts(),
    -- Runs at start, so Space c p is on every Markdown file before the plugin
    -- itself has loaded.
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ach_markdown", { clear = true }),
        pattern = P.file_types,
        callback = function(ev) require("ach.preview").attach(ev.buf) end,
      })
    end,
    -- The guard goes on as the plugin loads, before its server can start.
    config = function(_, opts)
      require("livepreview.config").set(opts)
      P.guard()
    end,
  },
  {
    "folke/snacks.nvim",
    opts = { image = { enabled = true } },
  },
}
