-- Editor options. Leader keys are set here, before lazy.nvim loads, so every
-- plugin's keys see them.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/options.lua.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = true
vim.g.markdown_recommended_style = 0

-- Tools Mason installs are runnable before mason.nvim itself loads.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local o = vim.opt
o.termguicolors = true
o.background = "dark"
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 4
o.sidescrolloff = 8
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.undofile = true
o.undolevels = 10000
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.shiftround = true
o.smartindent = true
o.wrap = false
o.linebreak = true
o.mouse = "a"
o.confirm = true
o.exrc = true
o.spelllang = { "en_us" }
o.laststatus = 3
o.showmode = false
o.pumheight = 10
o.inccommand = "nosplit"
o.jumpoptions = "view"
o.timeoutlen = 300
o.updatetime = 200
o.virtualedit = "block"
o.winborder = "rounded"
o.smoothscroll = true
o.conceallevel = 2
o.grepprg = "rg --vimgrep"
o.grepformat = "%f:%l:%c:%m"
o.formatoptions = "jcroqlnt"
o.completeopt = "menu,menuone,noselect"
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
o.shortmess:append({ W = true, I = true, c = true, C = true })
o.fillchars = { fold = " ", foldsep = " ", diff = "╱", eob = " " }
o.foldlevel = 99
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldtext = ""

-- The system clipboard, except over SSH, where it would need OSC 52.
vim.schedule(function()
  if not vim.env.SSH_CONNECTION then
    o.clipboard = "unnamedplus"
  end
end)
