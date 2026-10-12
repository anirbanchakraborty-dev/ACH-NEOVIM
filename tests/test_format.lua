-- Formatting. Every formatter the table names is one conform knows, and
-- reaches it; prettier, shfmt and sqlfluff get this configuration's
-- arguments; prose formats on save only when switched on; either switch stops
-- a save from formatting; a save runs the file type's formatter, and one not
-- installed yet lets the save through as typed and silent; a formatter that
-- runs out of time, or is known to be slow, runs after the write instead; the
-- keys have their icons; and gq rewraps where nothing formats. The buffer
-- tests use a file type of their own, achtest, whose formatter is a command
-- every Mac has, so no real formatter needs to be installed.
local I = require("ach.icons")

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

-- Runs body, then wipes the buffers it opened and forgets any timeouts, even
-- when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if package.loaded["ach.format"] then
    package.loaded["ach.format"].reset()
  end
  if not ok then
    error(err, 0)
  end
end

-- A new scratch buffer, of file type ft when one is given.
local function scratch(ft)
  local buf = vim.api.nvim_create_buf(false, true)
  opened[#opened + 1] = buf
  if ft then
    vim.bo[buf].filetype = ft
  end
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

-- Gives the file type achtest one formatter, ach_test, which runs command
-- with args, for the length of body.
local function with_formatter(command, args, body)
  local conform = require("conform")
  tidy(
    function()
      with({
        { conform.formatters, "ach_test", { command = command, args = args } },
        { conform.formatters_by_ft, "achtest", { "ach_test" } },
      }, body)
    end
  )
end

-- The arguments conform would give the formatter called name for a file of
-- type ft in the folder dir. Call it inside tidy.
local function args_for(name, ft, dir)
  local buf = scratch(ft)
  local config = assert(require("conform").get_formatter_config(name, buf), "conform has no " .. name)
  local ctx = { buf = buf, filename = dir .. "/sample", dirname = dir, shiftwidth = vim.bo[buf].shiftwidth }
  if type(config.args) == "function" then
    return config.args(config, ctx)
  end
  return config.args
end

return {
  ["every formatter the table names is one conform knows"] = function(t)
    local conform = require("conform")
    local unknown, used = {}, {}
    for ft, names in pairs(require("ach.lang").formatters_by_ft()) do
      for _, name in ipairs(names) do
        used[name] = true
        if not conform.get_formatter_config(name) then
          unknown[#unknown + 1] = ft .. ": " .. name
        end
      end
    end
    table.sort(unknown)
    t.eq(unknown, {}, "formatters conform has no definition for")
    local stray = {}
    for name in pairs(require("ach.format").slow) do
      if not used[name] then
        stray[#stray + 1] = name
      end
    end
    table.sort(stray)
    t.eq(stray, {}, "slow formatters no file type uses")
  end,

  ["conform has every file type's formatters"] = function(t)
    local conform = require("conform")
    local want = require("ach.lang").formatters_by_ft()
    local got = {}
    for ft in pairs(want) do
      got[ft] = conform.formatters_by_ft[ft]
    end
    t.eq(got, want)
  end,

  ["prettier indents scripts, JSON and stylesheets by four and leaves the rest alone"] = function(t)
    local fmt = require("ach.format")
    local formats = require("ach.lang").formatters_by_ft()
    tidy(function()
      local dir = t.tmpdir()
      local four = { "--config-precedence", "prefer-file", "--tab-width", "4", "--stdin-filepath", "$FILENAME" }
      for _, ft in ipairs(fmt.four_wide) do
        t.ok(vim.list_contains(formats[ft] or {}, "prettier"), ft .. " is formatted by prettier")
        t.eq(args_for("prettier", ft, dir), four, ft)
      end
      for _, ft in ipairs({ "yaml", "html", "markdown", "graphql", "vue" }) do
        t.eq(args_for("prettier", ft, dir), { "--stdin-filepath", "$FILENAME" }, ft)
      end
    end)
  end,

  ["shfmt indents by four unless an .editorconfig above the file says otherwise"] = function(t)
    tidy(function()
      t.eq(args_for("shfmt", "sh", t.tmpdir()), { "-filename", "$FILENAME", "-i", "4" }, "with no .editorconfig")
      local project = t.tmpdir()
      vim.fn.writefile({ "root = true" }, project .. "/.editorconfig")
      vim.fn.mkdir(project .. "/scripts", "p")
      t.eq(args_for("shfmt", "bash", project .. "/scripts"), { "-filename", "$FILENAME" }, "below an .editorconfig")
    end)
  end,

  ["sqlfluff is told the dialect, or runs beside the project's own configuration"] = function(t)
    local function project(file, lines)
      local dir = t.tmpdir()
      vim.fn.writefile(lines, dir .. "/" .. file)
      return dir
    end
    tidy(function()
      local loose = t.tmpdir()
      t.eq(args_for("sqlfluff", "sql", loose), { "format", "--dialect", "ansi", "-" }, "sql")
      t.eq(args_for("sqlfluff", "mysql", loose), { "format", "--dialect", "mysql", "-" }, "mysql")
      t.eq(args_for("sqlfluff", "plsql", loose), { "format", "--dialect", "oracle", "-" }, "plsql")
      local own = project(".sqlfluff", { "[sqlfluff]", "dialect = postgres" })
      t.eq(args_for("sqlfluff", "sql", own), { "format", "-" }, "beside a .sqlfluff")
      local py = project("pyproject.toml", { "[tool.sqlfluff.core]", 'dialect = "bigquery"' })
      t.eq(args_for("sqlfluff", "sql", py), { "format", "-" }, "beside a pyproject.toml with a sqlfluff section")
      local other = project("pyproject.toml", { "[tool.ruff]", "line-length = 100" })
      t.eq(args_for("sqlfluff", "sql", other), { "format", "--dialect", "ansi", "-" }, "beside one without")
      local config = require("conform").get_formatter_config("sqlfluff")
      t.eq(config.require_cwd, false, "runs outside a configured project")
      vim.fn.mkdir(own .. "/queries", "p")
      t.eq(config.cwd(config, { dirname = own .. "/queries" }), own, "the folder it runs in, below a .sqlfluff")
      t.eq(config.cwd(config, { dirname = other }), nil, "the folder it runs in, outside a configured project")
    end)
  end,

  ["prose formats on save only when switched on"] = function(t)
    tidy(function()
      local on = {}
      for _, ft in ipairs(require("ach.lang").manual_filetypes()) do
        if vim.b[scratch(ft)].autoformat ~= false then
          on[#on + 1] = ft
        end
      end
      t.eq(on, {}, "prose file types that would format on save")
      t.eq(vim.b[scratch("python")].autoformat, nil, "a python buffer's switch")
      local became = scratch("markdown")
      vim.bo[became].filetype = "python"
      t.eq(vim.b[became].autoformat, nil, "a markdown buffer that became python")
      local mine = scratch("python")
      vim.b[mine].autoformat = true
      vim.bo[mine].filetype = "markdown"
      t.eq(vim.b[mine].autoformat, true, "a buffer switched on by hand that became markdown")
    end)
  end,

  ["either switch stops a save from formatting"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      local buf, path = open(t, "hello")
      t.eq(fmt.when(buf), "now", "with both switches on")
      with({ { vim.g, "autoformat", false } }, function() t.eq(fmt.when(buf), nil, "with the global switch off") end)
      with({ { vim.b[buf], "autoformat", false } }, function()
        t.eq(fmt.when(buf), nil, "with the buffer's switch off")
        vim.cmd.write()
        t.eq(vim.fn.readfile(path), { "hello" }, "the file, saved with the buffer's switch off")
      end)
    end)
  end,

  ["a save runs the file type's formatter"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local buf, path = open(t, "hello")
      vim.cmd.write()
      t.eq(vim.fn.readfile(path), { "HELLO" }, "the file on disk")
      t.eq(vim.bo[buf].modified, false, "the buffer is saved")
    end)
  end,

  ["a save before the formatter is installed writes the file as typed and says nothing"] = function(t)
    with_formatter("ach-formatter-not-installed-yet", {}, function()
      local notes = {}
      local function note(msg, level) notes[#notes + 1] = { msg, level } end
      with({ { vim, "notify", note } }, function()
        local buf, path = open(t, "hello")
        vim.v.errmsg = ""
        vim.cmd.write()
        vim.wait(200) -- conform sends its messages on the next turn of the event loop
        t.eq(vim.fn.readfile(path), { "hello" }, "the file on disk")
        t.eq(vim.bo[buf].modified, false, "the buffer is saved")
        t.eq(vim.v.errmsg, "", "the last error message")
        t.eq(notes, {}, "messages")
        require("conform").format({ bufnr = buf })
        vim.wait(200)
        t.ok(#notes > 0, "conform warns when asked outright, so the save's silence is this configuration's doing")
      end)
    end)
  end,

  ["a formatter that runs out of time formats after the write from then on"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      local buf = open(t, "hello")
      local opts, done = fmt.on_save(buf)
      t.eq(opts, { timeout_ms = fmt.timeout_ms, lsp_format = "fallback" }, "the save's options")
      done(nil)
      done("Formatter 'ach_test' exited with code 2")
      t.eq(fmt.when(buf), "now", "after a success and a failure")
      local notes = {}
      local function note(msg) notes[#notes + 1] = msg end
      with({ { vim, "notify", note } }, function() done("Formatter 'ach_test' timeout") end)
      t.eq(notes, { "achtest files format after each save from now on" }, "the message")
      t.eq(fmt.when(buf), "after", "after a timeout")
      t.eq(fmt.on_save(buf), nil, "the save's options")
      t.eq(fmt.after_save(buf), { lsp_format = "fallback" }, "the options after the save")
    end)
  end,

  ["formatters known to be slow run after the write"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local fmt = require("ach.format")
      with({ { fmt.slow, "ach_test", true } }, function()
        local buf, path = open(t, "hello")
        t.eq(fmt.when(buf), "after", "when it runs")
        t.eq(fmt.on_save(buf), nil, "the save's options")
        vim.cmd.write()
        t.eq(vim.fn.readfile(path), { "hello" }, "the file as the save wrote it")
        local formatted = vim.wait(3000, function() return vim.fn.readfile(path)[1] == "HELLO" end)
        t.ok(formatted, "the file is written again, formatted")
        t.eq(vim.bo[buf].modified, false, "the buffer is saved")
      end)
    end)
  end,

  ["the format keys are mapped, each with an icon"] = function(t)
    local keys = { ["<leader>cf"] = "Format", ["<leader>cF"] = "Format Injected Langs" }
    for lhs, desc in pairs(keys) do
      for _, mode in ipairs({ "n", "x" }) do
        t.eq(vim.fn.maparg(lhs, mode, false, true).desc, desc, lhs .. " in mode " .. mode)
      end
      t.ok(I.key(desc), desc .. " has an icon")
    end
  end,

  ["gq formats with the file type's formatter, and rewraps where there is none"] = function(t)
    with_formatter("tr", { "a-z", "A-Z" }, function()
      local buf = open(t, "one two three four")
      vim.cmd("normal! gqq")
      t.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "ONE TWO THREE FOUR" }, "with a formatter")
      local plain = scratch()
      vim.api.nvim_set_current_buf(plain)
      vim.bo[plain].textwidth = 10
      vim.api.nvim_buf_set_lines(plain, 0, -1, false, { "one two three four" })
      vim.cmd("normal! gqq")
      t.eq(vim.api.nvim_buf_get_lines(plain, 0, -1, false), { "one two", "three four" }, "with none")
    end)
  end,
}
