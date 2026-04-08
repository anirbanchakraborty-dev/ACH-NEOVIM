-- Options
-- Sensible defaults for ACH-NEOVIM

local opt = vim.opt
local icons = require("config.icons")

-- Leader key (must be set before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Disable Neovim's built-in markdown ftplugin's 4-space indent override.
-- Indent rules for prose are owned by autocmds.lua's ProseMode group.
vim.g.markdown_recommended_style = 0

-- Line numbers
opt.number = true
opt.relativenumber = false

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true -- round > and < to a multiple of shiftwidth

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "nosplit" -- live preview of :s///

-- Grep: use ripgrep
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

-- Folds: open everything by default; treesitter folds can layer on top later.
opt.foldlevel = 99
opt.foldmethod = "indent"

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.laststatus = 3 -- one global statusline across all splits
opt.pumblend = 10 -- popup menu transparency
opt.pumheight = 10 -- max popup menu items
opt.winminwidth = 5 -- minimum window width
opt.fillchars = {
  foldopen = icons.ui.expand, -- chevron-down
  foldclose = icons.ui.collapse, -- chevron-right
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen" -- keep cursor visually in place on horizontal split

-- System clipboard (skip on SSH so OSC 52 takes over)
opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"

-- Undo
opt.undofile = true
opt.undolevels = 10000

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- Completion
opt.completeopt = "menu,menuone,noselect"

-- Sessions (consumed by persistence.nvim)
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- Editing behavior
opt.formatoptions = "jcroqlnt" -- smarter auto-formatting (don't continue comments on `o`, recognize numbered lists, etc.)
opt.virtualedit = "block" -- cursor can move past EOL in visual block mode
opt.linebreak = true -- when wrap is on, break at word boundaries

-- Navigation
opt.jumpoptions = "view" -- preserve view position across jumps
opt.smoothscroll = true -- smooth <C-d>/<C-u> (Neovim 0.10+)

-- Command line
opt.wildmode = "longest:full,full"

-- Filetype niceties
opt.conceallevel = 2 -- hide markdown bold/italic markers, keep substitutions
opt.spelllang = { "en" }

-- Misc
opt.autowrite = true
opt.wrap = false
opt.mouse = "a"
opt.showmode = false
opt.confirm = true
opt.shortmess:append({ W = true, I = true, c = true, C = true })
