-- Loads the configuration in order. File types are added before lazy.nvim
-- starts, so a file named on the command line is recognised when it opens.
-- Keymaps wait for VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
