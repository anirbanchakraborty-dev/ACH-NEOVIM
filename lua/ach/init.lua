-- Loads the configuration in order. File types are added and the installer's
-- hooks created before lazy.nvim starts, so a file named on the command line
-- is recognised and gets its parsers when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.install").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() require("ach.keymaps") end,
})
