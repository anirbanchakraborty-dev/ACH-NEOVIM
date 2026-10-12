-- Adapted from x86-lookup.el by Christopher Wellons, released into the public
-- domain, https://github.com/skeeto/x86-lookup.
-- Space c x: finds an instruction's page in Intel's Software Developer's
-- Manual and opens Skim there. pdftotext reads the manual once, and the pages
-- found are kept as JSON in Neovim's cache folder, under a name made from the
-- manual's size and date, so a newer manual is read again.
local M = {}

-- Where the manual is kept. It is Intel's, fetched by hand from M.source.
M.pdf = vim.fs.joinpath(vim.env.HOME, ".local", "state", "x86-lookup", "intel-sdm.pdf")
M.source = "https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html"
M.cache = vim.fs.joinpath(vim.fn.stdpath("cache") --[[@as string]], "x86-lookup")

-- The condition codes Intel writes as cc, so Jcc stands for JA, JAE, JB and
-- the rest.
local cc = {
  "a",
  "ae",
  "b",
  "be",
  "c",
  "e",
  "g",
  "ge",
  "l",
  "le",
  "na",
  "nae",
  "nb",
  "nbe",
  "nc",
  "ne",
  "ng",
  "nge",
  "nl",
  "nle",
  "no",
  "np",
  "ns",
  "nz",
  "o",
  "p",
  "pe",
  "po",
  "s",
  "z",
}

-- Headings that stand for a family: the part each member keeps, and the
-- endings that make the members. Matched exactly, capitals included, as the
-- manual writes them.
local families = {
  PREFETCHh = { "PREFETCH", { "", "nta", "t0", "t1", "t2" } },
  Jcc = { "J", vim.list_extend({ "cxz", "ecxz", "rcxz" }, cc) },
  SETcc = { "SET", cc },
  CMOVcc = { "CMOV", cc },
  FCMOVcc = { "FCMOV", { "b", "e", "be", "u", "nb", "ne", "nbe", "nu" } },
  LOOPcc = { "LOOP", { "e", "ne" } },
  VBROADCAST = { "VBROADCAST", { "", "ss", "sd", "f128" } },
  VMASKMOV = { "VMASKMOV", { "", "ps", "pd" } },
  VPBROADCAST = { "VPBROADCAST", { "", "b", "w", "d", "q", "I128" } },
  VPMASKMOV = { "VPMASKMOV", { "", "d", "q" } },
}

-- The names a heading line gives, such as "INT n/INTO/INT3/INT1" from
-- "INT n/INTO/INT3/INT1—Call to Interrupt Procedure", or nil. The dash is an
-- em dash or, as x86-lookup also accepts, two hyphens.
---@param line string
---@return string?
local function heading(line) return line:match("^%s*([%w/ \t]+)—") or line:match("^%s*([%w/ \t]+)%-%-") end

-- Every lowercase instruction a heading's names stand for. "INT n" is int,
-- and a family is each of its members.
---@param raw string
---@return string[]
local function names(raw)
  local out = {}
  for part in vim.gsplit(raw, "/", { plain = true }) do
    local name = vim.trim(part):match("^%S+")
    local family = name and families[name]
    if family then
      for _, tail in ipairs(family[2]) do
        out[#out + 1] = (family[1] .. tail):lower()
      end
    elseif name then
      out[#out + 1] = name:lower()
    end
  end
  return out
end

-- The first five lines of a page that are not blank.
---@param page string
---@return string[]
local function opening(page)
  local lines = {}
  for line in vim.gsplit(page, "\n", { plain = true }) do
    if line:find("%S") then
      lines[#lines + 1] = line
      if #lines == 5 then
        break
      end
    end
  end
  return lines
end

-- The heading's names when the page is an instruction's: one of its first two
-- lines is a heading, and one of the three lines after that starts with the
-- word Opcode, which heads the table every instruction's pages open with.
---@param lines string[]
---@return string?
local function instruction(lines)
  for h = 1, 2 do
    local raw = lines[h] and heading(lines[h])
    if raw then
      for o = h + 1, h + 3 do
        if lines[o] and lines[o]:lower():find("^%s*opcode") then
          return raw
        end
      end
    end
  end
end

-- Reads pdftotext's text of the manual, where a form feed ends every page,
-- and returns the first page of each instruction, as { add = 123, ... }.
---@param text string
---@return table<string, integer>
function M.parse(text)
  local index, page = {}, 0
  for body in (text .. "\f"):gmatch("([^\f]*)\f") do
    page = page + 1
    local raw = instruction(opening(body))
    if raw then
      for _, name in ipairs(names(raw)) do
        if index[name] == nil then
          index[name] = page
        end
      end
    end
  end
  return index
end

-- Where the index of the manual at pdf is kept, or nil when there is no file
-- at pdf.
---@param pdf string
---@return string?
local function cache_file(pdf)
  local stat = vim.uv.fs_stat(pdf)
  if not stat then
    return nil
  end
  local key = ("%s:%d:%d"):format(pdf, stat.size, stat.mtime.sec)
  return vim.fs.joinpath(M.cache, vim.fn.sha256(key):sub(1, 16) .. ".json")
end

-- Hands done the index of the manual at pdf: from the cache when it is there,
-- and otherwise from pdftotext, which runs in the background, after which the
-- index is saved. Hands done nil when the manual cannot be read.
---@param pdf string
---@param done fun(index: table<string, integer>?)
function M.index(pdf, done)
  local file = cache_file(pdf)
  if not file then
    return done(nil)
  end
  local ok, cached = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(file), "\n")) end)
  if ok and type(cached) == "table" then
    return done(cached)
  end
  vim.notify("Reading Intel's manual to index it. This happens once.", vim.log.levels.INFO)
  vim.system(
    { "pdftotext", "-q", "-enc", "UTF-8", pdf, "-" },
    { text = true },
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        vim.notify(("pdftotext could not read %s: %s"):format(pdf, vim.trim(r.stderr or "")), vim.log.levels.ERROR)
        return done(nil)
      end
      local index = M.parse(r.stdout or "")
      vim.fn.mkdir(M.cache, "p")
      vim.fn.writefile({ vim.json.encode(index) }, file)
      done(index)
    end)
  )
end

-- Asks Skim to open a PDF at a page. The file and the page arrive as the
-- script's arguments, so no file name is ever pasted into the script's text.
-- A document Skim already has open is found by its path and reused.
M.script = {
  "on run argv",
  "set theFile to POSIX file (item 1 of argv)",
  "set thePath to POSIX path of (theFile as alias)",
  'tell application "Skim"',
  "open theFile",
  "set theDocs to get documents whose path is thePath",
  "if (count of theDocs) = 0 then set theDocs to {document 1}",
  "set theDoc to contents of item 1 of theDocs",
  "go theDoc to page ((item 2 of argv) as integer) of theDoc",
  "activate",
  "end tell",
  "end run",
}

-- Opens the PDF at pdf in Skim at page.
---@param pdf string
---@param page integer
function M.open(pdf, page)
  local argv = { "osascript" }
  for _, line in ipairs(M.script) do
    vim.list_extend(argv, { "-e", line })
  end
  vim.list_extend(argv, { pdf, tostring(page) })
  vim.system(
    argv,
    { text = true },
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        vim.notify(
          ("Skim could not open %s at page %d: %s"):format(pdf, page, vim.trim(r.stderr or "")),
          vim.log.levels.ERROR
        )
      end
    end)
  )
end

-- Space c x. Both programs are checked before either stops the key, so a new
-- Mac learns about both at once.
function M.lookup()
  local need = require("ach.need")
  local reader = need.have("pdftotext")
  local viewer = need.have("displayline")
  if not (reader and viewer) then
    return
  end
  if vim.fn.filereadable(M.pdf) ~= 1 then
    vim.notify(
      ("Intel's manual is not at %s. Download the combined volumes from %s and save the PDF there."):format(
        M.pdf,
        M.source
      ),
      vim.log.levels.WARN
    )
    return
  end
  local word = vim.fn.expand("<cword>"):lower()
  M.index(M.pdf, function(index)
    if not index then
      return
    end
    if index[word] then
      return M.open(M.pdf, index[word])
    end
    local all = vim.tbl_keys(index)
    if #all == 0 then
      vim.notify(
        ("%s has no instruction pages. It should be the combined volumes from %s."):format(M.pdf, M.source),
        vim.log.levels.WARN
      )
      return
    end
    table.sort(all)
    vim.ui.select(all, { prompt = "x86 instruction" }, function(choice)
      if choice then
        M.open(M.pdf, index[choice])
      end
    end)
  end)
end

return M
