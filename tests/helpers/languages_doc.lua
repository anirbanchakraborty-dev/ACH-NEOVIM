-- Builds docs/languages.md from what the full test measured, reads a copy of
-- it back, and says what got worse between the two. Pure functions, so the
-- regular suite tests them without installing anything.
--
-- A result is { name, layers }, where layers maps each layer key to
-- { want, works, needs }: the tools the table names, those that worked, and,
-- for a tool that did not, the install command it is waiting on when the
-- reason is a missing runtime or Homebrew program. A language whose check did
-- not finish is { name, error } instead.
local M = {}

M.layers = {
  { key = "treesitter", title = "Tree-sitter" },
  { key = "server", title = "Server" },
  { key = "formatter", title = "Formatter" },
  { key = "linter", title = "Linter" },
  { key = "grammar", title = "Grammar" },
}

local INTRO = table.concat({
  "Written by `scripts/check --full`, which installs what each language needs, short of anything from Homebrew",
  "or Xcode, and tries each layer on that language's sample in `tests/fixtures/samples.lua`.",
  "A cell names the tools that worked.",
  "`none` means the configuration names no tool for that layer,",
  "`not working` names a tool that was installed and failed its check,",
  "`waiting` names one waiting on a runtime or a Homebrew or Xcode program that is missing on this Mac,",
  "and `check failed` means the language's check did not finish.",
  "Server covers the servers that take the sample's file type, and Grammar is Harper.",
  "A language with no formatter listed may still be formatted by its server, which this table does not measure.",
}, " ")

local WAITING = table.concat({
  "The full run never installs from Homebrew or Xcode, so each command below stays waiting until it is run by hand,",
  "or, for a Homebrew command, until a file of one of its languages is opened in Neovim and the offer to install",
  "it is accepted. A tool waiting on one of them is not a failure.",
}, " ")

-- Each install command the run found missing, with the languages waiting on
-- it, both sorted.
local function waiting(results)
  local by_how = {}
  for _, r in ipairs(results) do
    for _, layer in pairs(r.layers or {}) do
      for _, how in pairs(layer.needs) do
        by_how[how] = by_how[how] or {}
        if not vim.list_contains(by_how[how], r.name) then
          table.insert(by_how[how], r.name)
        end
      end
    end
  end
  local out = {}
  for how, names in pairs(by_how) do
    table.sort(names)
    out[#out + 1] = { how = how, names = names }
  end
  table.sort(out, function(a, b) return a.how < b.how end)
  return out
end

function M.cell(layer, failed)
  if failed then
    return "check failed"
  end
  if not layer or #layer.want == 0 then
    return "none"
  end
  local works, broken, blocked = {}, {}, {}
  for _, tool in ipairs(layer.want) do
    if vim.list_contains(layer.works, tool) then
      works[#works + 1] = tool
    elseif layer.needs[tool] then
      blocked[#blocked + 1] = tool
    else
      broken[#broken + 1] = tool
    end
  end
  local parts = {}
  if #works > 0 then
    parts[#parts + 1] = table.concat(works, ", ")
  end
  if #broken > 0 then
    parts[#parts + 1] = "not working: " .. table.concat(broken, ", ")
  end
  if #blocked > 0 then
    parts[#parts + 1] = "waiting: " .. table.concat(blocked, ", ")
  end
  return table.concat(parts, "; ")
end

function M.render(results, stamp)
  local header, rule = { "Language" }, { "---" }
  for _, l in ipairs(M.layers) do
    header[#header + 1] = l.title
    rule[#rule + 1] = "---"
  end
  local lines = {
    "# Languages",
    "",
    INTRO,
    "",
    stamp,
    "",
    "| " .. table.concat(header, " | ") .. " |",
    "| " .. table.concat(rule, " | ") .. " |",
  }
  local sorted = vim.list_extend({}, results)
  table.sort(sorted, function(a, b) return a.name < b.name end)
  for _, r in ipairs(sorted) do
    local row = { r.name }
    for _, l in ipairs(M.layers) do
      row[#row + 1] = M.cell(r.layers and r.layers[l.key], r.error ~= nil)
    end
    lines[#lines + 1] = "| " .. table.concat(row, " | ") .. " |"
  end
  local blocked = waiting(results)
  if #blocked > 0 then
    vim.list_extend(lines, { "", "## Waiting on an install", "", WAITING, "" })
    for _, w in ipairs(blocked) do
      lines[#lines + 1] = ("- `%s`, for %s"):format(w.how, table.concat(w.names, ", "))
    end
  end
  return table.concat(lines, "\n") .. "\n"
end

-- The tools each language had working, read from a document render wrote.
-- Lines that are not one of its rows are skipped, the list of installs under
-- the table among them, so "" gives {}.
function M.parse(text)
  local out = {}
  for line in vim.gsplit(text, "\n", { plain = true }) do
    -- A row splits into an empty piece either side of its cells.
    local cells = vim.split(line, "|", { plain = true })
    local name = cells[2] and vim.trim(cells[2]) or ""
    if line:sub(1, 2) == "| " and #cells == #M.layers + 3 and name ~= "Language" and name ~= "---" then
      local row = {}
      for i, l in ipairs(M.layers) do
        local works = {}
        for _, part in ipairs(vim.split(vim.trim(cells[i + 2]), "; ", { plain = true })) do
          local listed = part ~= "" and part ~= "none" and part ~= "check failed"
          if listed and not part:find("^not working: ") and not part:find("^waiting: ") then
            vim.list_extend(works, vim.split(part, ", ", { plain = true }))
          end
        end
        row[l.key] = works
      end
      out[name] = row
    end
  end
  return out
end

-- What got worse since before, one message each. A tool counts only while the
-- table still names it, and one that is merely waiting on an install is left
-- to needs(). A check that did not finish always counts.
function M.compare(before, results)
  local out = {}
  for _, r in ipairs(results) do
    if r.error then
      out[#out + 1] = ("%s: the check did not finish: %s"):format(r.name, r.error)
    else
      local was = before[r.name] or {}
      for _, l in ipairs(M.layers) do
        local layer = r.layers[l.key]
        for _, tool in ipairs(was[l.key] or {}) do
          local wanted, works = vim.list_contains(layer.want, tool), vim.list_contains(layer.works, tool)
          if wanted and not works and not layer.needs[tool] then
            out[#out + 1] = ("%s: %s worked before and does not now (%s)"):format(r.name, tool, l.title)
          end
        end
      end
    end
  end
  table.sort(out)
  return out
end

-- Each install command the run found missing, with the languages waiting on
-- it, sorted, for the line scripts/check prints when a person is needed.
function M.needs(results)
  local out = {}
  for _, w in ipairs(waiting(results)) do
    out[#out + 1] = ("%s (for %s)"):format(w.how, table.concat(w.names, ", "))
  end
  return out
end

return M
