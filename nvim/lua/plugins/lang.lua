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

-- ─── SystemVerilog / Verilog run.sh integration ─────────────────────────
--
-- The user drives every hardware project with a `run.sh` script (Yantra-CPU
-- style — see CLAUDE.md / project memory) that wraps the open-source HDL
-- toolchain (verilator + iverilog + verible + yosys + surfer + netlistsvg).
-- These helpers detect that script by walking up from the current buffer,
-- then spawn it in a snacks float terminal so output is captured and
-- dismissable. The keys themselves are filetype-gated and live in a
-- snacks.nvim contributor spec further down this file.

-- which-key v3 spec entries don't accept an `ft` field (that lives on
-- lazy.nvim's `keys` blocks). Use a `cond` callback instead so labels
-- + icons for the <leader>R* group only render in SystemVerilog /
-- Verilog buffers, matching the buffer-local activation of the
-- underlying keymaps.
local sv_filetypes = { "systemverilog", "verilog" }
local function sv_cond()
  return vim.tbl_contains(sv_filetypes, vim.bo.filetype)
end

local function find_run_sh()
  local bufdir = vim.fn.expand("%:p:h")
  if bufdir == "" or bufdir == "." then
    return nil
  end
  return (vim.fs.find("run.sh", { upward = true, path = bufdir, type = "file" }) or {})[1]
end

local function run_script(subcommand, target)
  local script = find_run_sh()
  if not script then
    vim.notify("run.sh not found in any parent directory", vim.log.levels.WARN, { title = "Verilog" })
    return
  end
  local cwd = vim.fs.dirname(script)
  local cmd = { "./run.sh", subcommand }
  if target and target ~= "" then
    table.insert(cmd, target)
  end
  Snacks.terminal(cmd, {
    cwd = cwd,
    win = {
      position = "float",
      border = "rounded",
      title = " run.sh " .. subcommand .. (target and (" " .. target) or "") .. " ",
      title_pos = "center",
    },
  })
end

local function run_pick(subcommand, glob_pattern)
  local script = find_run_sh()
  if not script then
    vim.notify("run.sh not found in any parent directory", vim.log.levels.WARN, { title = "Verilog" })
    return
  end
  local cwd = vim.fs.dirname(script)
  local matches = vim.fn.globpath(cwd, glob_pattern, false, true)
  if #matches == 0 then
    vim.notify("No matches for " .. glob_pattern, vim.log.levels.WARN, { title = "Verilog" })
    return
  end
  local items = {}
  for _, m in ipairs(matches) do
    table.insert(items, vim.fn.fnamemodify(m, ":t:r"))
  end
  vim.ui.select(items, { prompt = "run.sh " .. subcommand .. ":" }, function(choice)
    if choice then
      run_script(subcommand, choice)
    end
  end)
end

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
        sign = false,
        width = "block",
        right_pad = 1,
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
  -- SystemVerilog / Verilog run.sh keymaps.
  --
  -- Filetype-gated <leader>R* keymaps that wrap the canonical run.sh
  -- workflow script (lint/fmt/sim/wave/synth/schematic/check/clean).
  -- The helpers `find_run_sh`/`run_script`/`run_pick` at the top of
  -- this file detect the script by walking up from the current buffer;
  -- gracefully toasts if not found. Each command runs in a snacks
  -- float terminal rooted at the script's directory so output is
  -- captured + dismissable.
  --
  -- These keys are deliberately redundant with the run.sh Overseer
  -- template in util.lua: this prefix is for the high-frequency loop
  -- (one keystroke), the Overseer template is for the long tail
  -- (lint:errors / lint:style / fmt:check / sim:unit / sim:integration)
  -- and gives you task list + history.
  --
  -- The spec hitches onto folke/snacks.nvim because (a) the keymaps
  -- use Snacks.terminal in their callbacks and (b) snacks is loaded
  -- at startup with priority 1000 in ui.lua, so the keys register
  -- immediately. Per-key `ft = ...` filters scope them to SV buffers.
  -- ──────────────────────────────────────────────────────────────────
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>Rl",
        function()
          run_script("lint")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Lint (Verilator + Verible)",
      },
      {
        "<leader>Rf",
        function()
          run_script("fmt")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Format (Verible)",
      },
      {
        "<leader>Rs",
        function()
          run_pick("sim", "tb/**/tb_*.sv")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Simulate Testbench",
      },
      {
        "<leader>Ra",
        function()
          run_script("sim:all")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Sim All",
      },
      {
        "<leader>Rw",
        function()
          run_pick("wave", "build/*.vcd")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Open Waveform (Surfer)",
      },
      {
        "<leader>Ry",
        function()
          run_pick("synth", "rtl/**/*.sv")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Synthesize (Yosys)",
      },
      {
        "<leader>RS",
        function()
          run_pick("schematic", "rtl/**/*.sv")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Schematic (netlistsvg)",
      },
      {
        "<leader>Rc",
        function()
          run_script("check")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Check Tools",
      },
      {
        "<leader>Rk",
        function()
          run_script("clean")
        end,
        ft = { "systemverilog", "verilog" },
        desc = "Clean Build",
      },
    },
  },

  -- ──────────────────────────────────────────────────────────────────
  -- which-key: register the new <leader>c keymaps' icons + the
  -- vimtex localleader group label so the discoverable picker shows
  -- friendly entries instead of bare keys. The keymaps themselves are
  -- defined on each plugin spec above; this block only adds icons.
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

        -- SystemVerilog / Verilog run.sh group + per-key icons. Gated
        -- by `cond = sv_cond` (defined at the top of this file) so they
        -- only show in the SV picker, not the global which-key tree.
        -- which-key v3 spec entries don't accept an `ft` field -- the
        -- equivalent on lazy.nvim's `keys` blocks above does the actual
        -- buffer-local keymap activation; this `cond` just gates the
        -- which-key label/icon rendering to match.
        {
          "<leader>R",
          group = "Verilog Run",
          icon = { icon = icons.filetypes.systemverilog, color = "blue" },
          cond = sv_cond,
        },
        {
          "<leader>Rl",
          desc = "Lint (Verilator + Verible)",
          icon = { icon = icons.lsp.diagnostic, color = "yellow" },
          cond = sv_cond,
        },
        {
          "<leader>Rf",
          desc = "Format (Verible)",
          icon = { icon = icons.lsp.format, color = "blue" },
          cond = sv_cond,
        },
        {
          "<leader>Rs",
          desc = "Simulate Testbench",
          icon = { icon = icons.ui.play, color = "green" },
          cond = sv_cond,
        },
        {
          "<leader>Ra",
          desc = "Sim All",
          icon = { icon = icons.ui.rocket, color = "green" },
          cond = sv_cond,
        },
        {
          "<leader>Rw",
          desc = "Open Waveform (Surfer)",
          icon = { icon = icons.ui.eye, color = "cyan" },
          cond = sv_cond,
        },
        {
          "<leader>Ry",
          desc = "Synthesize (Yosys)",
          icon = { icon = icons.devtools.test, color = "purple" },
          cond = sv_cond,
        },
        {
          "<leader>RS",
          desc = "Schematic (netlistsvg)",
          icon = { icon = icons.ui.eye, color = "purple" },
          cond = sv_cond,
        },
        {
          "<leader>Rc",
          desc = "Check Tools",
          icon = { icon = icons.ui.check, color = "green" },
          cond = sv_cond,
        },
        {
          "<leader>Rk",
          desc = "Clean Build",
          icon = { icon = icons.ui.trash, color = "red" },
          cond = sv_cond,
        },
      },
    },
  },
}
