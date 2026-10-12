-- ACH-NEOVIM entry point. The repository is the configuration, so every path
-- is derived from where this file really sits: through the ~/.config/nvim
-- link, through `nvim -u`, and from scripts/check alike.
if vim.fn.has("nvim-0.12") == 0 then
  vim.api.nvim_echo({ { "ACH-NEOVIM needs Neovim 0.12 or later: brew upgrade neovim", "ErrorMsg" } }, true, {})
  return
end

local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local root = vim.uv.fs_realpath(here) or here
vim.g.ach_root = root
if not vim.tbl_contains(vim.opt.rtp:get(), root) then
  vim.opt.rtp:prepend(root)
end

if vim.env.ACH_TEST == "1" then
  require("ach.testhook").install()
end

require("ach")
