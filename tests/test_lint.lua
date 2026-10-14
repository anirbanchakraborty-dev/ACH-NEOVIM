-- Linting. Every linter the table names is one nvim-lint knows, run by the
-- program listed for it; only installed linters run, and only on files; one
-- not installed yet stays silent; linters sent the buffer's text run when
-- insert mode ends, and those that read the file wait for a save; events
-- lint after a short pause; and markdownlint-cli2, sqlfluff, tflint and
-- golangci-lint get this configuration's changes. The buffer tests use a file
-- type of their own, achtest, whose linters run cat, so no real linter needs
-- to be installed; the one that runs markdownlint-cli2 is skipped without it.
local opened = {}

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

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- A scratch buffer named path, which nothing writes to disk.
local function named(path)
  local buf = vim.api.nvim_create_buf(false, true)
  opened[#opened + 1] = buf
  vim.api.nvim_buf_set_name(buf, path)
  return buf
end

-- Writes one line of text to a new file and opens it as an achtest buffer.
local function open(t, text)
  local path = t.tmpdir() .. "/sample.achtest"
  vim.fn.writefile({ text }, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  opened[#opened + 1] = buf
  vim.bo[buf].filetype = "achtest"
  return buf, path
end

-- A linter that runs cat and reports what it read as one warning on the
-- first line: the buffer's text when stdin is true, the file on disk when not.
local function cat(stdin)
  return {
    cmd = "cat",
    stdin = stdin,
    stream = "stdout",
    parser = function(output)
      return { { lnum = 0, col = 0, message = vim.trim(output), severity = vim.diagnostic.severity.WARN } }
    end,
  }
end

-- Gives the file type achtest the linters in defs, for the length of body.
-- defs maps each name to { definition, program }.
local function with_linters(defs, body)
  local lint, L = require("lint"), require("ach.lint")
  local stubs, names = {}, {}
  for name, def in pairs(defs) do
    names[#names + 1] = name
    stubs[#stubs + 1] = { lint.linters, name, def[1] }
    stubs[#stubs + 1] = { L.commands, name, { def[2] } }
  end
  table.sort(names)
  stubs[#stubs + 1] = { lint.linters_by_ft, "achtest", names }
  tidy(function() with(stubs, body) end)
end

-- The messages of the diagnostics the linter called name has put on buf.
local function messages(buf, name)
  local out = {}
  for _, d in ipairs(vim.diagnostic.get(buf, { namespace = require("lint").get_namespace(name) })) do
    out[#out + 1] = d.message
  end
  return out
end

return {
  ["every linter the table names is one nvim-lint knows, run by the program listed"] = function(t)
    local L = require("ach.lint")
    local bad, used = {}, {}
    for ft, names in pairs(require("ach.lang").linters_by_ft()) do
      for _, name in ipairs(names) do
        used[name] = true
        local ok, def = pcall(require, "lint.linters." .. name)
        local cmd = ok and type(def) == "table" and def.cmd or nil
        if type(cmd) == "function" then
          cmd = cmd()
        end
        local listed = L.commands[name] or {}
        if cmd == nil or cmd ~= listed[1] then
          bad[#bad + 1] = ("%s: %s runs %s, listed as %s"):format(ft, name, tostring(cmd), tostring(listed[1]))
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "linters nvim-lint has no definition for, or listed with another program")
    local stray = {}
    for name in pairs(L.commands) do
      if not used[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "listed linters no file type uses")
    for name in pairs(L.adapt) do
      t.ok(used[name], name .. " is changed here and used by a file type")
    end
  end,

  ["nvim-lint has every file type's linters"] = function(t)
    local lint = require("lint")
    local want, got = require("ach.lang").linters_by_ft(), {}
    for ft in pairs(want) do
      got[ft] = lint.linters_by_ft[ft]
    end
    t.eq(got, want)
  end,

  ["only installed linters run, and only on files"] = function(t)
    local defs = { ach_missing = { cat(true), "ach-linter-not-installed-yet" }, ach_test = { cat(true), "cat" } }
    with_linters(defs, function()
      local L = require("ach.lint")
      local file = open(t, "hello")
      t.eq(L.linters_for(file), { "ach_test" }, "a file")
      vim.bo[file].filetype = "achtest.extra"
      t.eq(L.linters_for(file), { "ach_test" }, "a compound file type the table does not name")
      local scratch = named(t.tmpdir() .. "/scratch.achtest")
      vim.bo[scratch].filetype = "achtest"
      t.eq(L.linters_for(scratch), {}, "a scratch buffer")
      local unnamed = vim.api.nvim_create_buf(true, false)
      opened[#opened + 1] = unnamed
      vim.bo[unnamed].filetype = "achtest"
      t.eq(L.linters_for(unnamed), {}, "a buffer with no file")
    end)
  end,

  ["a linter not installed yet stays silent"] = function(t)
    local missing = { cmd = "ach-linter-not-installed-yet", stdin = true, parser = function() return {} end }
    with_linters({ ach_missing = { missing, "ach-linter-not-installed-yet" } }, function()
      local notes = {}
      local function note(msg) notes[#notes + 1] = msg end
      with({ { vim, "notify", note } }, function()
        local buf = open(t, "hello")
        vim.v.errmsg = ""
        vim.cmd.write()
        vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
        vim.wait(300)
        t.eq(notes, {}, "messages")
        t.eq(vim.v.errmsg, "", "the last error message")
        require("lint").try_lint("ach_missing")
        t.ok(#notes > 0, "nvim-lint complains when asked outright, so the silence above is this configuration's doing")
      end)
    end)
  end,

  ["a linter sent the buffer's text reports on what is typed"] = function(t)
    with_linters({ ach_test = { cat(true), "cat" } }, function()
      local buf = open(t, "hello")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed, not saved" })
      require("ach.lint").run(buf, false)
      local linted = vim.wait(2000, function() return messages(buf, "ach_test")[1] == "typed, not saved" end)
      t.ok(linted, "the warning reports the unsaved text")
    end)
  end,

  ["a linter that reads the file waits for a save"] = function(t)
    with_linters({ ach_test = { cat(false), "cat" } }, function()
      local L = require("ach.lint")
      local ns = require("lint").get_namespace("ach_test")
      local buf = open(t, "hello")
      local linted = vim.wait(2000, function() return messages(buf, "ach_test")[1] == "hello" end)
      t.ok(linted, "the file is linted when it opens")
      vim.diagnostic.reset(ns, buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed, not saved" })
      vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
      vim.wait(300)
      t.eq(messages(buf, "ach_test"), {}, "after leaving insert mode")
      vim.cmd.write()
      linted = vim.wait(2000, function() return messages(buf, "ach_test")[1] == "typed, not saved" end)
      t.ok(linted, "after the save, the saved text")
      vim.diagnostic.reset(ns, buf)
      L.schedule(buf, true)
      L.schedule(buf, false)
      linted = vim.wait(2000, function() return #messages(buf, "ach_test") > 0 end)
      t.ok(linted, "a save followed at once by leaving insert mode")
    end)
  end,

  ["saving and leaving insert mode lint after a short pause"] = function(t)
    with_linters({ ach_test = { cat(true), "cat" } }, function()
      local buf = open(t, "hello")
      vim.wait(2000, function() return #messages(buf, "ach_test") > 0 end)
      vim.diagnostic.reset(require("lint").get_namespace("ach_test"), buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "saved" })
      vim.cmd.write()
      t.eq(messages(buf, "ach_test"), {}, "straight after the save")
      local linted = vim.wait(2000, function() return messages(buf, "ach_test")[1] == "saved" end)
      t.ok(linted, "after the save")
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "typed" })
      vim.api.nvim_exec_autocmds("InsertLeave", { buffer = buf })
      linted = vim.wait(2000, function() return messages(buf, "ach_test")[1] == "typed" end)
      t.ok(linted, "after leaving insert mode")
    end)
  end,

  ["sqlfluff lints in the formatter's dialect, from the folder of the project's configuration"] = function(t)
    local L = require("ach.lint")
    local upstream = require("lint.linters.sqlfluff")
    local function adapted(path, ft)
      local buf = named(path)
      vim.bo[buf].filetype = ft
      return L.adapt.sqlfluff(vim.deepcopy(upstream), buf)
    end
    tidy(function()
      local loose = t.tmpdir()
      local def = adapted(loose .. "/query.sql", "sql")
      t.eq(def.args, { "lint", "--format=json", "--dialect", "ansi", "-" }, "a loose sql file")
      t.eq(def.cwd, loose, "where a loose file is linted")
      t.eq(adapted(loose .. "/query.mysql", "mysql").args[4], "mysql", "a mysql file's dialect")
      local project = t.tmpdir()
      vim.fn.writefile({ "[sqlfluff]", "dialect = postgres" }, project .. "/.sqlfluff")
      vim.fn.mkdir(project .. "/queries", "p")
      def = adapted(project .. "/queries/report.sql", "sql")
      t.eq(def.args, { "lint", "--format=json", "-" }, "a file below a .sqlfluff")
      t.eq(def.cwd, project, "where it is linted")
      t.eq(upstream.args, { "lint", "--format=json", "-" }, "upstream's own arguments, unchanged")
    end)
  end,

  ["markdownlint-cli2 lints from the folder of the project's configuration"] = function(t)
    local L = require("ach.lint")
    local upstream = require("lint.linters.markdownlint-cli2")
    tidy(function()
      local loose = t.tmpdir()
      local def = L.adapt["markdownlint-cli2"](vim.deepcopy(upstream), named(loose .. "/notes.md"))
      t.eq(def.cwd, loose, "where a loose file is linted")
      local project = t.tmpdir()
      vim.fn.writefile({ "{}" }, project .. "/.markdownlint-cli2.jsonc")
      vim.fn.mkdir(project .. "/book/chapters", "p")
      def = L.adapt["markdownlint-cli2"](vim.deepcopy(upstream), named(project .. "/book/chapters/one.md"))
      t.eq(def.cwd, project, "where a file below a .markdownlint-cli2.jsonc is linted")
      t.eq(def.args, { "-" }, "its arguments, unchanged")
      t.eq(upstream.cwd, nil, "upstream's own definition, unchanged")
    end)
  end,

  ["markdownlint-cli2 follows the project's configuration wherever Neovim was started"] = function(t)
    if vim.fn.executable("markdownlint-cli2") ~= 1 then
      t.skip("markdownlint-cli2 is not installed")
    end
    local L = require("ach.lint")
    local project = t.tmpdir()
    vim.fn.writefile({ '{ "config": { "MD013": false } }' }, project .. "/.markdownlint-cli2.jsonc")
    vim.fn.mkdir(project .. "/book", "p")
    local path = project .. "/book/one.md"
    vim.fn.writefile({ "# One", "", ("word "):rep(40) }, path)
    local started = vim.fn.getcwd()
    vim.cmd.cd(vim.fn.fnameescape(project .. "/book"))
    local ok, err = pcall(tidy, function()
      vim.cmd.edit(vim.fn.fnameescape(path))
      local buf = vim.api.nvim_get_current_buf()
      opened[#opened + 1] = buf
      L.run(buf, true)
      local rules = {}
      local linted = vim.wait(10000, function()
        rules = {}
        for _, message in ipairs(messages(buf, "markdownlint-cli2")) do
          rules[#rules + 1] = message:match("MD%d+")
        end
        return #rules > 0
      end)
      t.ok(linted, "markdownlint-cli2 reported")
      table.sort(rules)
      t.eq(rules, { "MD009" }, "the rules reported, with MD013 off as the project's configuration says")
    end)
    vim.cmd.cd(vim.fn.fnameescape(started))
    if not ok then
      error(err, 0)
    end
  end,

  ["tflint lints the file's own module"] = function(t)
    local L = require("ach.lint")
    tidy(function()
      local module = t.tmpdir()
      local buf = named(module .. "/main.tf")
      local def = L.adapt.tflint(vim.deepcopy(require("lint.linters.tflint")), buf)
      t.eq(def.cwd, module, "where it runs")
      t.eq(def.args, { "--format=json" }, "its arguments")
      local function issue(file, rule)
        return {
          rule = { name = rule, severity = "warning", link = "https://github.com/terraform-linters/tflint" },
          message = "declared but not used",
          range = { filename = file, start = { line = 2, column = 1 }, ["end"] = { line = 2, column = 13 } },
        }
      end
      local output = vim.json.encode({ issues = { issue("main.tf", "here"), issue("variables.tf", "there") } })
      local rules = {}
      for _, d in ipairs(def.parser(output, buf, module)) do
        rules[#rules + 1] = d.message:match("%((.-)%)")
      end
      t.eq(rules, { "here" }, "the rules reported for this file")
    end)
  end,

  ["golangci-lint lints the whole package, from the module's folder"] = function(t)
    local L = require("ach.lint")
    local upstream = {
      cmd = "golangci-lint",
      args = {
        "run",
        "--issues-exit-code=0",
        function() return "upstream's target" end,
      },
    }
    tidy(function()
      local module = t.tmpdir()
      vim.fn.writefile({ "module example.com/sample", "", "go 1.23" }, module .. "/go.mod")
      vim.fn.mkdir(module .. "/server", "p")
      local def = L.adapt.golangcilint(vim.deepcopy(upstream), named(module .. "/server/handler.go"))
      t.eq(def.cwd, module, "where it runs inside a module")
      t.eq(def.args, { "run", "--issues-exit-code=0", module .. "/server" }, "its arguments inside a module")
      local loose = t.tmpdir()
      def = L.adapt.golangcilint(vim.deepcopy(upstream), named(loose .. "/main.go"))
      t.eq(def.cwd, loose, "where it runs outside a module")
      t.eq(def.args, { "run", "--issues-exit-code=0", loose .. "/main.go" }, "its arguments outside a module")
      local real = require("lint.linters.golangcilint")
      if real.args then
        t.eq(type(real.args[#real.args]), "function", "upstream's last argument, the target this replaces")
      end
    end)
  end,
}
