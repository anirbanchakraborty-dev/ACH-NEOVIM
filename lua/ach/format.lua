-- Formatting. conform.nvim runs the formatters; this module decides which
-- run, with what arguments, and when: during a save, after it, or not at all.
local M = {}

-- How long a save waits for its formatters before writing the file as typed.
M.timeout_ms = 1000

-- Formatters that start a Java, .NET, Python, Ruby or PHP runtime, too slow
-- for a save to wait on. They run once the file is written, and the buffer is
-- written again with their changes.
M.slow = {
  ktlint = true,
  csharpier = true,
  fantomas = true,
  sqlfluff = true,
  rubocop = true,
  erb_format = true,
  php_cs_fixer = true,
}

-- File types prettier indents by four spaces rather than its default of two.
M.four_wide = {
  "javascript",
  "javascriptreact",
  "javascript.jsx",
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "json",
  "jsonc",
  "json5",
  "css",
  "scss",
  "less",
}

-- sqlfluff's dialect for each SQL file type, used where the project names none.
M.dialects = { sql = "ansi", mysql = "mysql", plsql = "oracle" }

local sqlfluff_files = { ".sqlfluff", "pyproject.toml", "setup.cfg", "tox.ini", "pep8.ini" }

-- File types whose formatters ran out of time this session.
local timed_out = {}

-- The folder holding the sqlfluff configuration nearest to dir, at dir or
-- above it: a .sqlfluff, or a pyproject.toml, setup.cfg, tox.ini or pep8.ini
-- with a sqlfluff section. nil when there is none.
function M.sqlfluff_root(dir)
  for _, path in ipairs(vim.fs.find(sqlfluff_files, { path = dir, upward = true, limit = math.huge })) do
    local configures = vim.fs.basename(path) == ".sqlfluff"
    if not configures then
      local f = io.open(path)
      if f then
        local text = f:read("*a")
        f:close()
        configures = text:find("[sqlfluff", 1, true) ~= nil or text:find("[tool.sqlfluff", 1, true) ~= nil
      end
    end
    if configures then
      return vim.fs.dirname(path)
    end
  end
  return nil
end

-- The dialect to give sqlfluff for this buffer, or nil inside a project that
-- configures sqlfluff, whose configuration names the dialect.
function M.sqlfluff_dialect(buf, dir)
  if M.sqlfluff_root(dir) then
    return nil
  end
  return M.dialects[vim.bo[buf].filetype] or "ansi"
end

-- Changes merged over conform's own definitions of these formatters.
M.formatters = {
  -- prefer-file: prettier drops both flags when the project has a
  -- configuration of its own, an .editorconfig included.
  prettier = {
    prepend_args = function(_, ctx)
      if vim.list_contains(M.four_wide, vim.bo[ctx.buf].filetype) then
        return { "--config-precedence", "prefer-file", "--tab-width", "4" }
      end
      return {}
    end,
  },
  -- shfmt reads an .editorconfig only when given no formatting flag, so -i is
  -- left off wherever one is found.
  shfmt = {
    args = function(_, ctx)
      local args = { "-filename", "$FILENAME" }
      if not vim.fs.find(".editorconfig", { path = ctx.dirname, upward = true })[1] then
        vim.list_extend(args, { "-i", "4" })
      end
      return args
    end,
  },
  -- format applies only the layout and capitalisation rules. conform's own
  -- definition runs fix, and only inside a configured project. sqlfluff reads
  -- its configuration from the folder it runs in.
  sqlfluff = {
    require_cwd = false,
    cwd = function(_, ctx) return M.sqlfluff_root(ctx.dirname) end,
    args = function(_, ctx)
      local dialect = M.sqlfluff_dialect(ctx.buf, ctx.dirname)
      if dialect then
        return { "format", "--dialect", dialect, "-" }
      end
      return { "format", "-" }
    end,
  },
  -- A code block that fails to format does not stop the others.
  injected = { options = { ignore_errors = true } },
}

-- When a save formats this buffer: "now", during the save; "after", once the
-- file is written; or nil, not at all, because a switch is off or nothing
-- that could format it is installed.
function M.when(buf)
  if vim.g.autoformat == false or vim.b[buf].autoformat == false then
    return nil
  end
  local formatters, lsp = require("conform").list_formatters_to_run(buf)
  if #formatters == 0 and not lsp then
    return nil
  end
  if timed_out[vim.bo[buf].filetype] then
    return "after"
  end
  for _, f in ipairs(formatters) do
    if M.slow[f.name] then
      return "after"
    end
  end
  return "now"
end

-- conform's format_on_save. Returning nothing lets the save through as
-- typed, which is what a file whose formatter is still installing gets, with
-- no message. A file type that runs out of time moves to after the save.
function M.on_save(buf)
  if M.when(buf) ~= "now" then
    return nil
  end
  local ft = vim.bo[buf].filetype
  return { timeout_ms = M.timeout_ms, lsp_format = "fallback" }, function(err)
    if err and err:match("timeout$") then
      timed_out[ft] = true
      vim.notify(("%s files format after each save from now on"):format(ft), vim.log.levels.INFO)
    end
  end
end

-- conform's format_after_save: formats in the background once the file is
-- written, then writes it again.
function M.after_save(buf)
  if M.when(buf) == "after" then
    return { lsp_format = "fallback" }
  end
  return nil
end

-- 'formatexpr'. gq formats with the file type's formatter or language server
-- where one is installed, and leaves the lines to Vim's own rewrapping where
-- neither is, and while typing past 'textwidth'.
function M.formatexpr()
  if vim.fn.mode():match("^[iR]") then
    return 1
  end
  local formatters, lsp = require("conform").list_formatters_to_run(0)
  if #formatters == 0 and not lsp then
    return 1
  end
  return require("conform").formatexpr()
end

-- A buffer of a prose file type starts with its switch off. One that leaves
-- prose gets the switch back, unless it was set by hand.
local function on_filetype(buf, ft)
  local manual = require("ach.lang").is_manual(ft)
  if manual and vim.b[buf].autoformat == nil then
    vim.b[buf].autoformat = false
    vim.b[buf].ach_prose_off = true
  elseif not manual and vim.b[buf].ach_prose_off then
    vim.b[buf].autoformat = nil
    vim.b[buf].ach_prose_off = nil
  end
end

-- Called from the conform spec's init, before any file is open.
function M.setup()
  vim.o.formatexpr = "v:lua.require'ach.format'.formatexpr()"
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ach_format", { clear = true }),
    callback = function(ev) on_filetype(ev.buf, ev.match) end,
  })
end

-- Forgets which file types ran out of time this session.
function M.reset() timed_out = {} end

-- conform's options.
function M.opts()
  return {
    formatters_by_ft = require("ach.lang").formatters_by_ft(),
    formatters = M.formatters,
    default_format_opts = { lsp_format = "fallback" },
    format_on_save = M.on_save,
    format_after_save = M.after_save,
  }
end

return M
