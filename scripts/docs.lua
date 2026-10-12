-- Writes the documentation post: one MDX file for the website's
-- /blog/ach-neovim, made from this repository's own source so it cannot drift
-- from the configuration. It never starts the configuration. The plugin specs
-- and lua/ach/servers.lua are read as text through Neovim's own Lua parser,
-- because running them would need the plugins; lua/ach/languages.lua is plain
-- data and is loaded; the keys come from docs/site/keymaps.json, which
-- scripts/check --keymaps records. Run through scripts/docs.
local M = {}

local USAGE = "usage: scripts/docs --out <file> [--date YYYY-MM-DD]\n"
local DATE = "^%d%d%d%d%-%d%d%-%d%d$"
local PLUGINS = "lua/ach/plugins"
local LANGUAGES = "lua/ach/languages.lua"
local SERVERS = "lua/ach/servers.lua"
local KEYMAPS = "docs/site/keymaps.json"
local CARD = "docs/key-card.md"

-- The card's names for keys that are not one character.
local NAMED = {
  Space = "<Space>",
  Tab = "<Tab>",
  Esc = "<Esc>",
  Enter = "<CR>",
  Up = "<Up>",
  Down = "<Down>",
  Left = "<Left>",
  Right = "<Right>",
  Backslash = "\\",
}

-- The card's names for the keys held down with another.
local MODIFIER = { Ctrl = "C", Alt = "A", Shift = "S" }

-- How the post spells the names Neovim writes inside <>, and its modifier
-- letters, for a key the card does not name.
local NAMES = {
  Space = "Space",
  Tab = "Tab",
  Esc = "Esc",
  CR = "Enter",
  BS = "Backspace",
  Del = "Delete",
  Up = "Up",
  Down = "Down",
  Left = "Left",
  Right = "Right",
  lt = "<",
  Bslash = "Backslash",
  Bar = "|",
}
local MODS = { C = "Ctrl", M = "Alt", A = "Alt", S = "Shift", D = "Command" }

local function read(path)
  local f, err = io.open(path, "rb")
  if not f then
    error(err, 0)
  end
  local text = f:read("*a")
  f:close()
  return text
end

local function sorted(map)
  local keys = vim.tbl_keys(map)
  table.sort(keys)
  return keys
end

-- Text --------------------------------------------------------------------

-- text with every character MDX or Markdown would read as markup escaped,
-- except inside code spans: a run of backticks up to the next run of the same
-- length. A run with no partner is plain text. $ is escaped too, because the
-- website runs remark-math, which reads the text between two $ as a formula.
function M.escape(text)
  local out, i = {}, 1
  local function plain(s) return (s:gsub("[\\{}<>*_%[%]%$]", "\\%0")) end
  while i <= #text do
    local s, e = text:find("`+", i)
    if not s then
      out[#out + 1] = plain(text:sub(i))
      break
    end
    out[#out + 1] = plain(text:sub(i, s - 1))
    local close, j = nil, e + 1
    while true do
      local cs, ce = text:find("`+", j)
      if not cs then
        break
      end
      if ce - cs == e - s then
        close = ce
        break
      end
      j = ce + 1
    end
    if close then
      out[#out + 1] = text:sub(s, close)
      i = close + 1
    else
      out[#out + 1] = text:sub(s, e)
      i = e + 1
    end
  end
  return table.concat(out)
end

-- text escaped for a table cell: a | ends a cell even inside a code span, so
-- it is escaped everywhere, and a cell is one line.
function M.cell(text) return (M.escape(text):gsub("|", "\\|"):gsub("\n", " ")) end

local function longest_run(text)
  local longest = 0
  for run in text:gmatch("`+") do
    longest = math.max(longest, #run)
  end
  return longest
end

-- text as a code span, fenced by one more backtick than its longest run.
function M.code(text)
  local fence = ("`"):rep(longest_run(text) + 1)
  local pad = (text:match("^`") or text:match("`$")) and " " or ""
  return fence .. pad .. text .. pad .. fence
end

-- The fence for a code block holding text: at least three backticks, and one
-- more than its longest run.
function M.fence(text) return ("`"):rep(math.max(3, longest_run(text) + 1)) end

-- A <Tabs> component, one { label, Lua source } per tab.
function M.tabs(tabs)
  local out = { "<Tabs>" }
  for _, tab in ipairs(tabs) do
    local fence = M.fence(tab[2])
    vim.list_extend(out, { ('<Tab label="%s">'):format(tab[1]), "", fence .. "lua" })
    vim.list_extend(out, vim.split(tab[2], "\n", { plain = true }))
    vim.list_extend(out, { fence, "", "</Tab>" })
  end
  out[#out + 1] = "</Tabs>"
  return out
end

-- Source --------------------------------------------------------------------

-- A Lua file of the repository, read as text and parsed.
local function parse(root, file)
  local src = read(root .. "/" .. file)
  local tree = vim.treesitter.get_string_parser(src, "lua"):parse()[1]
  return { file = file, src = src, lines = vim.split(src, "\n", { plain = true }), tree = tree:root() }
end

local function children(node)
  local out = {}
  for i = 0, node:named_child_count() - 1 do
    out[#out + 1] = node:named_child(i)
  end
  return out
end

-- A string node's contents, without its quotes or long brackets.
local function unquote(node, src)
  local text = vim.treesitter.get_node_text(node, src)
  return text:match('^"(.*)"$') or text:match("^'(.*)'$") or text:match("^%[%[(.*)%]%]$")
end

-- A field's name, such as opts in opts = {}, or nil for a list entry.
local function name_of(field, src)
  local name = field:field("name")[1]
  if not name then
    return nil
  end
  if name:type() == "string" then
    return unquote(name, src)
  end
  return vim.treesitter.get_node_text(name, src)
end

-- The first child of a table that is not a comment.
local function first_child(tbl)
  for _, child in ipairs(children(tbl)) do
    if child:type() ~= "comment" then
      return child
    end
  end
end

local function field_named(tbl, name, src)
  for _, child in ipairs(children(tbl)) do
    if child:type() == "field" and name_of(child, src) == name then
      return child
    end
  end
end

-- The repository a spec table starts with, or nil.
local function repo_of(tbl, src)
  local first = first_child(tbl)
  if first and first:type() == "field" and not first:field("name")[1] then
    local value = first:field("value")[1]
    if value and value:type() == "string" then
      return unquote(value, src)
    end
  end
end

-- The table a top-level statement such as M.languages = { ... } assigns.
local function assigned(src, root, target)
  for _, node in ipairs(children(root)) do
    if node:type() == "assignment_statement" then
      local vars, values = node:named_child(0), node:named_child(1)
      if vars and values and vim.treesitter.get_node_text(vars, src) == target then
        local value = values:named_child(0)
        if value and value:type() == "table_constructor" then
          return value
        end
      end
    end
  end
end

-- A table's named fields, by name.
local function fields_of(tbl, src)
  local out = {}
  for _, child in ipairs(children(tbl)) do
    local name = child:type() == "field" and name_of(child, src)
    if name then
      out[name] = child
    end
  end
  return out
end

-- The text of node, from the start of its first line to its end. With
-- comments, the comment lines directly above it come too, when node starts
-- its line. The lines lose the indent they share.
function M.snippet(lines, node, comments)
  local sr, sc, er, ec = node:range()
  local own = not lines[sr + 1]:sub(1, sc):match("%S")
  local sib = comments and own and node:prev_named_sibling() or nil
  while sib and sib:type() == "comment" do
    local cr, cc, cer, cec = sib:range()
    if cec == 0 then
      cer = cer - 1
    end
    if cer ~= sr - 1 or lines[cr + 1]:sub(1, cc):match("%S") then
      break
    end
    sr, sc = cr, cc
    sib = sib:prev_named_sibling()
  end
  local out = {}
  for row = sr, er do
    local line = lines[row + 1]
    if row == er then
      line = line:sub(1, ec)
    end
    if row == sr then
      line = line:match("^%s*") .. line:sub(sc + 1)
    end
    out[#out + 1] = line
  end
  local indent
  for _, line in ipairs(out) do
    if line:match("%S") then
      local n = #line:match("^%s*")
      indent = indent and math.min(indent, n) or n
    end
  end
  for i, line in ipairs(out) do
    out[i] = line:match("%S") and line:sub((indent or 0) + 1) or ""
  end
  return table.concat(out, "\n")
end

-- Every plugin in lock that a spec file names, by its name in the lock: its
-- repository, each spec that starts with it, with the text of the spec and of
-- its opts, and each dependencies line that brings it in for another plugin.
function M.specs(root, lock)
  local query = vim.treesitter.query.parse("lua", "(field !name value: (string) @repo)")
  local files = {}
  for name, kind in vim.fs.dir(root .. "/" .. PLUGINS) do
    if kind == "file" and name:match("%.lua$") then
      files[#files + 1] = PLUGINS .. "/" .. name
    end
  end
  table.sort(files)
  local out = {}
  for _, file in ipairs(files) do
    local doc = parse(root, file)
    for _, node in query:iter_captures(doc.tree, doc.src) do
      local repo = unquote(node, doc.src)
      local name = repo and repo:match("^[%w%-_.]+/([%w%-_.]+)$")
      if name and lock[name] then
        local field = node:parent()
        local tbl = field:parent()
        local holder = tbl:parent()
        out[name] = out[name] or { repo = repo, fragments = {}, parents = {} }
        if holder:type() == "field" and name_of(holder, doc.src) == "dependencies" then
          local parent = repo_of(holder:parent(), doc.src)
          if not parent then
            error(("%s: %s is a dependency of a spec that does not start with its repository"):format(file, repo), 0)
          end
          local text = M.snippet(doc.lines, holder, false)
          table.insert(out[name].parents, { file = file, parent = parent, text = text })
        elseif first_child(tbl):id() == field:id() then
          local opts = field_named(tbl, "opts", doc.src)
          table.insert(out[name].fragments, {
            file = file,
            spec = M.snippet(doc.lines, holder:type() == "field" and holder or tbl, true),
            opts = opts and M.snippet(doc.lines, opts, true) or nil,
          })
        end
      end
    end
  end
  return out
end

-- Keys ----------------------------------------------------------------------

-- A key in one canonical spelling, as tests/helpers/keymaps.lua writes it.
local function norm(lhs) return vim.fn.keytrans(vim.keycode(lhs)) end

-- A key as the card writes it, such as "Space f f", "Ctrl-/" or "Alt-Down",
-- in the canonical spelling. The same reading as the key card test's.
local function card_key(key)
  local out = {}
  for _, word in ipairs(vim.split(key, " ", { plain = true })) do
    local modifier, rest = word:match("^(%a+)%-(.+)$")
    if modifier and MODIFIER[modifier] then
      local inner = NAMED[rest] or rest
      out[#out + 1] = ("<%s-%s>"):format(MODIFIER[modifier], inner:match("^<(.+)>$") or inner)
    else
      out[#out + 1] = NAMED[word] or word
    end
  end
  return norm(table.concat(out))
end

-- The cells of one table row, trimmed. A | inside a cell is written \|.
local function cells(line)
  local row = line:gsub("\\|", "\1"):match("^%s*|(.*)|%s*$") or ""
  local out = {}
  for cell in (row .. "|"):gmatch("([^|]*)|") do
    out[#out + 1] = vim.trim((cell:gsub("\1", "|")))
  end
  return out
end

-- A key in the canonical spelling, written for a reader: "<Space>gg" is
-- "Space g g", "<M-j>" is "Alt-j" and "<C-H>" is "Ctrl-h".
function M.spell(lhs)
  local words, i = {}, 1
  while i <= #lhs do
    local group = lhs:match("^<[^<>]+>", i)
    if group then
      local inner, parts = group:sub(2, -2), {}
      while true do
        local mod, rest = inner:match("^(%a)%-(.+)$")
        if not (mod and MODS[mod]) then
          break
        end
        parts[#parts + 1] = MODS[mod]
        inner = rest
      end
      local key = NAMES[inner] or inner
      if #parts == 1 and parts[1] == "Ctrl" and key:match("^%u$") then
        key = key:lower()
      end
      parts[#parts + 1] = key
      words[#words + 1] = table.concat(parts, "-")
      i = i + #group
    else
      local char = lhs:match("^[\1-\127\194-\244][\128-\191]*", i) or lhs:sub(i, i)
      words[#words + 1] = char
      i = i + #char
    end
  end
  return table.concat(words, " ")
end

-- The keys in the card's tables with a Description column, by canonical
-- spelling, each with the card's spelling, its section and its place in the
-- card; and those sections, in the card's order.
function M.card(root)
  local lines = vim.split(read(root .. "/" .. CARD), "\n", { plain = true })
  local card, order, section, current, rank = {}, {}, "", nil, 0
  for i, line in ipairs(lines) do
    if line:match("^## ") then
      section = line:sub(4)
    end
    if line:match("^|%s*%-%-%-") and i > 1 and lines[i - 1]:match("^|") then
      current = cells(lines[i - 1])[2] == "Description" and section or nil
      if current and not vim.tbl_contains(order, current) then
        order[#order + 1] = current
      end
    elseif current and line:match("^|") then
      local key = cells(line)[1]:match("^`([^`]+)`$")
      local lhs = key and card_key(key)
      if lhs and not card[lhs] then
        rank = rank + 1
        card[lhs] = { spelling = key, section = current, rank = rank }
      end
    elseif not line:match("^|") then
      current = nil
    end
  end
  if #order == 0 then
    error(CARD .. " has no table with a Description column", 0)
  end
  return card, order
end

-- The card section a key goes under: the card's own section for it, else the
-- longest start in docs.key_sections that its spelling begins with, word by
-- word, else "Outside the menus".
function M.section(card, lhs, spelling, docs)
  if card[lhs] then
    return card[lhs].section
  end
  local best, length = "Outside the menus", -1
  for _, rule in ipairs(docs.key_sections) do
    local start = rule[1]
    local match = spelling == start or spelling:sub(1, #start + 1) == start .. " "
    if match and #start > length then
      best, length = rule[2], #start
    end
  end
  return best
end

-- Sections ------------------------------------------------------------------

function M.keymaps_section(root, docs)
  local card, order = M.card(root)
  local rows = {}
  for _, name in ipairs(order) do
    rows[name] = {}
  end
  for i, k in ipairs(vim.json.decode(read(root .. "/" .. KEYMAPS))) do
    local lhs, modes, desc = k[1], k[2], k[3]
    local spelling = card[lhs] and card[lhs].spelling or M.spell(lhs)
    local section = M.section(card, lhs, spelling, docs)
    if not rows[section] then
      error(("%s: %s goes under %s, which %s has no table for"):format(KEYMAPS, spelling, section, CARD), 0)
    end
    local letters = {}
    for letter in modes:gmatch(".") do
      letters[#letters + 1] = letter
    end
    table.insert(rows[section], {
      rank = card[lhs] and card[lhs].rank or math.huge,
      index = i,
      line = ("| %s | %s | %s |"):format(M.cell(M.code(spelling)), M.cell(desc), table.concat(letters, ", ")),
    })
  end
  local out = vim.deepcopy(docs.intro.keymaps)
  for _, name in ipairs(order) do
    local list = rows[name]
    table.sort(list, function(a, b)
      if a.rank ~= b.rank then
        return a.rank < b.rank
      end
      return a.index < b.index
    end)
    if #list > 0 then
      vim.list_extend(out, { "", "### " .. M.escape(name), "", "| Key | Description | Mode |", "| --- | --- | --- |" })
      for _, row in ipairs(list) do
        out[#out + 1] = row.line
      end
    end
  end
  return out
end

function M.plugins_section(root, docs)
  local lock = vim.json.decode(read(root .. "/lazy-lock.json"))
  local specs = M.specs(root, lock)
  local known, problems = {}, {}
  for _, category in ipairs(docs.categories) do
    known[category] = true
  end
  for _, name in ipairs(sorted(lock)) do
    local entry, spec = docs.plugins[name], specs[name]
    if not entry then
      problems[#problems + 1] = name .. " is in lazy-lock.json but has no entry in lua/ach/docs.lua"
    elseif not known[entry.category] then
      problems[#problems + 1] = ("%s has the category %s, which M.categories does not list"):format(
        name,
        tostring(entry.category)
      )
    end
    if not spec or (#spec.fragments == 0 and #spec.parents == 0) then
      problems[#problems + 1] = name .. " is in lazy-lock.json but no spec in " .. PLUGINS .. " names it"
    end
  end
  for _, name in ipairs(sorted(docs.plugins)) do
    if not lock[name] then
      problems[#problems + 1] = name .. " has an entry in lua/ach/docs.lua but is not in lazy-lock.json"
    end
  end
  if #problems > 0 then
    error(table.concat(problems, "\n"), 0)
  end

  local out = vim.deepcopy(docs.intro.plugins)
  for _, category in ipairs(docs.categories) do
    local names = {}
    for _, name in ipairs(sorted(lock)) do
      if docs.plugins[name].category == category then
        names[#names + 1] = name
      end
    end
    table.sort(names, function(a, b)
      if a:lower() ~= b:lower() then
        return a:lower() < b:lower()
      end
      return a < b
    end)
    if #names > 0 then
      vim.list_extend(out, { "", "### " .. M.escape(category) })
    end
    for _, name in ipairs(names) do
      local spec = specs[name]
      local heading = ("#### [%s](https://github.com/%s)"):format(M.escape(name), spec.repo)
      vim.list_extend(out, { "", heading, "", M.escape(docs.plugins[name].desc) })
      for _, fragment in ipairs(spec.fragments) do
        local tabs = {}
        if fragment.opts then
          tabs[#tabs + 1] = { "Options", fragment.opts }
        end
        tabs[#tabs + 1] = { "Full Spec", fragment.spec }
        vim.list_extend(out, { "", ("From `%s`:"):format(fragment.file), "" })
        vim.list_extend(out, M.tabs(tabs))
      end
      if #spec.fragments == 0 then
        for _, mention in ipairs(spec.parents) do
          local line = ("lazy.nvim installs it as a dependency of `%s`, in `%s`:"):format(
            mention.parent:match("[^/]+$"),
            mention.file
          )
          vim.list_extend(out, { "", line, "" })
          vim.list_extend(out, M.tabs({ { "Full Spec", mention.text } }))
        end
      end
    end
  end
  return out
end

-- Names as code spans, joined by commas.
local function codes(list)
  local out = {}
  for _, item in ipairs(list or {}) do
    out[#out + 1] = M.code(item)
  end
  return table.concat(out, ", ")
end

-- A fmt or lint field: a list for every file type, or a map from file type to
-- list, which is written per file type.
local function tools(value)
  if value == nil or vim.islist(value) then
    return codes(value)
  end
  local parts = {}
  for _, ft in ipairs(sorted(value)) do
    parts[#parts + 1] = ("%s for %s"):format(codes(value[ft]), M.code(ft))
  end
  return table.concat(parts, "; ")
end

function M.languages_section(root, docs)
  local data = dofile(root .. "/" .. LANGUAGES).languages
  local langs, servers = parse(root, LANGUAGES), parse(root, SERVERS)
  local entries_node = assigned(langs.src, langs.tree, "M.languages")
  local settings_node = assigned(servers.src, servers.tree, "M.settings")
  if not entries_node or not settings_node then
    error(("M.languages must be a table written out in %s, and M.settings one in %s"):format(LANGUAGES, SERVERS), 0)
  end
  local entries, settings = fields_of(entries_node, langs.src), fields_of(settings_node, servers.src)
  local problems = {}
  for _, name in ipairs(sorted(docs.debuggers)) do
    if not data[name] then
      problems[#problems + 1] = name .. " has a debugger in lua/ach/docs.lua but no entry in " .. LANGUAGES
    end
  end
  for _, name in ipairs(sorted(data)) do
    if not entries[name] then
      problems[#problems + 1] = name .. " is not written out inside M.languages, so its entry cannot be shown"
    end
  end
  if #problems > 0 then
    error(table.concat(problems, "\n"), 0)
  end

  local out = vim.deepcopy(docs.intro.languages)
  for _, name in ipairs(sorted(data)) do
    local e = data[name]
    local started = codes(e.lsp)
    if e.managed then
      started = (started ~= "" and started .. "; " or "") .. "started by " .. M.code(e.managed)
    end
    local formatters = tools(e.fmt)
    if e.manual and formatters ~= "" then
      formatters = formatters .. "; never on save, only on `Space c f`"
    end
    local grammar = ""
    if e.harper == true then
      grammar = "Harper"
    elseif type(e.harper) == "table" then
      grammar = "Harper, in " .. codes(e.harper)
    end
    local rows = {
      { "File types", codes(e.ft) },
      { "Parsers", codes(e.ts) },
      { "Servers", started },
      { "Formatters", formatters },
      { "Linters", tools(e.lint) },
      { "Debugger", docs.debuggers[name] or "" },
      { "Grammar", grammar },
    }
    vim.list_extend(out, { "", "### " .. M.escape(name), "", "| Part | Names |", "| --- | --- |" })
    for _, row in ipairs(rows) do
      out[#out + 1] = ("| %s | %s |"):format(row[1], M.cell(row[2] ~= "" and row[2] or "none"))
    end
    local tabs = { { "Entry", M.snippet(langs.lines, entries[name], false) } }
    local options = {}
    for _, server in ipairs(e.lsp or {}) do
      if settings[server] then
        options[#options + 1] = M.snippet(servers.lines, settings[server], true)
      end
    end
    if #options > 0 then
      tabs[2] = { "Options", table.concat(options, "\n\n") }
    end
    out[#out + 1] = ""
    vim.list_extend(out, M.tabs(tabs))
  end
  return out
end

-- The post -----------------------------------------------------------------

local function quote(text) return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"' end

function M.front_matter(post, date)
  local tags = {}
  for _, tag in ipairs(post.tags) do
    tags[#tags + 1] = quote(tag)
  end
  return {
    "---",
    "title: " .. quote(post.title),
    "date: " .. quote(date),
    "summary: " .. quote(post.summary),
    "tags: [" .. table.concat(tags, ", ") .. "]",
    "draft: false",
    "---",
  }
end

-- One of the hand-written pages in docs/site/, without trailing blank lines.
-- The post gives each page its ## heading, so a page's own headings start at
-- ###.
local function page(root, name)
  local file = "docs/site/" .. name
  local lines = vim.split((read(root .. "/" .. file):gsub("%s+$", "")), "\n", { plain = true })
  local fence
  for i, line in ipairs(lines) do
    local run = line:match("^%s*(`+)")
    if fence then
      if run and #run >= #fence and line:match("^%s*`+%s*$") then
        fence = nil
      end
    elseif run and #run >= 3 then
      fence = run
    elseif line:match("^##?%s") then
      error(("%s:%d: a # or ## heading; the pages start their headings at ###"):format(file, i), 0)
    end
  end
  return lines
end

function M.render(root, date)
  local docs = require("ach.docs")
  local out = M.front_matter(docs.post, date)
  vim.list_extend(out, { "", '<Callout type="note">', "" })
  vim.list_extend(out, docs.intro.note)
  vim.list_extend(out, { "", "</Callout>" })
  local function add(title, lines)
    vim.list_extend(out, { "", "## " .. title, "" })
    vim.list_extend(out, lines)
  end
  add("Getting Started", page(root, "getting-started.md"))
  add("Installation", page(root, "installation.md"))
  add("What's New", page(root, "news.md"))
  add("Keymaps", M.keymaps_section(root, docs))
  add("Configuration", page(root, "configuration.md"))
  add("Plugins", M.plugins_section(root, docs))
  add("Languages", M.languages_section(root, docs))
  return table.concat(out, "\n") .. "\n"
end

function M.main(args)
  local root = vim.fn.getcwd()
  package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
  local out, date
  local i = 1
  while i <= #args do
    if args[i] == "--out" and args[i + 1] then
      out = args[i + 1]
    elseif args[i] == "--date" and args[i + 1] then
      date = args[i + 1]
    else
      io.stderr:write(USAGE)
      return 1
    end
    i = i + 2
  end
  if not out then
    io.stderr:write(USAGE)
    return 1
  end
  if date and not date:match(DATE) then
    io.stderr:write(("--date takes YYYY-MM-DD, such as 2026-10-11, not %s\n"):format(date))
    return 1
  end
  if not date then
    local r = vim.system({ "git", "log", "-1", "--format=%cs" }, { cwd = root, text = true }):wait()
    date = vim.trim(r.stdout or "")
    if r.code ~= 0 or not date:match(DATE) then
      io.stderr:write("could not read the date of HEAD; pass --date YYYY-MM-DD\n")
      return 1
    end
  end
  if out:sub(1, 1) ~= "/" then
    out = root .. "/" .. out
  end
  if vim.fn.isdirectory(vim.fs.dirname(out)) == 0 then
    io.stderr:write(("the folder for --out does not exist: %s\n"):format(vim.fs.dirname(out)))
    return 1
  end
  local ok, text = pcall(M.render, root, date)
  if not ok then
    io.stderr:write("scripts/docs: " .. tostring(text) .. "\n")
    return 1
  end
  local f = assert(io.open(out, "wb"))
  f:write(text)
  f:close()
  local _, count = text:gsub("\n", "")
  io.stdout:write(("Wrote %s: %d lines.\n"):format(out, count))
  return 0
end

if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "docs.lua" then
  os.exit(M.main(vim.list_slice(_G.arg, 1, #_G.arg)))
end

return M
