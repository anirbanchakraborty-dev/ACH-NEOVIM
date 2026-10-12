return {
  ["loads with no errors or warnings"] = function(t)
    t.eq(t.startup.errmsg, "", "v:errmsg after startup")
    t.eq(t.startup.warnings, {}, "warnings and errors raised during startup")
  end,

  ["sets the editor options"] = function(t)
    t.eq(vim.g.mapleader, " ")
    t.ok(vim.o.exrc, "exrc must be on, so a trusted .nvim.lua is read")
    t.ok(vim.o.undofile, "undo history is kept on disk")
    t.eq(
      vim.fn.expand(vim.o.undodir):find(vim.fn.stdpath("state"), 1, true),
      1,
      "undo files live under the state folder"
    )
    t.eq(vim.opt.spelllang:get(), { "en_us" })
    t.eq(vim.o.shiftwidth, 4)
    t.ok(vim.env.PATH:find(vim.fn.stdpath("data") .. "/mason/bin", 1, true), "Mason's bin folder is on PATH")
  end,

  ["writes the lock file into the repository"] = function(t)
    t.eq(require("lazy.core.config").options.lockfile, t.root .. "/lazy-lock.json")
  end,
}
