-- Runs a second, headless Neovim with this configuration and returns what its
-- body reported. The body is Lua source that runs after VeryLazy and calls
-- report(value) once, with any value vim.json can encode. The child runs
-- dry, so it never downloads, whatever mode the suite itself is in.
--
-- The body runs from +luafile, before Neovim has finished starting, unless
-- opts.entered is set. Then it waits for VimEnter, as everything a person
-- types does. The difference matters to language servers: vim.lsp.enable
-- attaches a buffer that is already open only once Neovim has entered.
local M = {}

function M.run(t, body, opts)
  opts = opts or {}
  local dir = t.tmpdir()
  local out = dir .. "/report.json"
  local script = dir .. "/child.lua"
  local source = table.concat({
    ("local out = %q"):format(out),
    "local function report(value)",
    "  vim.fn.writefile({ vim.json.encode(value) }, out)",
    "  vim.cmd('qall!')",
    "end",
    "local function run()",
    "  vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })",
    "  vim.wait(10000, function() return vim.g.did_very_lazy == true end, 20)",
    "  local ok, err = pcall(function()",
    body,
    "  end)",
    "  vim.fn.writefile({ vim.json.encode({ child_error = ok and 'the body never called report()' or tostring(err) }) }, out)",
    "  vim.cmd('qall!')",
    "end",
    opts.entered
        and "vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function() vim.schedule(run) end })"
      or "run()",
  }, "\n")
  vim.fn.writefile(vim.split(source, "\n"), script)

  local cmd = { vim.v.progpath, "--headless", "-u", t.root .. "/init.lua" }
  vim.list_extend(cmd, opts.args or {})
  cmd[#cmd + 1] = "+luafile " .. script
  local env = vim.tbl_extend("force", { ACH_TEST = "1", ACH_DRY_INSTALL = "1" }, opts.env or {})
  local result = vim.system(cmd, { env = env, cwd = opts.cwd, text = true, timeout = opts.timeout or 30000 }):wait()

  local f = io.open(out)
  if not f then
    error(
      ("the child Neovim reported nothing (exit %s)\n%s%s"):format(
        result.code,
        result.stdout or "",
        result.stderr or ""
      ),
      0
    )
  end
  local value = vim.json.decode(f:read("*a"))
  f:close()
  if type(value) == "table" and value.child_error then
    error("the child Neovim failed: " .. value.child_error, 0)
  end
  return value
end

return M
