-- Test-only instrumentation, installed by init.lua when ACH_TEST=1. It records
-- every warning or error raised through vim.notify, and every key that a file
-- under lua/ach/ sets, split by whether it carries a description, so tests can
-- fail on a warning, on a key with no description, or on a key with no icon.
local M = { notifications = {}, keymaps = {}, keymaps_without_desc = {} }

function M.install()
  local notify = vim.notify
  vim.notify = function(msg, level, opts)
    if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
      table.insert(M.notifications, { msg = tostring(msg), level = level })
    end
    return notify(msg, level, opts)
  end

  local set = vim.keymap.set
  vim.keymap.set = function(mode, lhs, rhs, opts)
    local source = debug.getinfo(2, "S").source
    if source:find("/lua/ach/", 1, true) then
      local desc = opts and opts.desc
      if desc and desc ~= "" then
        table.insert(M.keymaps, { mode = mode, lhs = lhs, desc = desc, where = source:sub(2) })
      else
        table.insert(M.keymaps_without_desc, { mode = mode, lhs = lhs, where = source:sub(2) })
      end
    end
    return set(mode, lhs, rhs, opts)
  end
end

-- Warnings and errors from startup on. snacks.notifier replaces vim.notify when
-- it loads, so anything raised after that point is read from its history.
function M.warnings()
  local out = vim.deepcopy(M.notifications)
  local ok, history = pcall(function() return Snacks.notifier.get_history() end)
  if ok and type(history) == "table" then
    for _, n in ipairs(history) do
      if n.level == "warn" or n.level == "error" then
        table.insert(out, { msg = tostring(n.msg), level = n.level })
      end
    end
  end
  return out
end

return M
