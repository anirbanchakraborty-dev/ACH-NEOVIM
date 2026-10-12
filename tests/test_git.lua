-- Git. Each test makes its own repository in a scratch folder, with a fixed
-- name and email and with commit signing and hooks off, so no setting of the
-- owner's reaches it. lazygit, gh, the clipboard and the browser are
-- stand-ins: no test starts lazygit, reaches GitHub or touches the owner's
-- clipboard.
local I = require("ach.icons")

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name) return found[name] and 1 or 0 end
end

-- Runs git in dir with the owner's settings that could interfere turned
-- off, checks that it worked, and returns what it printed, trimmed.
local function git(t, dir, ...)
  local argv = {
    "git",
    "--no-optional-locks",
    "-C",
    dir,
    "-c",
    "user.name=ACH",
    "-c",
    "user.email=ach@example.invalid",
    "-c",
    "commit.gpgsign=false",
    "-c",
    "core.hooksPath=/dev/null",
    ...,
  }
  local r = vim.system(argv, { text = true }):wait()
  t.eq(r.code, 0, table.concat(argv, " ") .. ": " .. (r.stderr or ""))
  return vim.trim(r.stdout or "")
end

-- Ten lines, "line 1" to "line 10", with the lines named in changed edited.
local function lines(changed)
  local out = {}
  for i = 1, 10 do
    out[i] = changed[i] and ("line %d, changed"):format(i) or ("line %d"):format(i)
  end
  return out
end

-- A repository in a fresh folder holding notes.txt, ten lines committed on
-- main. Returns the folder.
local function repo(t)
  local dir = t.tmpdir()
  git(t, dir, "init", "-q", "-b", "main")
  vim.fn.writefile(lines({}), dir .. "/notes.txt")
  git(t, dir, "add", "notes.txt")
  git(t, dir, "commit", "-q", "-m", "notes")
  return dir
end

-- Opens file and waits until gitsigns has read it, which is when its status
-- counts the given number of changed lines. Returns the buffer.
local function open(t, file, changed)
  vim.cmd.edit(vim.fn.fnameescape(file))
  local buf = vim.api.nvim_get_current_buf()
  local ready = vim.wait(5000, function()
    local d = vim.b[buf].gitsigns_status_dict
    return d ~= nil and d.changed == changed
  end, 20)
  t.ok(ready, ("gitsigns counts %d changed lines in %s"):format(changed, file))
  return buf
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

return {
  ["change bars come from gitsigns, in snacks' column, with the database's glyphs"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      local buf = open(t, dir .. "/notes.txt", 1)
      local ns = vim.api.nvim_get_namespaces()["gitsigns_signs_"]
      t.ok(ns ~= nil, "gitsigns' namespace for its bars")
      -- gitsigns numbers each bar by its line.
      local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, 3, { details = true })
      t.eq(mark[1], 2, "a bar on line 3")
      t.eq(mark[3].sign_hl_group, "GitSignsChange", "coloured as a change")
      t.eq(vim.trim(mark[3].sign_text), I.gitsigns.change, "drawn with the glyph from the icon database")
      t.ok(vim.wo.statuscolumn:find("snacks.statuscolumn", 1, true) ~= nil, "in snacks' column")
      t.eq(vim.b[buf].gitsigns_status_dict.head, "main", "and the branch is there for the status bar")
    end)
  end,

  ["the hunk keys belong to the buffer, and each has an icon"] = function(t)
    tidy(function()
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local keys = {
        { "]h", "n" },
        { "[h", "n" },
        { "]H", "n" },
        { "[H", "n" },
        { "<leader>ghs", "n" },
        { "<leader>ghs", "x" },
        { "<leader>ghr", "n" },
        { "<leader>ghr", "x" },
        { "<leader>ghS", "n" },
        { "<leader>ghR", "n" },
        { "<leader>ghp", "n" },
        { "<leader>ghb", "n" },
        { "<leader>ghB", "n" },
        { "<leader>ghd", "n" },
        { "<leader>ghD", "n" },
        { "ih", "o" },
        { "ih", "x" },
      }
      for _, k in ipairs(keys) do
        local m = vim.fn.maparg(k[1], k[2], false, true)
        t.eq(m.buffer, 1, ("%s in mode %s belongs to the buffer"):format(k[1], k[2]))
        t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
      end
    end)
  end,

  ["]h and the other hunk moves land on the changed lines"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true, [8] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 2)
      local function at(line)
        return vim.wait(2000, function() return vim.fn.line(".") == line end, 20)
      end
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      press("]h")
      t.ok(at(3), "]h from line 1 goes to the change on line 3")
      press("]H")
      t.ok(at(8), "]H goes to the last change, on line 8")
      press("[H")
      t.ok(at(3), "[H goes back to the first")
    end)
  end,

  ["Space g h s stages the change under the cursor"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 1)
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      press("<leader>ghs")
      local staged = vim.wait(
        5000,
        function() return git(t, dir, "diff", "--cached", "--name-only") == "notes.txt" end,
        100
      )
      t.ok(staged, "notes.txt is staged")
    end)
  end,

  ["Space u G and Space u b turn the bars and the line's blame off and on"] = function(t)
    tidy(function()
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local function config() return require("gitsigns.config").config end
      local signs, blame = config().signcolumn, config().current_line_blame
      press("<leader>uG")
      t.eq(config().signcolumn, not signs, "Space u G flips the bars")
      press("<leader>uG")
      t.eq(config().signcolumn, signs, "and back")
      press("<leader>ub")
      t.eq(config().current_line_blame, not blame, "Space u b flips the line's blame")
      press("<leader>ub")
      t.eq(config().current_line_blame, blame, "and back")
    end)
  end,

  ["lazygit opens at the top of the repository, from a file in a subfolder"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.mkdir(dir .. "/sub", "p")
      vim.fn.writefile({ "deep" }, dir .. "/sub/deep.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/sub/deep.txt"))
      local got
      with({
        { vim.fn, "executable", only({ lazygit = true }) },
        {
          Snacks,
          "lazygit",
          function(opts) got = opts end,
        },
      }, function() press("<leader>gg") end)
      t.eq(got and got.cwd, dir, "lazygit starts at the repository's top")
    end)
  end,

  ["outside a repository, every git action says so once and opens nothing"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = t.tmpdir()
      vim.fn.writefile({ "scratch" }, dir .. "/scratch.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/scratch.txt"))
      local tabs = #vim.api.nvim_list_tabpages()
      local opened, said = {}, {}
      local function record(what)
        return function() opened[#opened + 1] = what end
      end
      with({
        { vim.fn, "executable", only({ lazygit = true, gh = true }) },
        { Snacks, "lazygit", record("lazygit") },
        {
          Snacks,
          "picker",
          setmetatable({}, {
            __index = function(_, source) return record(source) end,
          }),
        },
        { package.loaded, "neogit", { open = record("neogit") } },
        { G, "clip", record("clipboard") },
        { vim.ui, "open", record("browser") },
        {
          vim,
          "notify",
          function(msg) said[#said + 1] = msg end,
        },
      }, function()
        G.lazygit()
        G.neogit()
        G.diffview("open")
        G.diffview("file")
        G.pick("git_status")
        G.copy_link()
        G.browse()
      end)
      t.eq(opened, {}, "nothing opens")
      t.eq(#vim.api.nvim_list_tabpages(), tabs, "no tab opens")
      t.eq(#said, 7, "one message for each")
      for _, msg in ipairs(said) do
        t.eq(msg, "Not inside a git repository: " .. dir)
      end
    end)
  end,

  ["a missing lazygit or gh prints the line that installs it"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local opened, said = {}, {}
      with({
        { vim.fn, "executable", only({}) },
        {
          Snacks,
          "lazygit",
          function() opened[#opened + 1] = "lazygit" end,
        },
        {
          vim,
          "notify",
          function(msg) said[#said + 1] = msg end,
        },
      }, function()
        G.lazygit()
        G.octo("issue list")
      end)
      t.eq(opened, {}, "lazygit does not open")
      t.eq(package.loaded["octo"], nil, "octo does not load")
      t.eq(said, {
        "lazygit is not installed. Install it with: brew install lazygit",
        "gh is not installed. Install it with: brew install gh, then run: gh auth login",
      })
    end)
  end,

  ["the copied link leaves out the user in the remote's address"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      git(t, dir, "remote", "add", "origin", "https://build_bot@github.com/owner/project.git")
      local sha = git(t, dir, "rev-parse", "HEAD")
      open(t, dir .. "/notes.txt", 0)
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      local copied, said = {}, {}
      with({
        {
          G,
          "clip",
          function(text) copied[#copied + 1] = text end,
        },
        {
          vim,
          "notify",
          function(msg) said[#said + 1] = msg end,
        },
        {
          vim.ui,
          "open",
          function() error("the browser was opened") end,
        },
      }, function() G.copy_link() end)
      local want = ("https://github.com/owner/project/blob/%s/notes.txt#L4-L4"):format(sha)
      t.eq(copied, { want }, "the link to line 4 at its commit, without build_bot")
      t.eq(said, { "Copied " .. want }, "and it says what it copied")
      local ssh = "git@github.com:owner/project.git"
      t.eq(G.scrub(ssh), ssh, "an ssh address is left alone")
      t.eq(G.scrub("https://github.com/owner/project"), "https://github.com/owner/project", "as is a plain one")
    end)
  end,

  ["Diff View opens in a tab of its own and closes with :DiffviewClose"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 1)
      local tabs = #vim.api.nvim_list_tabpages()
      G.diffview("open")
      local shown = vim.wait(5000, function()
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(b):match("^diffview://") then
            return true
          end
        end
        return false
      end, 50)
      t.ok(shown, "a diffview buffer appears")
      t.eq(#vim.api.nvim_list_tabpages(), tabs + 1, "in one new tab")
      vim.cmd("DiffviewClose")
      local closed = vim.wait(2000, function() return #vim.api.nvim_list_tabpages() == tabs end, 50)
      t.ok(closed, "and :DiffviewClose takes the tab away")
    end)
  end,

  ["Neogit opens in a tab at the repository's top, with diffview and snacks"] = function(t)
    tidy(function()
      local plugin = require("lazy.core.config").plugins["neogit"]
      t.ok(plugin ~= nil, "Neogit is in the plugin list")
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      t.eq(opts.kind, "tab", "in a tab")
      t.eq(opts.graph_style, "unicode", "with a graph drawn in box characters")
      t.eq(opts.integrations, { diffview = true, snacks = true }, "using diffview and the snacks picker")
      local dir = repo(t)
      vim.fn.mkdir(dir .. "/sub", "p")
      vim.fn.writefile({ "deep" }, dir .. "/sub/deep.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/sub/deep.txt"))
      local got
      with({
        {
          package.loaded,
          "neogit",
          {
            open = function(o) got = o end,
          },
        },
      }, function() require("ach.git").neogit() end)
      t.eq(got, { cwd = dir }, "at the repository's top")
    end)
  end,

  ["octo waits for its command and lists through the snacks picker"] = function(t)
    local plugin = require("lazy.core.config").plugins["octo.nvim"]
    t.ok(plugin ~= nil, "octo is in the plugin list")
    local opts = require("lazy.core.plugin").values(plugin, "opts", false)
    t.eq(opts.picker, "snacks", "lists in the snacks picker")
    t.eq(opts.enable_builtin, true, "a bare :Octo offers a menu of its commands")
    t.eq(plugin._.loaded, nil, "not loaded at startup")
  end,

  ["every git key is set, with a description that has an icon"] = function(t)
    local keys = {
      { "<leader>gg", "n" },
      { "<leader>gG", "n" },
      { "<leader>gn", "n" },
      { "<leader>gD", "n" },
      { "<leader>gF", "n" },
      { "<leader>gs", "n" },
      { "<leader>gS", "n" },
      { "<leader>gd", "n" },
      { "<leader>gl", "n" },
      { "<leader>gL", "n" },
      { "<leader>gf", "n" },
      { "<leader>gb", "n" },
      { "<leader>gc", "n" },
      { "<leader>gB", "n" },
      { "<leader>gB", "x" },
      { "<leader>gY", "n" },
      { "<leader>gY", "x" },
      { "<leader>gi", "n" },
      { "<leader>gp", "n" },
    }
    for _, k in ipairs(keys) do
      local m = vim.fn.maparg(k[1], k[2], false, true)
      t.ok(m.desc ~= nil, ("%s is set in mode %s"):format(k[1], k[2]))
      t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
    end
  end,
}
