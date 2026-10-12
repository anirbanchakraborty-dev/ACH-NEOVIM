-- Loads the configuration in order. File types are added, Homebrew's Java,
-- Ruby and the toolchain folders put on the path, spelling and Harper's
-- settings put in place, the managed languages' plugins told not to start
-- their own servers, and the installer's hooks created before lazy.nvim
-- starts, so a file named on the command line is recognised, checked, and
-- gets its parsers, tools and server when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn, and so does the check that
-- runs once after Homebrew moves Neovim.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.runtimes").setup()
require("ach.grammar").setup()
require("ach.managed").setup()
require("ach.install").setup()
require("ach.upgrade").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() require("ach.keymaps") end,
})
