-- Core keys. Every key carries a description, which which-key shows and
-- tests/test_keys.lua checks. Plugin keys live in their plugin specs, and no
-- key here may replace one; the test checks that too.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/keymaps.lua.
local map = vim.keymap.set
local I = require("ach.icons")

local function root() return require("ach.util").root() end

-- Move by screen line through a wrapped line, unless a count is given.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Windows.
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- Move lines. Option works as Alt once Ghostty's macos-option-as-alt is set.
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Buffers.
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })

-- Escape also clears the search highlight.
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })
map("n", "<leader>ur", "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", { desc = "Redraw / Clear hlsearch" })

-- n always searches forward and N backward, whichever way the search began.
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Files.
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path, vim.log.levels.INFO, { title = "File path" })
end, { desc = "Copy File Path" })

-- Keep the selection after shifting it.
map("x", "<", "<gv", { desc = "Indent Left" })
map("x", ">", ">gv", { desc = "Indent Right" })

-- A comment line above or below, in the file's own comment syntax.
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- Location and quickfix lists. [q and ]q belong to the trouble spec.
map("n", "<leader>xl", function()
  local open = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  local ok, err = pcall(open and vim.cmd.lclose or vim.cmd.lopen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  local ok, err = pcall(open and vim.cmd.cclose or vim.cmd.copen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

-- Diagnostics: jump, then show the message under the cursor.
local function jump(count, severity)
  return function()
    local found = vim.diagnostic.jump({
      count = count * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
    })
    if found then
      vim.diagnostic.open_float({ scope = "cursor", focus = false })
    end
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", jump(1), { desc = "Next Diagnostic" })
map("n", "[d", jump(-1), { desc = "Prev Diagnostic" })
map("n", "]e", jump(1, "ERROR"), { desc = "Next Error" })
map("n", "[e", jump(-1, "ERROR"), { desc = "Prev Error" })
map("n", "]w", jump(1, "WARN"), { desc = "Next Warning" })
map("n", "[w", jump(-1, "WARN"), { desc = "Prev Warning" })

-- Toggles under Space u. which-key shows each one's current state, and I.toggle
-- gives each its icon from the database, green when on and grey when off. The
-- two format toggles carry ids because the database looks a toggle up by id.
I.toggle(Snacks.toggle({
  id = "autoformat",
  name = "Format on Save (all buffers)",
  get = function() return vim.g.autoformat ~= false end,
  set = function(state) vim.g.autoformat = state end,
})):map("<leader>uf")
I.toggle(Snacks.toggle({
  id = "autoformat_buffer",
  name = "Format on Save (this buffer)",
  get = function() return vim.b.autoformat ~= false end,
  set = function(state) vim.b.autoformat = state end,
})):map("<leader>uF")
I.toggle(Snacks.toggle.option("spell", { name = "Spelling" })):map("<leader>us")
I.toggle(Snacks.toggle.option("wrap", { name = "Wrap" })):map("<leader>uw")
I.toggle(Snacks.toggle.option("relativenumber", { name = "Relative Number" })):map("<leader>uL")
I.toggle(Snacks.toggle.line_number()):map("<leader>ul")
I.toggle(Snacks.toggle.diagnostics()):map("<leader>ud")
I.toggle(Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal" })):map("<leader>uc")
I.toggle(Snacks.toggle.treesitter()):map("<leader>uT")
I.toggle(Snacks.toggle.inlay_hints()):map("<leader>uh")
I.toggle(Snacks.toggle.indent()):map("<leader>ug")
I.toggle(Snacks.toggle.dim()):map("<leader>uD")
I.toggle(Snacks.toggle.zoom()):map("<leader>wm"):map("<leader>uZ")
I.toggle(Snacks.toggle.zen()):map("<leader>uz")

-- The undo tree ships with Neovim 0.12 as an optional package.
map("n", "<leader>uu", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd("Undotree")
end, { desc = "Undo Tree" })
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- Terminal. Ghostty sends Control-/ as itself; older terminals send Control-_.
map("n", "<leader>fT", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "which_key_ignore" })

-- Tabs.
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })

-- Quit, and the plugin manager.
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
