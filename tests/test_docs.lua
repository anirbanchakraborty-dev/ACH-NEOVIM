-- scripts/docs, the generator of the documentation post. The first eight
-- tests read the post it writes for this repository. The last seven run it on
-- a fixture, a small repository built in a temporary folder, where the exact
-- MDX for every input is known.

local SECTIONS = { "Getting Started", "Installation", "What's New", "Keymaps", "Configuration", "Plugins", "Languages" }

-- The only lines outside code that may hold a < or a >: the two components'
-- tags, each on a line of its own.
local TAGS = {
  "^<Tabs>$",
  "^</Tabs>$",
  '^<Tab label="[^"]*">$',
  "^</Tab>$",
  '^<Callout type="note">$',
  '^<Callout type="tip">$',
  '^<Callout type="warning">$',
  "^</Callout>$",
  '^<RepoLink url="https://[^"]*" name="[^"]*" license="[^"]*" licenseUrl="https://[^"]*" />$',
  '^<Figure src="/figures/ach%-neovim/[%w%-]+%.webp" alt="[^"]*" caption="[^"]*" id="fig:[%w%-]+" width="%d+" height="%d+" />$',
}

-- Words the post must never contain. They are stored in ROT13, which shifts
-- each letter thirteen places along the alphabet, so this file never spells
-- them out.
local BANNED = {
  "rznpf",
  "zntvg",
  "rysrrq",
  "qbbz",
  "iregvpb",
  "pbesh",
  "bet-ebnz",
  "dhvpx pneq",
  "nhpgrk",
  "rtybg",
  "qverq",
  "wvak",
  "ryvfc",
  "ivfhny-yvar",
}

local DATE = "2026-10-11"

-- The fixture's lock, its keys, and every other file it holds.
local LOCK = {
  ["alpha.nvim"] = { branch = "main", commit = ("1"):rep(40) },
  ["beta.nvim"] = { branch = "main", commit = ("2"):rep(40) },
  ["gamma.nvim"] = { branch = "main", commit = ("3"):rep(40) },
}

local KEYS = {
  { "<M-j>", "n", "Move Down" },
  { "<Space>x", "nx", "Opens {x} <y> | z" },
}

local FILES = {
  ["lua/ach/plugins/fixture.lua"] = [[
return {
  {
    "someone/alpha.nvim",
    dependencies = { "someone/gamma.nvim" },
    -- Three is enough.
    opts = { size = 3 },
  },
  { "someone/beta.nvim", event = "VeryLazy" },
}
]],
  ["lua/ach/docs.lua"] = [=[
local M = {}
M.post = { title = "Fixture", summary = "A post about a fixture.", tags = { "demo" } }
M.intro = {
  note = { "Written by scripts/docs." },
  keymaps = { "Every key." },
  plugins = { "Every plugin." },
  languages = { "Every language." },
}
M.categories = { "Util" }
M.plugins = {
  ["alpha.nvim"] = { category = "Util", desc = "Turns {a} into <b> | c." },
  ["beta.nvim"] = { category = "Util", desc = "Reads $HOME and $PATH, never `$SHELL`." },
  ["gamma.nvim"] = { category = "Util", desc = "Comes with alpha." },
}
M.debuggers = { demo = "demo-dap" }
M.key_sections = {}
return M
]=],
  ["lua/ach/languages.lua"] = [[
local M = {}

M.languages = {
  -- Demo ---------------------------------------------------------------------
  demo = { ft = { "demo" }, ts = { "demo" }, lsp = { "demo_ls" }, fmt = { demo = { "demofmt" } }, harper = true },
}

return M
]],
  ["lua/ach/servers.lua"] = [[
local M = {}

M.settings = {
  -- The demo server's one setting.
  demo_ls = { settings = { level = 1 } },
}

return M
]],
  ["docs/site/getting-started.md"] = "Start here.\n",
  ["docs/site/installation.md"] = "Install it.\n",
  ["docs/site/news.md"] = "Nothing yet.\n",
  ["docs/site/configuration.md"] = "### Layout\n\nOne folder.\n",
  ["docs/key-card.md"] = [[
# Card

## Files and buffers

| Key | Description | What it does |
| --- | --- | --- |
| `Space x` | Opens {x} <y> \| z | Opens x. |

## Outside the menus

| Key | Description | What it does |
| --- | --- | --- |
| `Esc` | Clear | Clears the search. |
]],
}

local function rot13(text)
  return (
    text:gsub("%a", function(c)
      local base = c:match("%l") and 97 or 65
      return string.char((c:byte() - base + 13) % 26 + base)
    end)
  )
end

local function slurp(path)
  local f = assert(io.open(path, "rb"))
  local text = f:read("*a")
  f:close()
  return text
end

local function write(path, text)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local f = assert(io.open(path, "wb"))
  f:write(text)
  f:close()
end

-- The first line from from on that is exactly wanted, or nil.
local function find(lines, wanted, from)
  for i = from or 1, #lines do
    if lines[i] == wanted then
      return i
    end
  end
end

-- Runs scripts/docs in dir with args, and returns vim.system's result.
local function docs(dir, args)
  local cmd = { dir .. "/scripts/docs" }
  vim.list_extend(cmd, args)
  return vim.system(cmd, { cwd = dir, text = true }):wait(60000)
end

-- Writes the post for dir into a temporary file and returns its text.
local function generate(t, dir, args)
  local out = t.tmpdir() .. "/post.mdx"
  local r = docs(dir, vim.list_extend({ "--out", out }, args or {}))
  t.eq(r.code, 0, "scripts/docs exits 0; it printed: " .. (r.stderr or ""))
  return slurp(out)
end

local function lines_of(text) return vim.split(text, "\n", { plain = true }) end

-- The width and height an extended WebP file gives in its header. Bytes 25 to
-- 27 hold the width less one and bytes 28 to 30 the height less one, each
-- read with its lowest byte first.
local function webp_size(path)
  local b = slurp(path)
  assert(b:sub(1, 4) == "RIFF" and b:sub(9, 16) == "WEBPVP8X", path .. " is not an extended WebP file")
  local function u24(i) return b:byte(i) + b:byte(i + 1) * 256 + b:byte(i + 2) * 65536 end
  return u24(25) + 1, u24(28) + 1
end

-- The post for this repository, written once and kept for every test.
local real
local function post(t)
  real = real or lines_of(generate(t, t.root, { "--date", DATE }))
  return real
end

-- The post's lines outside the front matter and the fenced code blocks, each
-- { line number, text }, with every code span taken out of the text.
local function prose(lines)
  local out, fence, front = {}, nil, 0
  for i, line in ipairs(lines) do
    local run = line:match("^%s*(`+)")
    if front < 2 then
      if line == "---" then
        front = front + 1
      end
    elseif fence then
      if run and #run >= #fence and line:match("^%s*`+%s*$") then
        fence = nil
      end
    elseif run and #run >= 3 then
      fence = run
    else
      out[#out + 1] = { i, (line:gsub("(`+)(.-)%1", "")) }
    end
  end
  return out
end

-- A ### heading's name, without the " (Section)" a repeated name is given.
local function unqualified(h3, section)
  local suffix = " (" .. section .. ")"
  return h3:sub(-#suffix) == suffix and h3:sub(1, -#suffix - 1) or h3
end

-- The ### headings inside one ## section of the post, in order.
local function headings(lines, section)
  local out, inside = {}, false
  for _, p in ipairs(prose(lines)) do
    local h2 = p[2]:match("^## (.+)$")
    if h2 then
      inside = h2 == section
    end
    local h3 = inside and p[2]:match("^### (.+)$")
    if h3 then
      out[#out + 1] = (unqualified(h3, section):gsub("\\(.)", "%1"))
    end
  end
  return out
end

-- The id the website gives a heading: its visible text, lower case, with each
-- run of other characters made one hyphen. The same rule as slugify() in the
-- website's src/lib/utils.ts.
local function id(heading)
  local text = heading:gsub("%[(.-)%]%b()", "%1"):gsub("`", ""):gsub("\\(.)", "%1")
  return (text:lower():gsub("[^a-z0-9]+", "-"):gsub("^%-", ""):gsub("%-$", ""))
end

-- A repository in a temporary folder with this repository's scripts/docs and
-- the files above, committed once on 4 March 2026. files, when given, replaces
-- some of them.
local function fixture(t, lock, files)
  local dir = t.tmpdir() .. "/repo"
  for path, text in pairs(vim.tbl_extend("force", FILES, files or {})) do
    write(dir .. "/" .. path, text)
  end
  write(dir .. "/lazy-lock.json", vim.json.encode(lock or LOCK) .. "\n")
  write(dir .. "/docs/site/keymaps.json", vim.json.encode(KEYS) .. "\n")
  for _, path in ipairs({ "scripts/docs", "scripts/docs.lua" }) do
    write(dir .. "/" .. path, slurp(t.root .. "/" .. path))
  end
  vim.fn.setfperm(dir .. "/scripts/docs", "rwxr-xr-x")
  local env = { GIT_AUTHOR_DATE = "2026-03-04T12:00:00", GIT_COMMITTER_DATE = "2026-03-04T12:00:00" }
  for _, args in ipairs({ { "init", "-q" }, { "add", "." }, { "commit", "-q", "-m", "fixture" } }) do
    local cmd = { "git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false" }
    vim.list_extend(cmd, { "-c", "core.hooksPath=/dev/null", "-c", "init.defaultBranch=main" })
    vim.list_extend(cmd, args)
    local r = vim.system(cmd, { cwd = dir, env = env, text = true }):wait(30000)
    t.eq(r.code, 0, "git " .. args[1] .. " in the fixture; it printed: " .. (r.stderr or ""))
  end
  return dir
end

return {
  ["the post has the seven sections, in order"] = function(t)
    local found = {}
    for _, p in ipairs(prose(post(t))) do
      local h2 = p[2]:match("^## (.+)$")
      if h2 then
        found[#found + 1] = h2
      end
    end
    t.eq(found, SECTIONS, "the ## headings of the post")
  end,

  ["every plugin in the lock has an entry, and the post lists it under a category"] = function(t)
    local lock = vim.json.decode(slurp(t.root .. "/lazy-lock.json"))
    local docs_data = require("ach.docs")
    local missing, extra = {}, {}
    for name in pairs(lock) do
      if not docs_data.plugins[name] then
        missing[#missing + 1] = name
      end
    end
    for name in pairs(docs_data.plugins) do
      if not lock[name] then
        extra[#extra + 1] = name
      end
    end
    table.sort(missing)
    table.sort(extra)
    t.eq(missing, {}, "plugins in lazy-lock.json with no entry in lua/ach/docs.lua")
    t.eq(extra, {}, "entries in lua/ach/docs.lua for plugins not in lazy-lock.json")
    local known = {}
    for _, category in ipairs(docs_data.categories) do
      known[category] = true
    end
    local listed, inside, under = {}, false, nil
    for _, p in ipairs(prose(post(t))) do
      local h2 = p[2]:match("^## (.+)$")
      if h2 then
        inside = h2 == "Plugins"
      end
      local h3 = inside and p[2]:match("^### (.+)$")
      under = h3 and unqualified(h3, "Plugins") or under
      local name = inside and p[2]:match("^#### (.+)$")
      if name then
        name = name:gsub("\\(.)", "%1")
        t.ok(known[under], name .. " sits under a known category, not " .. tostring(under))
        listed[#listed + 1] = name
      end
    end
    local names = vim.tbl_keys(lock)
    table.sort(names)
    table.sort(listed)
    t.eq(listed, names, "the plugins the post lists, against lazy-lock.json")
  end,

  ["every language in lua/ach/languages.lua has a subsection"] = function(t)
    local names = vim.tbl_keys(require("ach.languages").languages)
    table.sort(names)
    t.eq(headings(post(t), "Languages"), names, "the ### headings under Languages")
  end,

  ["every debugger belongs to a language, and every language nvim-dap debugs has one"] = function(t)
    local debuggers = require("ach.docs").debuggers
    local languages = require("ach.languages").languages
    local dap = require("ach.dap")
    local owner = {}
    for name, entry in pairs(languages) do
      for _, ft in ipairs(entry.ft) do
        owner[ft] = name
      end
    end
    local unknown, missing = {}, {}
    for name in pairs(debuggers) do
      if not languages[name] then
        unknown[#unknown + 1] = name
      end
    end
    for _, ft in ipairs(vim.list_extend(vim.list_extend({}, dap.lldb_filetypes), dap.js_filetypes)) do
      if not (owner[ft] and debuggers[owner[ft]]) then
        missing[#missing + 1] = ft
      end
    end
    table.sort(unknown)
    table.sort(missing)
    t.eq(unknown, {}, "debuggers in lua/ach/docs.lua for languages lua/ach/languages.lua does not have")
    t.eq(missing, {}, "file types nvim-dap debugs whose language names no debugger in lua/ach/docs.lua")
  end,

  ["docs/site/keymaps.json holds the keys the configuration sets"] = function(t)
    local K = dofile(t.root .. "/tests/helpers/keymaps.lua")
    local ok, recorded = pcall(K.read, t.root)
    t.ok(ok, "docs/site/keymaps.json can be read; run scripts/check --keymaps and commit it")
    t.eq(recorded, K.snapshot(t), "docs/site/keymaps.json against the keys set now; run scripts/check --keymaps")
  end,

  ["outside code, every < > { } $ is escaped or part of a component's tag"] = function(t)
    local bad = {}
    for _, p in ipairs(prose(post(t))) do
      local tag = false
      for _, pattern in ipairs(TAGS) do
        tag = tag or p[2]:match(pattern) ~= nil
      end
      if not tag and p[2]:gsub("\\.", ""):find("[<>{}%$]") then
        bad[#bad + 1] = p[1] .. ": " .. p[2]
      end
    end
    t.eq(bad, {}, "lines of the post with a bare <, >, {, } or $ outside code")
  end,

  ["the post never contains the words kept out of it"] = function(t)
    local text = table.concat(post(t), "\n"):lower()
    local found = {}
    for _, word in ipairs(BANNED) do
      if text:find(rot13(word), 1, true) then
        found[#found + 1] = word
      end
    end
    t.eq(found, {}, "words from the list, in ROT13, that the post contains")
  end,

  ["no two headings in the post share an id"] = function(t)
    local seen, shared = {}, {}
    for _, p in ipairs(prose(post(t))) do
      local heading = p[2]:match("^##+ (.+)$")
      if heading then
        local key = id(heading)
        if seen[key] then
          shared[#shared + 1] = ("%d and %d: %s"):format(seen[key], p[1], key)
        end
        seen[key] = seen[key] or p[1]
      end
    end
    t.eq(shared, {}, "lines whose headings the website would give the same id")
  end,

  ["outside code, the post's sentences carry no semicolon"] = function(t)
    local bad = {}
    for _, p in ipairs(prose(post(t))) do
      if p[2]:find(";", 1, true) then
        bad[#bad + 1] = p[1] .. ": " .. p[2]
      end
    end
    t.eq(bad, {}, "lines of the post with a semicolon outside code")
  end,

  ["no heading in the post holds a link, since the website makes each heading one"] = function(t)
    local linked = {}
    for _, p in ipairs(prose(post(t))) do
      if p[2]:match("^##+ ") and p[2]:find("](", 1, true) then
        linked[#linked + 1] = p[1] .. ": " .. p[2]
      end
    end
    t.eq(linked, {}, "headings with a link inside, which a browser splits out of the heading's own link")
  end,

  ["a heading that repeats an earlier one's id is named for its section"] = function(t)
    local docs_file = FILES["lua/ach/docs.lua"]:gsub('"Util"', '"Demo"')
    local lines = lines_of(generate(t, fixture(t, nil, { ["lua/ach/docs.lua"] = docs_file })))
    local plugins = find(lines, "## Plugins")
    local languages = find(lines, "## Languages")
    t.ok(plugins and languages, "both sections are in the post")
    t.ok(find(lines, "### Demo", plugins) ~= nil, "the category keeps its name, being first")
    local demo = find(lines, "### demo (Languages)", languages)
    t.ok(demo ~= nil, "the language that repeats it is named for its section")
    t.ok(find(lines, "### demo", languages) == nil, "and is not left with the bare name")
  end,

  ["the front matter has the five keys every post uses"] = function(t)
    local lines = post(t)
    t.eq(lines[1], "---", "the post opens with front matter")
    local keys, i = {}, 2
    while lines[i] and lines[i] ~= "---" do
      keys[#keys + 1] = lines[i]:match("^(%w+):") or lines[i]
      i = i + 1
    end
    t.eq(keys, { "title", "date", "summary", "tags", "draft" }, "the front matter's keys")
    t.eq(lines[3], 'date: "' .. DATE .. '"', "the date --date gave")
    t.eq(lines[6], "draft: false", "the post is not a draft")
  end,

  ["the post opens with the repository's buttons, straight after the front matter"] = function(t)
    local lines = post(t)
    local close = 2
    while lines[close] and lines[close] ~= "---" do
      close = close + 1
    end
    local repo = "https://github.com/anirbanchakraborty-dev/ACH-NEOVIM"
    t.eq(lines[close + 1], "", "a blank line after the front matter")
    t.eq(lines[close + 2], ('<RepoLink url="%s" name="ACH-NEOVIM" license="MIT" licenseUrl="%s/blob/main/LICENSE" />'):format(repo, repo),
      "the repository and licence buttons")
    t.ok(slurp(t.root .. "/LICENSE"):match("^MIT License") ~= nil, "LICENSE is the MIT licence the button names")
  end,

  ["the screenshots follow the buttons, each at the size its file has"] = function(t)
    local lines = post(t)
    local at = find(lines, "---", 2) + 2
    local shots = dofile(t.root .. "/lua/ach/docs.lua").post.screenshots or {}
    t.ok(#shots >= 3, "lua/ach/docs.lua lists the screenshots")
    for _, shot in ipairs(shots) do
      local path = t.root .. "/docs/images/" .. shot.file
      t.eq(vim.fn.filereadable(path), 1, shot.file .. " is in docs/images")
      local width, height = webp_size(path)
      local want = ('<Figure src="/figures/ach-neovim/%s" alt="%s" caption="%s" id="fig:%s" width="%d" height="%d" />'):format(
        shot.file, shot.alt, shot.caption, shot.file:gsub("%.webp$", ""), width, height)
      at = at + 2
      t.eq({ lines[at - 1], lines[at] }, { "", want }, shot.file .. "'s figure, after a blank line")
    end
    t.eq({ lines[at + 1], lines[at + 2] }, { "", '<Callout type="note">' }, "the note follows the last screenshot")
  end,

  ["a WebP file's size comes from its header, in each of its three forms"] = function(t)
    local D = dofile(t.root .. "/scripts/docs.lua")
    local function le(v, n)
      local out = {}
      for _ = 1, n do
        out[#out + 1] = string.char(v % 256)
        v = math.floor(v / 256)
      end
      return table.concat(out)
    end
    local head = "RIFF" .. le(100, 4) .. "WEBP"
    local forms = {
      extended = head .. "VP8X" .. le(10, 4) .. le(0, 4) .. le(1279, 3) .. le(719, 3),
      lossless = head .. "VP8L" .. le(50, 4) .. "\47" .. le(1279 + 719 * 16384, 4) .. ("\0"):rep(10),
      lossy = head .. "VP8 " .. le(50, 4) .. le(0, 3) .. "\157\1\42" .. le(1280, 2) .. le(720, 2),
    }
    for name, bytes in pairs(forms) do
      local path = t.tmpdir() .. "/" .. name .. ".webp"
      write(path, bytes)
      t.eq({ D.webp_size(path) }, { 1280, 720 }, "the " .. name .. " form's size")
    end
    local png = t.tmpdir() .. "/not.webp"
    write(png, "\137PNG\r\n\26\n" .. ("\0"):rep(30))
    t.ok(not pcall(D.webp_size, png), "a file that is not WebP is refused")
  end,

  ["the README shows the same screenshots"] = function(t)
    local readme = slurp(t.root .. "/README.md")
    for _, shot in ipairs(dofile(t.root .. "/lua/ach/docs.lua").post.screenshots or {}) do
      local line = ("![%s](docs/images/%s)"):format(shot.alt, shot.file)
      t.ok(readme:find(line, 1, true) ~= nil, "README.md has " .. line)
    end
  end,

  ["a description and a key come out escaped, each key under its card section"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    t.ok(find(lines, "Turns \\{a\\} into \\<b\\> | c.") ~= nil, "alpha's description, escaped")
    local files = find(lines, "### Files and buffers")
    local outside = find(lines, "### Outside the menus")
    local x = find(lines, "| `Space x` | Opens \\{x\\} \\<y\\> \\| z | n, x |")
    local alt = find(lines, "| `Alt-j` | Move Down | n |")
    t.ok(files and outside and x and alt, "both sections and both rows are in the post")
    t.ok(files < x and x < outside and outside < alt, "each key sits under its section")
  end,

  ["a $ outside code comes out escaped, and a $ inside a code span does not"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    t.ok(find(lines, "Reads \\$HOME and \\$PATH, never `$SHELL`.") ~= nil, "beta's description, both bare $ escaped")
    t.ok(find(lines, "Reads $HOME and $PATH, never `$SHELL`.") == nil, "no line keeps the bare $ for remark-math")
  end,

  ["a plugin with opts gets Options then Full Spec, and one without gets Full Spec alone"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    local alpha = find(lines, "#### alpha.nvim")
    local beta = find(lines, "#### beta.nvim")
    local gamma = find(lines, "#### gamma.nvim")
    t.ok(alpha and beta and gamma and alpha < beta and beta < gamma, "alpha, beta and gamma, in that order")
    local function labels(from, to)
      local out = {}
      for i = from, to do
        out[#out + 1] = lines[i]:match('^<Tab label="(.-)">$')
      end
      return out
    end
    t.eq(labels(alpha, beta), { "Options", "Full Spec" }, "alpha's tabs")
    t.eq(labels(beta, gamma), { "Full Spec" }, "beta's tabs")
    local options = find(lines, '<Tab label="Options">', alpha)
    t.eq(vim.list_slice(lines, options + 2, options + 5), {
      "```lua",
      "-- Three is enough.",
      "opts = { size = 3 }",
      "```",
    }, "alpha's Options tab, with the comment above opts")
  end,

  ["a plugin's heading is its name, and the line after its description links its repository"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    local alpha = find(lines, "#### alpha.nvim")
    t.ok(alpha ~= nil, "alpha's heading is its name alone")
    t.eq(
      vim.list_slice(lines, alpha + 3, alpha + 4),
      { "", "Repository: [someone/alpha.nvim](https://github.com/someone/alpha.nvim)" },
      "the line after alpha's description"
    )
  end,

  ["a dependency shows the line that brings it in, and a language its table and tabs"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    local gamma = find(lines, "#### gamma.nvim")
    t.ok(gamma ~= nil, "gamma is in the post")
    t.eq(vim.list_slice(lines, gamma + 6, gamma + 13), {
      "lazy.nvim installs it as a dependency of `alpha.nvim`, in `lua/ach/plugins/fixture.lua`:",
      "",
      "<Tabs>",
      '<Tab label="Full Spec">',
      "",
      "```lua",
      'dependencies = { "someone/gamma.nvim" }',
      "```",
    }, "gamma's dependency line")
    local demo = find(lines, "### demo")
    t.ok(demo ~= nil, "the demo language has a subsection")
    t.eq(vim.list_slice(lines, demo + 2, demo + 10), {
      "| Part | Names |",
      "| --- | --- |",
      "| File types | `demo` |",
      "| Parsers | `demo` |",
      "| Servers | `demo_ls` |",
      "| Formatters | `demofmt` for `demo` |",
      "| Linters | none |",
      "| Debugger | demo-dap |",
      "| Grammar | Harper |",
    }, "the demo language's table")
    local entry = find(lines, '<Tab label="Entry">', demo)
    t.eq(
      lines[entry + 3],
      'demo = { ft = { "demo" }, ts = { "demo" }, lsp = { "demo_ls" }, fmt = { demo = { "demofmt" } }, '
        .. "harper = true }",
      "the Entry tab, without the group comment above it"
    )
    local options = find(lines, '<Tab label="Options">', demo)
    t.eq(vim.list_slice(lines, options + 3, options + 4), {
      "-- The demo server's one setting.",
      "demo_ls = { settings = { level = 1 } }",
    }, "the Options tab, with the comment above the setting")
  end,

  ["two runs at the same commit and date write the same bytes"] = function(t)
    local dir = fixture(t)
    local first = generate(t, dir, { "--date", DATE })
    local second = generate(t, dir, { "--date", DATE })
    t.ok(#first > 0, "the post is not empty")
    t.eq(second, first, "the second run's post against the first's")
  end,

  ["the date is HEAD's commit date unless --date names one"] = function(t)
    local dir = fixture(t)
    t.eq(lines_of(generate(t, dir))[3], 'date: "2026-03-04"', "with no --date, the date of the fixture's commit")
    t.eq(lines_of(generate(t, dir, { "--date", "2027-01-02" }))[3], 'date: "2027-01-02"', "--date 2027-01-02")
    local bad = docs(dir, { "--out", t.tmpdir() .. "/bad.mdx", "--date", "2 January 2027" })
    t.eq(bad.code, 1, "a --date not written YYYY-MM-DD is refused")
  end,

  ["a plugin in the lock with no entry in lua/ach/docs.lua stops the post"] = function(t)
    local lock = vim.deepcopy(LOCK)
    lock["delta.nvim"] = { branch = "main", commit = ("4"):rep(40) }
    local dir = fixture(t, lock)
    local out = t.tmpdir() .. "/post.mdx"
    local r = docs(dir, { "--out", out })
    t.eq(r.code, 1, "scripts/docs exits 1")
    t.ok((r.stderr or ""):find("delta.nvim", 1, true) ~= nil, "the error names delta.nvim: " .. (r.stderr or ""))
    t.eq(vim.fn.filereadable(out), 0, "no post is written")
  end,

  ["a screenshot with no file in docs/images stops the post"] = function(t)
    local docs_lua = FILES["lua/ach/docs.lua"]:gsub(
      'tags = { "demo" } }',
      'tags = { "demo" }, screenshots = { { file = "missing.webp", alt = "A view.", caption = "The view." } } }')
    local dir = fixture(t, nil, { ["lua/ach/docs.lua"] = docs_lua })
    local out = t.tmpdir() .. "/post.mdx"
    local r = docs(dir, { "--out", out })
    t.eq(r.code, 1, "scripts/docs exits 1")
    t.ok((r.stderr or ""):find("missing.webp", 1, true) ~= nil, "the error names missing.webp: " .. (r.stderr or ""))
    t.eq(vim.fn.filereadable(out), 0, "no post is written")
  end,
}
