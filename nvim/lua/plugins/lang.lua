-- Language-specific plugins that aren't LSP/formatter/linter:
--
--   * render-markdown.nvim    -- inline markdown rendering in the buffer
--   * markdown-preview.nvim   -- browser-based markdown preview
--   * vimtex                  -- LaTeX editing environment
--   * venv-selector.nvim      -- Python virtualenv picker
--
-- All four are lazy-loaded by filetype so they cost nothing at startup
-- unless you actually open the relevant file. Borrowed from LazyVim's
-- extras/lang/markdown.lua, extras/lang/tex.lua, and extras/lang/python.lua.

local icons = require("config.icons")

return {
  -- ──────────────────────────────────────────────────────────────────
  -- render-markdown.nvim
  --
  -- Replaces the raw markdown source with rendered headings, code
  -- blocks, callouts, tables, and bullet points inline in the buffer
  -- (concealed source). Bound under <leader>um as a snacks toggle so
  -- you can flip rendering on/off without leaving the buffer. The
  -- toggle hooks live in the config function so we don't reach into
  -- snacks.toggle until render-markdown actually loads.
  -- ──────────────────────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown.mdx", "norg", "rmd", "org" },
    opts = {
      code = {
        -- width = "full" fills the code block bg across the whole editor
        -- window width (not just to the end of the longest code line).
        -- `block` width created visually distracting color transitions
        -- where the code bg ended mid-line and merged visually with the
        -- adjacent sidebar's background -- it looked like a selection
        -- bleed. `full` gives a uniform bg that reads as a code block
        -- unambiguously.
        sign = false,
        width = "full",
      },
      heading = {
        sign = false,
        icons = {},
      },
      checkbox = {
        enabled = false,
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = function()
          return require("render-markdown.state").enabled
        end,
        set = function(enabled)
          local m = require("render-markdown")
          if enabled then
            m.enable()
          else
            m.disable()
          end
        end,
      }):map("<leader>um")
    end,
  },

  -- ──────────────────────────────────────────────────────────────────
  -- markdown-preview.nvim
  --
  -- Browser-based live preview. Heavy: ships a node/yarn build step
  -- the first time it loads. Bound under <leader>cp inside markdown
  -- buffers, so it doesn't show up in the global which-key tree.
  -- ──────────────────────────────────────────────────────────────────
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown", "markdown.mdx" },
    build = function()
      require("lazy").load({ plugins = { "markdown-preview.nvim" } })
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    config = function()
      vim.cmd([[do FileType]])
    end,
  },

  -- ──────────────────────────────────────────────────────────────────
  -- vimtex
  --
  -- Full LaTeX editing environment: build management, forward/inverse
  -- search, citations, document structure, definition lookups, etc.
  -- Cannot be lazy-loaded -- inverse search needs vimtex's servername
  -- registered at startup. Disable the `K` mapping so it doesn't
  -- collide with our LSP hover binding (texlab handles hover).
  -- The localleader for vimtex is `\l` -- which-key picks it up via
  -- the local <localLeader>l prefix below.
  -- ──────────────────────────────────────────────────────────────────
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_mappings_disable = { ["n"] = { "K" } }
      vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
      vim.g.vimtex_view_method = "skim" -- macOS PDF viewer
      vim.g.vimtex_compiler_method = "latexmk"
    end,
    keys = {
      { "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
    },
  },

  -- ──────────────────────────────────────────────────────────────────
  -- venv-selector.nvim
  --
  -- `<leader>cv` to pick a Python virtualenv. Reads VIRTUAL_ENV,
  -- pipx, poetry, hatch, pdm, conda, and any .venv directory in
  -- the workspace. Lazy-loaded on the python filetype so it costs
  -- nothing for non-Python work.
  -- ──────────────────────────────────────────────────────────────────
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    cmd = "VenvSelect",
    ft = "python",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      "mfussenegger/nvim-dap-python",
      { "nvim-telescope/telescope.nvim", optional = true },
    },
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select Python VirtualEnv", ft = "python" },
    },
  },

  -- ──────────────────────────────────────────────────────────────────
  -- which-key: register the new <leader>c keymaps' icons so the
  -- discoverable picker shows friendly entries instead of bare keys.
  -- The keymaps themselves are defined on each plugin spec above;
  -- this block only adds icons.
  -- ──────────────────────────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    optional = true,
    opts_extend = { "spec" },
    opts = {
      spec = {
        { "<leader>cp", desc = "Markdown Preview", icon = { icon = icons.ui.eye, color = "cyan" } },
        { "<leader>cv", desc = "Select Python VirtualEnv", icon = { icon = icons.devtools.pip, color = "green" } },
        { "<leader>um", desc = "Toggle Render Markdown", icon = { icon = icons.ui.eye, color = "purple" } },
      },
    },
  },
}
