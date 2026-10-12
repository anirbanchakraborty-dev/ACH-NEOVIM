-- The programs from outside Neovim that a key or command calls, each with the
-- Homebrew line that installs it. The configuration never installs one: a key
-- whose program is missing says what to run and does nothing else, and
-- :checkhealth ach lists every one under Integrations.
local M = {}

---@class ach.Program
---@field name string the program, as looked for on the path
---@field label? string what the owner calls it, when that is not its name
---@field brew string the line that installs it
---@field purpose string what it is for, as a noun phrase

---@type ach.Program[]
M.programs = {
  -- Programs added by later tasks go above this line.
}

---@param name string
---@return ach.Program?
function M.get(name)
  for _, p in ipairs(M.programs) do
    if p.name == name then
      return p
    end
  end
end

-- Whether the program called name is on the path. Prints nothing.
---@param name string
---@return boolean
function M.found(name) return vim.fn.executable(name) == 1 end

-- Whether the program called name is on the path. When it is not, prints the
-- line that installs it, so the key that asked can simply stop. A name the
-- list does not hold is an error, so a misspelt key fails in the tests.
---@param name string
---@return boolean
function M.have(name)
  local p = M.get(name)
  if not p then
    error(("ach.need has no program called %s"):format(name), 2)
  end
  if M.found(name) then
    return true
  end
  vim.notify(("%s is not installed. Install it with: %s"):format(p.label or p.name, p.brew), vim.log.levels.WARN)
  return false
end

return M
