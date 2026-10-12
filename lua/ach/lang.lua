-- The language engine: turns lua/ach/languages.lua into the shape each plugin
-- takes. Every function is pure, so tests/test_lang.lua checks them with no
-- plugin loaded.
local L = require("ach.languages")
local M = {}

local entries, by_name, by_ft = {}, {}, {}
for name, entry in pairs(L.languages) do
  local e = vim.deepcopy(entry)
  e.name = name
  by_name[name] = e
  entries[#entries + 1] = e
  for _, ft in ipairs(e.ft) do
    by_ft[ft] = e
  end
end
table.sort(entries, function(a, b) return a.name < b.name end)

-- A field that is either one list for every file type or a map from file type to list.
local function for_this_ft(value, ft)
  if value == nil then
    return {}
  end
  if vim.islist(value) then
    return value
  end
  return value[ft] or {}
end

local function harper_on(e, ft)
  local h = e.harper
  return h == true or (type(h) == "table" and vim.tbl_contains(h, ft))
end

local function sorted_unique(list)
  local seen, out = {}, {}
  for _, v in ipairs(list) do
    if not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out)
  return out
end

function M.entries() return entries end

function M.get(name) return by_name[name] end

function M.for_ft(ft) return by_ft[ft] end

function M.parsers_for_ft(ft)
  local e = by_ft[ft]
  return e and e.ts or {}
end

function M.servers_for_ft(ft)
  local e = by_ft[ft]
  if not e then
    return {}
  end
  local out = vim.list_extend({}, e.lsp or {})
  if harper_on(e, ft) then
    out[#out + 1] = L.grammar.server
  end
  return out
end

function M.servers()
  local all = { L.grammar.server }
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.lsp or {})
  end
  return sorted_unique(all)
end

local function by_filetype(field)
  local out = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      local list = for_this_ft(e[field], ft)
      if #list > 0 then
        out[ft] = vim.deepcopy(list)
      end
    end
  end
  return out
end

function M.formatters_by_ft() return by_filetype("fmt") end

function M.linters_by_ft() return by_filetype("lint") end

function M.packages_for_ft(ft, server_to_package)
  local e = by_ft[ft]
  if not e then
    return {}
  end
  local out = {}
  for _, server in ipairs(e.lsp or {}) do
    out[#out + 1] = server_to_package[server]
  end
  vim.list_extend(out, e.mason or {})
  if harper_on(e, ft) then
    out[#out + 1] = L.grammar.package
  end
  return sorted_unique(out)
end

function M.harper_filetypes()
  local out = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      if harper_on(e, ft) then
        out[#out + 1] = ft
      end
    end
  end
  table.sort(out)
  return out
end

function M.is_harper_ft(ft)
  local e = by_ft[ft]
  return e ~= nil and harper_on(e, ft)
end

function M.manual_filetypes()
  local out = {}
  for _, e in ipairs(entries) do
    if e.manual then
      vim.list_extend(out, e.ft)
    end
  end
  table.sort(out)
  return out
end

function M.is_manual(ft)
  local e = by_ft[ft]
  return e ~= nil and e.manual == true
end

function M.runtime_for_ft(ft)
  local e = by_ft[ft]
  return e and e.runtime or nil
end

-- The one line that installs a requirement, as the owner would type it.
function M.command(req)
  if req.command then
    return req.command
  end
  local parts = { "brew install " .. table.concat(req.brew, " ") }
  for _, argv in ipairs(req.after or {}) do
    parts[#parts + 1] = table.concat(argv, " ")
  end
  return table.concat(parts, " && ")
end

-- The commands the editor runs to install a requirement, each once the one
-- before has succeeded, or none when the command can only be shown.
function M.steps(req)
  if not req.brew then
    return {}
  end
  local steps = { vim.list_extend({ "brew", "install" }, req.brew) }
  for _, argv in ipairs(req.after or {}) do
    steps[#steps + 1] = vim.deepcopy(argv)
  end
  return steps
end

-- Each outside program the file type needs, mapped to the command that installs it.
function M.system_for_ft(ft)
  local e = by_ft[ft]
  local out = {}
  for program, req in pairs(e and e.system or {}) do
    out[program] = M.command(req)
  end
  return out
end

-- Every Homebrew formula the editor may offer to install. scripts/on-demand
-- prints this list.
function M.formulae()
  local all = {}
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.runtime and e.runtime.brew or {})
    for _, req in pairs(e.system or {}) do
      vim.list_extend(all, req.brew or {})
    end
  end
  return sorted_unique(all)
end

function M.managed_for_ft(ft)
  local e = by_ft[ft]
  return e and e.managed or nil
end

function M.custom_parsers() return L.parsers end

function M.all_parsers()
  local all = {}
  for _, e in ipairs(entries) do
    vim.list_extend(all, e.ts or {})
  end
  return sorted_unique(all)
end

-- Every Mason package any file type can ask for. Each file type is asked
-- separately, since Harper checks some of an entry's file types and not others.
function M.all_packages(server_to_package)
  local all = {}
  for _, e in ipairs(entries) do
    for _, ft in ipairs(e.ft) do
      vim.list_extend(all, M.packages_for_ft(ft, server_to_package))
    end
  end
  return sorted_unique(all)
end

return M
