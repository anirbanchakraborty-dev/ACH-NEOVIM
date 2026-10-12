-- Loads the configuration in order: options, autocommands, then lazy.nvim.
-- What only a file needs waits for the first one. File types are added,
-- Homebrew's Java, Ruby and the toolchain folders put on the path, spelling
-- and Harper's settings put in place, the managed languages' plugins told not
-- to start their own servers, and the installer's hooks created as the first
-- file is read, before Neovim works out its type, so a file named on the
-- command line is recognised, checked, and gets its parsers, tools and server
-- when it opens. With no file all of that waits for VeryLazy, after the first
-- screen has drawn, as do keymaps and the check that runs once after Homebrew
-- moves Neovim.
require("ach.options")
require("ach.autocmds")

-- These groups answer FileType, and Neovim does not run an autocommand created
-- while its event is under way, so when a file type set on a buffer with no
-- file is what set them up, the event is fired again for them alone.
local FILETYPE_GROUPS = { "ach_grammar", "ach_managed", "ach_install" }

local files = vim.api.nvim_create_augroup("ach_files", { clear = true })

-- Runs once: the first of these events deletes the group, and with it the rest.
local function for_files(ev)
  vim.api.nvim_del_augroup_by_id(files)
  require("ach.filetypes").setup()
  require("ach.runtimes").setup()
  require("ach.grammar").setup()
  require("ach.managed").setup()
  require("ach.install").setup()
  if ev.event == "FileType" then
    for _, group in ipairs(FILETYPE_GROUPS) do
      vim.api.nvim_exec_autocmds("FileType", { group = group, buffer = ev.buf, modeline = false })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "StdinReadPre" }, {
  group = files,
  callback = for_files,
})
vim.api.nvim_create_autocmd("FileType", {
  group = files,
  callback = function(ev)
    if vim.bo[ev.buf].buftype == "" then
      for_files(ev)
    end
  end,
})
vim.api.nvim_create_autocmd("User", { group = files, pattern = "VeryLazy", callback = for_files })

require("ach.upgrade").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() require("ach.keymaps") end,
})
