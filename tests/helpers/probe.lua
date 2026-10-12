-- Runs inside a child Neovim that the full test starts with the installer
-- live. It opens one language's sample, lets the installer do what it does on
-- a first open, then tries each layer and returns the language's result: for
-- each layer, the tools the table names for the sample's file type, those
-- that worked, and, for each that did not, the install command it is waiting
-- on when the reason is a missing runtime or Homebrew program.
local INSTALL_MS = 900000 -- a first install of the largest servers, such as jdtls
local ATTACH_MS = 180000
local REPORT_MS = 60000

return function(name, path)
  local lang = require("ach.lang")
  local install = require("ach.install")
  local grammar = require("ach.languages").grammar
  local entry = assert(lang.get(name), "no language named " .. name)

  -- ensure_tools calls install.ready through the module table, so this
  -- wrapper marks the moment the buffer's packages have installed or failed.
  local ready = false
  local inner = install.ready
  install.ready = function(...)
    inner(...)
    ready = true
  end

  -- The full run installs nothing from Homebrew, so every offer to install is
  -- answered no here, where nobody could answer it.
  install.ask = function(_, cb) cb(false) end

  -- With the runtime missing, ready is never called and only parsers install.
  local runtime_ok = true
  if entry.runtime then
    local answer
    require("ach.runtimes").check(entry.runtime, function(ok) answer = ok end)
    vim.wait(REPORT_MS, function() return answer ~= nil end, 50)
    runtime_ok = answer == true
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local system = lang.system_for_ft(ft)

  -- A missing program of the tool's own comes first: Homebrew programs are
  -- offered whether or not the runtime works, so the runtime is not what
  -- holds them back.
  local function waiting_on(programs, uses_runtime)
    for _, program in ipairs(programs or {}) do
      if system[program] and vim.fn.executable(program) ~= 1 then
        return system[program]
      end
    end
    if uses_runtime and not runtime_ok then
      return lang.command(entry.runtime)
    end
  end

  local function layer(want, works, programs, uses_runtime)
    local out = { want = want, works = {}, needs = {} }
    for _, tool in ipairs(want) do
      if works[tool] then
        out.works[#out.works + 1] = tool
      else
        out.needs[tool] = waiting_on(programs[tool], uses_runtime)
      end
    end
    return out
  end

  -- Tree-sitter. The hook asked for these same parsers, so this call shares
  -- its install and its callback runs after the hook has started highlighting.
  local own = vim.treesitter.language.get_lang(ft) or ft
  local parsed = false
  install.ensure_parsers(vim.list_extend(vim.deepcopy(entry.ts or {}), { own }), function() parsed = true end)
  vim.wait(INSTALL_MS, function() return parsed end, 200)
  local ts_want = #(entry.ts or {}) > 0 and { own } or {}
  local treesitter = layer(ts_want, { [own] = vim.treesitter.highlighter.active[buf] ~= nil }, {}, false)

  vim.wait(INSTALL_MS, function() return ready or not runtime_ok end, 200)

  -- Servers: each one whose configuration takes this file type, and the
  -- client a managed language's own plugin starts. Harper is the grammar layer.
  local lsp = require("ach.lsp")
  local server_want, server_programs = {}, {}
  for _, server in ipairs(entry.lsp or {}) do
    local fts = (vim.lsp.config[server] or {}).filetypes
    if not fts or vim.list_contains(fts, ft) then
      server_want[#server_want + 1] = server
      server_programs[server] = { lsp.program(server) }
    end
  end
  local managed_client = entry.managed and require("ach.managed").clients[entry.managed]
  if managed_client then
    server_want[#server_want + 1] = managed_client
  end
  local grammar_want = lang.is_harper_ft(ft) and { grammar.server } or {}

  local function attached()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      names[client.name] = true
    end
    return names
  end
  -- A server whose program is missing is never enabled, so waiting for it
  -- would cost the whole wait and prove nothing.
  local function can_start(server)
    if server == managed_client then
      return true
    end
    local program = server == grammar.server and grammar.program or lsp.program(server)
    return program ~= nil and vim.fn.executable(program) == 1
  end
  local expected = {}
  if runtime_ok then
    for _, server in ipairs(vim.list_extend(vim.deepcopy(server_want), grammar_want)) do
      if can_start(server) then
        expected[#expected + 1] = server
      end
    end
  end
  vim.wait(ATTACH_MS, function()
    local now = attached()
    for _, server in ipairs(expected) do
      if not now[server] then
        return false
      end
    end
    return true
  end, 200)
  local server = layer(server_want, attached(), server_programs, true)

  -- Linters, on the sample as written, before any formatter changes it.
  local lint = require("ach.lint")
  local nvim_lint = require("lint")
  local lint_want = lang.linters_by_ft()[ft] or {}
  local runnable = {}
  for _, linter in ipairs(lint.linters_for(buf)) do
    runnable[linter] = true
  end
  local function reported(linter)
    return runnable[linter] == true and #vim.diagnostic.get(buf, { namespace = nvim_lint.get_namespace(linter) }) > 0
  end
  lint.run(buf, true)
  vim.wait(REPORT_MS, function()
    for _, linter in ipairs(lint_want) do
      if runnable[linter] and not reported(linter) then
        return false
      end
    end
    return true
  end, 200)
  local lint_works = {}
  for _, linter in ipairs(lint_want) do
    lint_works[linter] = reported(linter)
  end
  local linter = layer(lint_want, lint_works, lint.commands, true)

  -- Harper, attached and, where the sample plants "the the", flagging that
  -- line. Push and pull diagnostics live in different namespaces, so both
  -- are read.
  local function flags_planted_line()
    local row
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      if line:find("the the", 1, true) then
        row = i - 1
      end
    end
    if not row then
      return true
    end
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = grammar.server })) do
      for _, pull in ipairs({ false, true }) do
        local ns = vim.lsp.diagnostic.get_namespace(client.id, pull)
        if #vim.diagnostic.get(buf, { namespace = ns, lnum = row }) > 0 then
          return true
        end
      end
    end
    return false
  end
  local harper_works = {}
  if #grammar_want > 0 and attached()[grammar.server] then
    harper_works[grammar.server] = vim.wait(REPORT_MS, flags_planted_line, 200)
  end
  -- harper-ls is a Mason package, so only a missing runtime leaves it waiting.
  local grammar_layer = layer(grammar_want, harper_works, {}, true)

  -- Formatters, each alone on the sample as written, which it must change.
  local conform = require("conform")
  local fmt_want = lang.formatters_by_ft()[ft] or {}
  local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local fmt_works, fmt_programs = {}, {}
  for _, formatter in ipairs(fmt_want) do
    local info = conform.get_formatter_info(formatter, buf)
    fmt_programs[formatter] = info.command and { vim.fs.basename(info.command) } or {}
    if info.available then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
      local opts = { bufnr = buf, formatters = { formatter }, lsp_format = "never", timeout_ms = REPORT_MS }
      local ok = pcall(conform.format, opts)
      fmt_works[formatter] = ok and not vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), original)
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original)
  local formatter = layer(fmt_want, fmt_works, fmt_programs, true)

  return {
    name = name,
    layers = {
      treesitter = treesitter,
      server = server,
      formatter = formatter,
      linter = linter,
      grammar = grammar_layer,
    },
  }
end
