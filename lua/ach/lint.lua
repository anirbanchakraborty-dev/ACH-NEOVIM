-- Linting. nvim-lint runs the linters; this module decides which can run and
-- when, and what three of them need beyond their upstream definitions.
local M = {}

-- When linting runs. Leaving insert mode runs only the linters that are sent
-- the buffer's text; the rest read the file on disk, so they wait for a save.
M.events = { "BufReadPost", "BufWritePost", "InsertLeave" }

-- How long linting waits after an event, so a burst of events costs one run.
M.debounce_ms = 100

-- The programs each linter needs, its own first. A linter runs only once all
-- of them are installed. They are listed here rather than read from the
-- definitions because loading golangcilint's definition runs golangci-lint
-- and go, and one loaded before they are installed stays broken.
M.commands = {
  cmakelint = { "cmakelint" },
  golangcilint = { "golangci-lint", "go" },
  hadolint = { "hadolint" },
  hlint = { "hlint" },
  ktlint = { "ktlint" },
  ["markdownlint-cli2"] = { "markdownlint-cli2" },
  phpcs = { "phpcs" },
  sqlfluff = { "sqlfluff" },
  statix = { "statix" },
  tclint = { "tclint" },
  tflint = { "tflint" },
}

-- Changes to three upstream definitions. Each takes a copy of the definition
-- and the buffer about to be linted, and returns the linter to run.
M.adapt = {
  -- Without a dialect sqlfluff checks nothing, and it reads a project's
  -- configuration from the folder it runs in.
  sqlfluff = function(def, buf)
    local fmt = require("ach.format")
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    local dialect = fmt.sqlfluff_dialect(buf, dir)
    if dialect then
      table.insert(def.args, #def.args, "--dialect")
      table.insert(def.args, #def.args, dialect)
    end
    def.cwd = fmt.sqlfluff_root(dir) or dir
    return def
  end,

  -- A Terraform module is one folder. tflint names files relative to the
  -- folder it runs in, and upstream matches them against the buffer's name
  -- relative to Neovim's, so each name is rewritten before it is matched.
  tflint = function(def, buf)
    def.cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
    def.args = vim.tbl_filter(function(arg) return arg ~= "--recursive" end, def.args)
    local parse = def.parser
    def.parser = function(output, bufnr, cwd)
      local ok, decoded = pcall(vim.json.decode, output)
      if ok and type(decoded) == "table" and type(decoded.issues) == "table" then
        for _, issue in ipairs(decoded.issues) do
          local file = type(issue.range) == "table" and issue.range.filename or nil
          if type(file) == "string" and file:sub(1, 1) ~= "/" then
            issue.range.filename = vim.fn.fnamemodify(vim.fs.joinpath(cwd, file), ":.")
          end
        end
        output = vim.json.encode(decoded)
      end
      return parse(output, bufnr, cwd)
    end
    return def
  end,

  -- golangci-lint checks a whole package, from inside its module. Upstream
  -- chooses between the package and the lone file once, from Neovim's own
  -- folder; this chooses for each file. Upstream's last argument is the
  -- function that names what to lint, and it is replaced.
  golangcilint = function(def, buf)
    local file = vim.api.nvim_buf_get_name(buf)
    local dir = vim.fs.dirname(file)
    local mod = vim.fs.find("go.mod", { path = dir, upward = true })[1]
    def.cwd = mod and vim.fs.dirname(mod) or dir
    local args = def.args or {}
    def.args = vim.list_slice(args, 1, #args - 1)
    def.args[#def.args + 1] = mod and dir or file
    return def
  end,
}

local function installed(name)
  local programs = M.commands[name]
  if not programs then
    return false
  end
  for _, program in ipairs(programs) do
    if vim.fn.executable(program) ~= 1 then
      return false
    end
  end
  return true
end

-- The linters that will run on buf, in the table's order: those of its file
-- type whose programs are installed. None for a buffer that is not a file. A
-- compound file type the table does not name, such as markdown.pandoc, gets
-- the linters of each of its parts, as nvim-lint resolves it.
function M.linters_for(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
    return {}
  end
  local by_ft, ft = require("lint").linters_by_ft, vim.bo[buf].filetype
  local wanted = by_ft[ft]
  if not wanted then
    wanted = {}
    for _, part in ipairs(vim.split(ft, ".", { plain = true })) do
      vim.list_extend(wanted, by_ft[part] or {})
    end
  end
  local names, seen = {}, {}
  for _, name in ipairs(wanted) do
    if not seen[name] and installed(name) then
      seen[name] = true
      names[#names + 1] = name
    end
  end
  return names
end

-- Lints buf now: every linter when all is true, otherwise only those that are
-- sent the buffer's text.
function M.run(buf, all)
  local names = M.linters_for(buf)
  if #names == 0 then
    return
  end
  vim.api.nvim_buf_call(buf, function() require("lint").try_lint(names, { filter = not all and "stdin" or nil }) end)
end

-- Calls waiting out their pause, by buffer.
local pending = {}

-- Lints buf once debounce_ms passes with no further call for it, running
-- every linter if any of the calls asked for all of them.
function M.schedule(buf, all)
  local p = pending[buf] or { all = false, n = 0 }
  pending[buf] = p
  p.all = p.all or all
  p.n = p.n + 1
  local n = p.n
  vim.defer_fn(function()
    if pending[buf] == p and p.n == n then
      pending[buf] = nil
      M.run(buf, p.all)
    end
  end, M.debounce_ms)
end

-- Called from nvim-lint's spec once the plugin loads.
function M.setup()
  local lint = require("lint")
  lint.linters_by_ft = require("ach.lang").linters_by_ft()
  for name, adapt in pairs(M.adapt) do
    lint.linters[name] = function()
      return adapt(vim.deepcopy(require("lint.linters." .. name)), vim.api.nvim_get_current_buf())
    end
  end
  vim.api.nvim_create_autocmd(M.events, {
    group = vim.api.nvim_create_augroup("ach_lint", { clear = true }),
    callback = function(ev) M.schedule(ev.buf, ev.event ~= "InsertLeave") end,
  })
end

return M
