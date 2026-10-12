local hook = require("ach.testhook")

local function read_lock(root)
  return vim.json.decode(table.concat(vim.fn.readfile(root .. "/lazy-lock.json"), "\n"))
end

return {
  ["every locked plugin is installed at its locked commit"] = function(t)
    local lock = read_lock(t.root)
    local plugins = require("lazy.core.config").plugins
    local git = require("lazy.manage.git")
    local bad = {}
    for name, entry in pairs(lock) do
      local p = plugins[name]
      if not p then
        table.insert(bad, name .. ": in the lock file but in no spec")
      elseif not p._.installed then
        table.insert(bad, name .. ": not installed")
      else
        local info = git.info(p.dir)
        if not info or info.commit ~= entry.commit then
          table.insert(bad, ("%s: at %s, locked at %s"):format(name, info and info.commit or "?", entry.commit))
        end
      end
    end
    for name in pairs(plugins) do
      if not lock[name] then
        table.insert(bad, name .. ": missing from the lock file")
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "plugins out of step with lazy-lock.json")
  end,

  ["every plugin loads without a warning"] = function(t)
    local before = #hook.warnings()
    local failed = {}
    for name in pairs(require("lazy.core.config").plugins) do
      local ok, err = pcall(require("lazy").load, { plugins = { name } })
      if not ok then
        table.insert(failed, name .. ": " .. tostring(err))
      end
    end
    vim.wait(500)
    for _, w in ipairs(vim.list_slice(hook.warnings(), before + 1)) do
      table.insert(failed, "warning: " .. w.msg)
    end
    table.sort(failed)
    t.eq(failed, {}, "plugins that failed to load")
  end,
}
