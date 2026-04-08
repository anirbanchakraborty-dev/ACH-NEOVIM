-- Global (non-plugin) keymaps.
--
-- This file runs at init time, before lazy.nvim boots plugins, so it must
-- only use pure vim / Neovim APIs. Plugin-specific bindings live in each
-- plugin's `keys = {}` spec (lsp.lua, editor.lua, util.lua, ...).
--
-- Callbacks may still reference plugin globals (Snacks, persistence, ...)
-- because the function body is only evaluated when the key is pressed, by
-- which point the plugin is loaded.

local map = vim.keymap.set

-- ---------------------------------------------------------------------------
-- Basic editor ergonomics
-- ---------------------------------------------------------------------------

-- Clear search highlight on <Esc>
map({ "i", "n" }, "<Esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Save file from any mode
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Better up/down: respect wrapped lines (also mirror to arrow keys)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down (respect wrap)" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up (respect wrap)" })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down (respect wrap)" })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up (respect wrap)" })

-- Centered scroll
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up (centered)" })

-- Saner n/N: always go forward in document order regardless of search
-- direction. The 'Nn'[v:searchforward] trick picks the opposite of vim's
-- direction-relative behavior when you searched backward, so `n` always
-- means "down the file" and `N` always means "up". Trailing .zv opens any
-- closed folds containing the match so the cursor lands on visible text.
-- Operator-pending / visual modes skip .zv since fold-opening would
-- interfere with text-object selection.
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Keep visual selection after indent
map("v", "<", "<gv", { desc = "Indent Left" })
map("v", ">", ">gv", { desc = "Indent Right" })

-- In visual mode, `p` keeps the unnamed register intact (replaces selection
-- without stealing the yanked text). `P` already behaves this way.
map("x", "p", "P", { desc = "Paste (keep register)" })

-- Move lines up/down (normal/insert/visual) with Alt+j/k.
-- Normal/visual versions respect a count prefix (e.g. `5<A-j>` moves 5 lines).
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Line Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Line Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Line Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Line Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Lines Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Lines Up" })

-- Undo break-points: split the insert-mode undo history at punctuation so
-- `u` can step back word/phrase by phrase instead of nuking the whole insert.
map("i", ",", ",<c-g>u", { desc = "Undo Breakpoint (,)" })
map("i", ".", ".<c-g>u", { desc = "Undo Breakpoint (.)" })
map("i", ";", ";<c-g>u", { desc = "Undo Breakpoint (;)" })

-- ---------------------------------------------------------------------------
-- Window navigation & management
-- ---------------------------------------------------------------------------

map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize with arrows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- <leader>w Window group
map("n", "<leader>wd", "<C-w>c", { desc = "Delete Window", remap = true })
map("n", "<leader>ws", "<C-w>s", { desc = "Split Below", remap = true })
map("n", "<leader>wv", "<C-w>v", { desc = "Split Right", remap = true })
map("n", "<leader>w=", "<C-w>=", { desc = "Balance Windows", remap = true })
map("n", "<leader>wm", "<C-w>_<C-w>|", { desc = "Maximize Window", remap = true })

-- ---------------------------------------------------------------------------
-- Buffer navigation
-- ---------------------------------------------------------------------------

-- Buffer cycle keymaps (<S-h>/<S-l>/[b/]b) are owned by bufferline.nvim in
-- ui.lua so they honor the bufferline order (drag-to-reorder, pinning, etc.).

-- Switch to the alternate (most recently used) buffer. Same as built-in <C-^>.
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- Buffer delete: prefer Snacks.bufdelete if snacks has loaded (keeps the
-- window open); fall back to vanilla :bdelete otherwise.
map("n", "<leader>bd", function()
  if _G.Snacks and Snacks.bufdelete then
    Snacks.bufdelete()
  else
    vim.cmd.bdelete()
  end
end, { desc = "Delete Buffer" })

map("n", "<leader>bD", "<cmd>bdelete<cr>", { desc = "Delete Buffer & Window" })
map("n", "<leader>bo", function()
  if _G.Snacks and Snacks.bufdelete and Snacks.bufdelete.other then
    Snacks.bufdelete.other()
  else
    vim.cmd('%bdelete|edit #|normal `"')
  end
end, { desc = "Delete Other Buffers" })

-- ---------------------------------------------------------------------------
-- UI / toggles under <leader>u
-- ---------------------------------------------------------------------------
--
-- Most <leader>u toggles (line numbers, wrap, spell, diagnostics, color
-- column, inlay hints, etc.) are owned by Snacks.toggle and registered in
-- ui.lua's snacks config function. Only the format-on-save toggle stays
-- here because conform's disable_autoformat flag has no snacks built-in.

map("n", "<leader>uf", function()
  if vim.b.disable_autoformat or vim.g.disable_autoformat then
    vim.cmd("FormatEnable")
    vim.notify("Format on save: enabled", vim.log.levels.INFO, { title = "Conform" })
  else
    vim.cmd("FormatDisable")
    vim.notify("Format on save: disabled", vim.log.levels.INFO, { title = "Conform" })
  end
end, { desc = "Toggle Format on Save" })

-- ---------------------------------------------------------------------------
-- Lazy.nvim shortcuts under <leader>l
-- ---------------------------------------------------------------------------

map("n", "<leader>ll", "<cmd>Lazy<cr>", { desc = "Lazy Home" })
map("n", "<leader>lu", "<cmd>Lazy update<cr>", { desc = "Update Plugins" })
map("n", "<leader>ls", "<cmd>Lazy sync<cr>", { desc = "Sync Plugins" })
map("n", "<leader>lc", "<cmd>Lazy check<cr>", { desc = "Check Plugins" })
map("n", "<leader>lp", "<cmd>Lazy profile<cr>", { desc = "Profile" })

-- ---------------------------------------------------------------------------
-- Diagnostics: severity-filtered jumps (global, not buffer-local). Pairs with
-- the buffer-local ]d/[d defined inside LspAttach in lsp.lua.
-- ---------------------------------------------------------------------------

local function diag_jump(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end

map("n", "]e", diag_jump(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diag_jump(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diag_jump(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diag_jump(false, "WARN"), { desc = "Prev Warning" })

-- ---------------------------------------------------------------------------
-- Productivity miscellany
-- ---------------------------------------------------------------------------

-- New empty buffer (under the existing File/Find group)
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Look up word under cursor via 'keywordprg' (defaults to :help / man).
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- Catch-all "reset visual state": clear search highlight, refresh diff, redraw.
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- Inspect highlight groups / treesitter nodes under cursor (great for theme work)
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- ---------------------------------------------------------------------------
-- vim.snippet tabstop navigation. Used by neogen (which routes its
-- docstring insertion through vim.snippet via snippet_engine = "nvim").
-- Kept separate from blink.cmp's <Tab>/<S-Tab> chain because blink's
-- snippet_forward action only sees blink-inserted snippets and is
-- invisible to vim.snippet sessions, so vim.snippet needs its own keys.
-- ---------------------------------------------------------------------------

map({ "i", "s" }, "<C-l>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1)
  end
end, { desc = "Snippet Forward (vim.snippet)" })

map({ "i", "s" }, "<C-h>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1)
  end
end, { desc = "Snippet Backward (vim.snippet)" })

-- ---------------------------------------------------------------------------
-- Commenting: add an empty commented line below/above and drop into insert.
-- Relies on Neovim 0.10+'s built-in `gcc` operator (no plugin required).
-- ---------------------------------------------------------------------------

map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
