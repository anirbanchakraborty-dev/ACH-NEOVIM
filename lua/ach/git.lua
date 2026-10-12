-- Git: the guards in front of every git key, gitsigns' options and its keys
-- for one change at a time, and the browse link with any user or token
-- removed. Each key finds the repository first, and each program is checked
-- before it is started, so a key pressed in the wrong place prints one line
-- and opens nothing.
local I = require("ach.icons")
local need = require("ach.need")
local util = require("ach.util")

local M = {}

local function nowhere(dir) vim.notify(("Not inside a git repository: %s"):format(dir), vim.log.levels.WARN) end

-- The top of the repository holding the current buffer. A buffer that is not
-- a file, such as the dashboard, uses the working folder instead. Prints why
-- and returns nil when there is no repository.
---@return string?
function M.repo()
  local root = util.git_root(0)
  if not root then
    local name = vim.api.nvim_buf_get_name(0)
    nowhere(name ~= "" and vim.bo.buftype == "" and vim.fs.dirname(name) or assert(vim.uv.cwd()))
  end
  return root
end

-- The folder a git action runs in: the repository's top, as repo() finds it,
-- or with "cwd" the working folder itself, when it is inside a repository.
---@param where? "cwd"
---@return string?
function M.where(where)
  if where ~= "cwd" then
    return M.repo()
  end
  local cwd = assert(vim.uv.cwd())
  if vim.fs.root(cwd, ".git") then
    return cwd
  end
  nowhere(cwd)
end

---@param where? "cwd"
function M.lazygit(where)
  if not need.have("lazygit") then
    return
  end
  local cwd = M.where(where)
  if cwd then
    Snacks.lazygit({ cwd = cwd })
  end
end

function M.neogit()
  local root = M.repo()
  if root then
    require("neogit").open({ cwd = root })
  end
end

-- "open" shows every uncommitted change; "file" the current file's history.
---@param what "open"|"file"
function M.diffview(what)
  local root = M.repo()
  if not root then
    return
  end
  if what ~= "file" then
    vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(root))
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("This buffer is not a file, so it has no history", vim.log.levels.WARN)
    return
  end
  vim.cmd(("DiffviewFileHistory -C%s %s"):format(vim.fn.fnameescape(root), vim.fn.fnameescape(file)))
end

-- octo works on the working folder's repository, through gh.
---@param args string such as "issue list"
function M.octo(args)
  if need.have("gh") and M.where("cwd") then
    vim.cmd("Octo " .. args)
  end
end

---@param source string a snacks picker, such as "git_status"
---@param where? "cwd"
function M.pick(source, where)
  local cwd = M.where(where)
  if cwd then
    Snacks.picker[source]({ cwd = cwd })
  end
end

-- A field rather than a local, so the tests can keep the clipboard untouched.
function M.clip(text) vim.fn.setreg("+", text) end

-- A remote's address can carry a user name or a token, as
-- https://build_bot@github.com/owner/project.git does, and snacks keeps it in
-- the link it builds. This removes everything between the scheme and the @.
-- An ssh address such as git@github.com:owner/project.git has no scheme and is
-- left as it is; snacks turns those into plain https links itself.
---@param url string
---@return string
function M.scrub(url) return (url:gsub("^(%a[%w+.-]*://)[^/@]*@", "%1")) end

-- Copies a link to the current line, or the selected lines, pinned to the
-- file's last commit so it still points at the same text after later edits.
-- notify = false stops snacks printing the link before it is scrubbed.
function M.copy_link()
  if not M.repo() then
    return
  end
  Snacks.gitbrowse({
    what = "permalink",
    notify = false,
    open = function(url)
      url = M.scrub(url)
      M.clip(url)
      vim.notify("Copied " .. url, vim.log.levels.INFO)
    end,
  })
end

-- Opens the current file and line, or the selected lines, in the browser.
function M.browse()
  if not M.repo() then
    return
  end
  Snacks.gitbrowse({
    notify = false,
    open = function(url) vim.ui.open(M.scrub(url)) end,
  })
end

function M.gitsigns_opts()
  local g = I.gitsigns
  return {
    signs = {
      add = { text = g.add },
      change = { text = g.change },
      delete = { text = g.delete },
      topdelete = { text = g.topdelete },
      changedelete = { text = g.changedelete },
      untracked = { text = g.untracked },
    },
    -- Staged changes keep the same shapes; gitsigns colours them more dimly.
    signs_staged = {
      add = { text = g.add },
      change = { text = g.change },
      delete = { text = g.delete },
      topdelete = { text = g.topdelete },
      changedelete = { text = g.changedelete },
    },
    attach_to_untracked = true,
    current_line_blame_opts = { delay = 300 },
    on_attach = M.on_attach,
  }
end

-- The keys for one change at a time, set on each buffer gitsigns attaches to.
---@param buf integer
function M.on_attach(buf)
  local gs = require("gitsigns")
  local function map(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true }) end
  -- In a diff window, ]c and [c already move between differences.
  map("n", "]h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      gs.nav_hunk("next")
    end
  end, "Next Hunk")
  map("n", "[h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      gs.nav_hunk("prev")
    end
  end, "Prev Hunk")
  map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
  map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
  map("n", "<leader>ghs", function() gs.stage_hunk() end, "Stage or Unstage Hunk")
  map("x", "<leader>ghs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage or Unstage Hunk")
  map("n", "<leader>ghr", function() gs.reset_hunk() end, "Reset Hunk")
  map("x", "<leader>ghr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset Hunk")
  map("n", "<leader>ghS", function() gs.stage_buffer() end, "Stage Buffer")
  map("n", "<leader>ghR", function() gs.reset_buffer() end, "Reset Buffer")
  map("n", "<leader>ghp", function() gs.preview_hunk_inline() end, "Preview Hunk Inline")
  map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
  map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
  map("n", "<leader>ghd", function() gs.diffthis() end, "Diff This")
  map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
end

-- Space u G and Space u b. Called once gitsigns is set up, so the keys exist
-- from the first file opened on.
function M.toggles()
  local gs = require("gitsigns")
  local function config() return require("gitsigns.config").config end
  I.toggle(Snacks.toggle({
    id = "git_signs",
    name = "Git Signs",
    get = function() return config().signcolumn end,
    set = function(state) gs.toggle_signs(state) end,
  })):map("<leader>uG")
  I.toggle(Snacks.toggle({
    id = "git_blame_line",
    name = "Git Blame Line",
    get = function() return config().current_line_blame end,
    set = function(state) gs.toggle_current_line_blame(state) end,
  })):map("<leader>ub")
end

return M
