-- Installs lazy.nvim on first start, then hands it the plugin specs in
-- lua/ach/plugins/. The bootstrap is lazy.nvim's own documented snippet.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

local testing = vim.env.ACH_TEST == "1"

require("lazy").setup({
  spec = { { import = "ach.plugins" } },
  lockfile = vim.g.ach_root .. "/lazy-lock.json",
  defaults = { lazy = true, version = false },
  -- Under test a missing plugin must fail the lock test, not install itself.
  install = { missing = not testing, colorscheme = { "tokyonight-night" } },
  checker = { enabled = not testing, notify = false, frequency = 86400 },
  change_detection = { notify = false },
  -- Every icon in lazy.nvim's window comes from the icon database.
  ui = { icons = require("ach.icons").lazy_ui() },
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- lazy.nvim resets the runtime path, and under `nvim -u` the repository
      -- is not the config folder, so it is kept explicitly.
      paths = { vim.g.ach_root },
      disabled_plugins = { "gzip", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
