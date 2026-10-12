return {
  ["finds the repository root"] = function(t)
    t.ok(vim.uv.fs_stat(t.root .. "/init.lua"), "init.lua should sit at " .. t.root)
    t.eq(vim.g.ach_root, vim.uv.fs_realpath(t.root))
  end,

  ["resolves the root through a symbolic link"] = function(t)
    local link = t.tmpdir() .. "/nvim"
    assert(vim.uv.fs_symlink(t.root, link))
    local r = vim.system({ vim.v.progpath, "--headless", "-u", link .. "/init.lua",
      "+lua io.stdout:write(vim.g.ach_root)", "+qall!" }, { text = true }):wait()
    vim.uv.fs_unlink(link)
    t.eq(r.stdout, t.root, "root seen through " .. link)
  end,

  ["exits 2 with the install command when Neovim is missing"] = function(t)
    local r = vim.system({ t.root .. "/scripts/check" }, { env = { PATH = "/usr/bin:/bin" }, text = true }):wait()
    t.eq(r.code, 2, "exit code")
    t.ok(r.stderr:find("brew install neovim", 1, true), "message should name the install command, got: " .. r.stderr)
  end,

  ["fails when --only matches no test"] = function(t)
    local r = vim.system({ t.root .. "/scripts/check", "--only", "no test is named this" }, { text = true }):wait()
    t.eq(r.code, 1, "exit code")
    t.ok(r.stdout:find("no test matches", 1, true), "the report should say why, got: " .. r.stdout)
  end,

  ["keeps test state out of the real state folder"] = function(t)
    t.ok(vim.env.XDG_STATE_HOME, "XDG_STATE_HOME should be set by scripts/check")
    t.eq(vim.fn.stdpath("state"):find(vim.env.XDG_STATE_HOME, 1, true), 1)
  end,

  ["records warnings raised through vim.notify"] = function(t)
    local hook = require("ach.testhook")
    local before = #hook.warnings()
    vim.notify("harness probe", vim.log.levels.WARN)
    vim.notify("harness info", vim.log.levels.INFO)
    vim.wait(100)
    t.eq(#hook.warnings() - before, 1, "only the warning is recorded")
  end,
}
