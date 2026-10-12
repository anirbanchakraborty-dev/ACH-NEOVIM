-- Loads the configuration in order. Keymaps wait for VeryLazy, after the first
-- screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
