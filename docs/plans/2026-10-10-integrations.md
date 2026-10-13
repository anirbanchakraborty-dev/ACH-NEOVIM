# ACH-NEOVIM Integrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything outside a single language works here: git from change bars through to GitHub, Claude Code in a panel beside the code, LaTeX with Skim, Markdown drawn in place and in a browser, the x86 manual and the news feeds a key away, Ghostty set up around the editor, startup time held to a baseline, an update procedure that can be undone, a fast check that runs by itself after Homebrew moves Neovim, a key card, and a documentation post that a generator writes from the configuration's own source.

**Architecture:** Each integration is a pair of files. `lua/ach/<area>.lua` holds the logic and the guards, written so a test can swap a program or a plugin for a stand-in, and `lua/ach/plugins/<area>.lua` holds the lazy.nvim specs and keys, which call into it. Every program from Homebrew is checked before it is used, and a missing one prints its `brew install` line and does nothing else. The two pieces that open a network port, claudecode's WebSocket server and live-preview's web server, bind to `127.0.0.1`, and a test reads the bound address back from `lsof`. Five of the last six tasks are not editor code: the Ghostty settings, the startup benchmark, `scripts/update`, `docs/key-card.md` and `scripts/docs`, which writes the documentation post, each with a test that keeps it honest. The sixth, between the update and the key card, runs the fast check in the background the first time a new Neovim release starts on a screen.

**Tech Stack:** gitsigns.nvim, Neogit, diffview.nvim, octo.nvim with plenary.nvim, snacks.nvim's lazygit, gitbrowse, git pickers, terminal and image modules, claudecode.nvim, VimTeX with Skim, render-markdown.nvim, live-preview.nvim, newsboat, Ghostty 1.2 or later, and the command-line programs the tasks list in `lua/ach/need.lua`: `lazygit`, `gh`, `claude`, `latexmk`, Skim's `displayline`, `magick`, `pdflatex`, `gs`, Poppler's `pdftotext` and `newsboat`, with macOS's own `osascript` asking Skim for a page. Startup is timed with Neovim's own `--startuptime`, so no benchmarking program is needed.

**Spec:** `docs/specs/2026-10-10-ach-neovim-design.md`

This is the third of three plans, run in this order: foundation, languages, integrations. It starts from the configuration the languages plan leaves behind, in which every language in the table opens with its parser, server, formatter, linter and grammar checking, and `scripts/check` passes. It ends with every integration the spec lists working, the startup benchmark in the fast check, the documentation post generated from the source, and the suite still passing.

## Global Constraints

- Neovim 0.12.4 or later. The foundation asks for 0.12, but VimTeX's current release refuses anything older than 0.12.4, so this plan raises the floor and `:checkhealth ach` says so. Homebrew has 0.12.6. Every command in this plan runs from the repository root, the folder that holds `init.lua`.
- LazyVim is a reference, never a dependency. Nothing requires or imports a `lazyvim` module. A file that adapts a LazyVim function says so in its header comment, as `-- Adapted from LazyVim (Apache-2.0), <path in LazyVim>.`
- Every key this configuration defines carries a `desc`, and that description has a line in `M.keys` in `lua/ach/icons.lua`. A task that adds a key adds its line above the marker `-- Keys added by later tasks go above this line.` in the same commit, and the same holds for groups and toggles with their own markers. Keys a plugin sets inside its own windows, such as Neogit's status buffer or Claude Code's panel, are the plugin's and are not listed.
- Every icon comes from `lua/ach/icons.lua`, named there by its Nerd Fonts 3.5.1 name. This plan needs no new glyph; every reference it uses is already in the database.
- Nothing writes into the repository while the editor runs, with the three exceptions the languages plan lists: `lazy-lock.json` during a deliberate update, `mason-lock.json` on a first install or under `:AchMasonUpdate`, and `docs/languages.md` under `scripts/check --full`. `tests/baseline.json` is written only by `scripts/check --baseline`, which runs once in the startup benchmark task and afterwards only when the owner asks for it. `docs/site/keymaps.json` is written only by `scripts/check --keymaps`, and `scripts/docs` writes nothing but the file its `--out` names.
- Programs from Homebrew are never installed by the configuration. A key or command whose program is missing prints the `brew install` line, and the Mac setup script's Brewfile installs them.
- Every server this configuration opens listens on `127.0.0.1` alone. claudecode's also refuses a connection without the token in its lock file. live-preview's refuses any path whose real location, with every `..` resolved and every link followed, is outside the folder it serves, and any request whose `Host` or `Origin` names another site.
- The regular suite never downloads, never starts the `claude` program, never contacts GitHub and never opens a browser, Skim or newsboat. Where a test needs one of them, the program is a stand-in.
- Lua is formatted by `stylua.toml`: two-space indent, 120 columns, double quotes.
- Markdown in this repository keeps one paragraph per line, with no hard wrap and no numbered headings or numbered lists.
- The documentation post is MDX for the website, and uses Markdown and two components only: `<Tabs>` with `<Tab label="...">` inside it, and `<Callout type="note">`, `"tip"` or `"warning"`, each tag on a line of its own. Outside code, every `{`, `}`, `<`, `>` and `$` is escaped with a backslash, and so is a `|` inside a table cell. The four pages in `docs/site/` are copied into it as written, so they follow the same rule and start their headings at `###`.
- Commits are made inside this repository, with `git commit --only <paths>` and a Conventional Commit subject that carries a scope. The commit `scripts/update` makes is the one whose message the script writes, from the two lock files. Nothing is pushed without the owner's yes.

## Review Focus

- **A git key pressed on a file outside every repository, such as a scratch note in `/tmp`.** The owner must see one message saying the folder is not in a git repository, and no lazygit, Neogit, diff or picker window may open on some other folder. The test lives in the git task.
- **A remote whose URL carries a user name or a token, such as `https://build_bot@github.com/owner/project.git`.** The link copied or opened for the current line must not contain it, because snacks keeps it and a token pasted into a chat is a leaked token. The test lives in the git task.
- **Claude Code with no window to show it, or with nothing else docked on the right.** With Neovim started with no window, such as `nvim --headless`, a script, or this test suite, no Claude Code server may start and no lock file may appear under `~/.claude/ide/`, so Claude Code never offers to connect to an editor nobody can see. With the panel opened and nothing else docked on the right, it must take 40 percent of the screen's width, and keep it when search and replace docks beside it, rather than the 30 columns edgy gives a side pane whose view names no width. Both tests live in the Claude Code task.
- **A request to the Markdown preview that climbs out of the served folder, such as `GET /%2e%2e/%2e%2e/etc/passwd`.** The answer must be 404 with no file contents, because live-preview joins the decoded path onto its root without a check. The test lives in the Markdown task.
- **A plugin description, a key's description or a hand-written page that holds a character MDX reads as markup, such as `{`, `<`, `$`, or a `|` inside a table cell.** The documentation post must carry it escaped, as `\{`, `\<`, `\$` and `\|`: one bare `{` or `<` fails the website's MDX build, two bare `$` turn the prose between them into a formula, because the website runs remark-math, and a bare `|` splits a table row. Inside a code span or a code block it stays as typed. The tests live in the documentation post task.

## File Structure

| Path | Responsibility |
| --- | --- |
| `lua/ach/git.lua` | gitsigns' options, its hunk keys and two toggles; the guards in front of lazygit, Neogit, diffview, octo and the git pickers; the browse link with any user or token removed |
| `lua/ach/plugins/git.lua` | gitsigns.nvim, Neogit, diffview.nvim, octo.nvim with plenary.nvim, and the snacks git keys |
| `lua/ach/claude.lua` | `status()` for the status bar, claudecode's options, the panel's window settings and its edgy view |
| `lua/ach/plugins/claude.lua` | claudecode.nvim and the `Space a` keys |
| `lua/ach/plugins/ui.lua` | Gains the Claude Code panel's view at the front of edgy's right edge |
| `lua/ach/latex.lua` | VimTeX's settings for Skim, the build folder kept outside the repository, the build hook a private `.nvim.lua` can set, and a description for each of VimTeX's keys |
| `lua/ach/plugins/latex.lua` | VimTeX, loaded at startup so Skim can always reach the editor |
| `lua/ach/treesitter.lua` | Gains `with_regex`, which keeps Vim's own LaTeX highlighting running beside tree-sitter's, because VimTeX reads it |
| `lua/ach/lsp.lua` | Its `]]` and `[[` reference jumps stand aside in LaTeX files, where VimTeX's section jumps hold those keys |
| `lua/ach/preview.lua` | live-preview's options and the guard on its server, which checks each path's real location and each request's `Host` and `Origin`; `Space c p`; the check for the programs that draw formulas and pictures in the editor |
| `lua/ach/plugins/markdown.lua` | render-markdown.nvim, live-preview.nvim, snacks' image module, and their keys |
| `lua/ach/x86.lua` | Finds an instruction's page in Intel's manual, keeps the pages found in Neovim's cache folder, and opens Skim there through `osascript` |
| `lua/ach/news.lua` | newsboat in a floating terminal, and where newsboat reads its feed list |
| `lua/ach/plugins/tools.lua` | `Space c x` for the x86 lookup and `Space N` for the news reader, as keys on snacks.nvim |
| `lua/ach/need.lua` | The Homebrew programs the integrations call, each with the line that installs it; `have(name)` checks one and prints that line when it is missing |
| `lua/ach/health.lua` | Gains an Integrations section: the 0.12.4 floor VimTeX sets, then each program in `ach.need`, installed or with its install line |
| `ghostty/config.ghostty` | Ghostty's settings: font, navy background, left Option as Alt, and the sixteen colours Neovim's own terminal uses |
| `tests/baseline.json` | The startup medians: this configuration's on its first passing run, and stock LazyVim's |
| `tests/helpers/startup.lua` | Times ten starts of a configuration and returns the median; run with `nvim -l`, records the baseline |
| `scripts/check` | Gains `--baseline`, which downloads stock LazyVim into its throwaway folder and records `tests/baseline.json`, and `--keymaps`, which records every key this configuration sets in `docs/site/keymaps.json` |
| `lua/ach/update.lua` | The update, the restore and the list, and the commit message written from the lock files; run with `nvim -l`, drives a whole update |
| `scripts/update` | Updates plugins and Mason packages headlessly, runs the full check, and commits both lock files or puts everything back; `--list` and `--restore` |
| `lua/ach/upgrade.lua` | Runs the fast check in the background the first time a new Neovim program starts on a screen, and records the program once the check passes |
| `lua/ach/init.lua` | Gains the line that sets up the upgrade check |
| `docs/key-card.md` | The one-page key card, with Ghostty's keys |
| `lua/ach/docs.lua` | The documentation post's data: its title, summary and tags, the introductions above the generated sections, every plugin's category and one-sentence description, each language's debugger, and the card section for a key the card does not name |
| `scripts/docs`, `scripts/docs.lua` | Write the documentation post, MDX for the website, from the source without starting the configuration; `--out` and `--date` |
| `docs/site/getting-started.md`, `docs/site/installation.md`, `docs/site/news.md`, `docs/site/configuration.md` | The post's four hand-written sections, in the owner's words |
| `docs/site/keymaps.json` | Every key the configuration sets, with its modes and description, for the post's Keymaps section |
| `tests/helpers/keymaps.lua` | Reads every key in a child Neovim; run with `nvim -l`, writes `docs/site/keymaps.json` |
| `tests/test_need.lua`, `tests/test_git.lua`, `tests/test_claude.lua`, `tests/test_latex.lua`, `tests/test_markdown.lua`, `tests/test_tools.lua`, `tests/test_ghostty.lua`, `tests/test_startup.lua`, `tests/test_update.lua`, `tests/test_upgrade.lua`, `tests/test_key_card.lua`, `tests/test_docs.lua` | One file per area |
| `lua/ach/icons.lua` | Gains a line in `M.keys` for every key this plan adds, and three lines in `M.toggles` |

---

### Task: Programs from Homebrew

**Files:**
- Create: `lua/ach/need.lua`
- Modify: `lua/ach/health.lua`, which gains an Integrations section at the end; `tests/test_health.lua`, whose test of the section order gains that title
- Test: `tests/test_need.lua`

**Interfaces:**
- Consumes: `require("ach.health").sections`, a list of `{ [1]: string, [2]: fun(s: table) }`, each a section's title and the function that writes it, called in order by `check()` under `vim.health.start(title)`.
- Produces:
  - `require("ach.need")`: `programs: ach.Program[]`, each with `name` (looked for on the path), `brew` (the line that installs it), `purpose` (what it is for, as a noun phrase) and an optional `label`; `get(name): ach.Program|nil`; `found(name): boolean`, which prints nothing; and `have(name): boolean`, which prints `<label or name> is not installed. Install it with: <brew>` when the program is missing, and raises an error when `name` is not in the list.
  - The marker `-- Programs added by later tasks go above this line.` in `M.programs`. Every later task that calls a program adds its line above it in the same commit.
  - An Integrations section, last in `:checkhealth ach`, that holds Neovim to 0.12.4 and reports each program in the list.

Nearly every integration in this plan hands work to a program that is not part of Neovim: lazygit, GitHub's `gh`, the `claude` program, Skim, ImageMagick, newsboat. The configuration never installs any of them, because a Homebrew install from inside an editor is slow, silent and hard to undo, and the Mac setup script's Brewfile is where those programs are kept. So a key whose program is missing has one job: say exactly what to run, and stop.

This task writes that once, as a list and two functions, so every later task asks the same way. `have("lazygit")` returns true when lazygit is on the path. When it is not, it prints `lazygit is not installed. Install it with: brew install lazygit` and returns false, and the key returns without opening anything. A name that is not in the list is an error rather than a quiet false, so a key with a misspelt program name fails in the tests rather than telling the owner to install a program that does not exist. A test also reads every Lua file in the configuration for `have("...")` and checks each name is listed, which catches the misspelling even in a key no test presses.

The same list feeds `:checkhealth ach`. The languages plan's health report has eight sections; this task adds a ninth, Integrations, after Mason. It starts with the Neovim version, because VimTeX's current release refuses to start on anything older than 0.12.4, a higher floor than the 0.12 the rest of the configuration needs. Then it gives one line per program: installed, or not installed with the Homebrew line beneath it as advice.

- [ ] **Write the failing tests**

`tests/test_need.lua`:

```lua
-- The Homebrew programs the integrations call, and the Integrations section
-- of :checkhealth ach. vim.fn.executable and vim.notify are stand-ins, so no
-- test depends on what this Mac has installed.

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Two programs to stand in for the real list.
local fake = {
  { name = "lazygit", brew = "brew install lazygit", purpose = "Lazygit on Space g g" },
  {
    name = "gh",
    label = "GitHub's gh",
    brew = "brew install gh, then run: gh auth login",
    purpose = "GitHub issues and pull requests",
  },
}

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level)
        said[#said + 1] = { msg = msg, level = level }
      end,
    },
  }, body)
  return said
end

-- Runs the Integrations section alone and returns what it reported: one
-- { kind, msg, advice } per call, kind being the vim.health function called.
local function integrations(stubs)
  local H = require("ach.health")
  local section
  for _, s in ipairs(H.sections) do
    if s[1] == "Integrations" then
      section = s[2]
    end
  end
  assert(section, "no Integrations section in :checkhealth ach")
  local out = {}
  local function record(kind)
    return function(msg, advice)
      out[#out + 1] = { kind = kind, msg = msg, advice = advice }
    end
  end
  local all = {
    { vim.health, "ok", record("ok") },
    { vim.health, "info", record("info") },
    { vim.health, "warn", record("warn") },
    { vim.health, "error", record("error") },
  }
  vim.list_extend(all, stubs)
  with(all, function()
    section({})
  end)
  return out
end

-- A stand-in for vim.fn.has that answers old for Neovim 0.12.4.
local function release(old)
  local real = vim.fn.has
  return function(feature)
    if feature == "nvim-0.12.4" then
      return old and 0 or 1
    end
    return real(feature)
  end
end

return {
  ["a program on the path is found and nothing is printed"] = function(t)
    local need = require("ach.need")
    local found
    local said = notices(function()
      with({ { need, "programs", fake }, { vim.fn, "executable", only({ lazygit = true }) } }, function()
        found = need.have("lazygit")
      end)
    end)
    t.eq(found, true, "lazygit is found")
    t.eq(#said, 0, "nothing is printed")
  end,

  ["a missing program prints the line that installs it and is not found"] = function(t)
    local need = require("ach.need")
    local found
    local said = notices(function()
      with({ { need, "programs", fake }, { vim.fn, "executable", only({}) } }, function()
        found = need.have("gh")
      end)
    end)
    t.eq(found, false, "gh is not found")
    t.eq(#said, 1, "one message")
    t.eq(said[1].msg, "GitHub's gh is not installed. Install it with: brew install gh, then run: gh auth login")
    t.eq(said[1].level, vim.log.levels.WARN, "as a warning")
  end,

  ["a name the list does not hold is an error"] = function(t)
    local need = require("ach.need")
    local ok, err
    with({ { need, "programs", fake } }, function()
      ok, err = pcall(need.have, "lazygti")
    end)
    t.eq(ok, false, "an error")
    t.ok(tostring(err):find("lazygti", 1, true) ~= nil, "naming the program")
  end,

  ["every program in the list has a name, a brew line and a purpose, once each"] = function(t)
    local seen = {}
    for _, p in ipairs(require("ach.need").programs) do
      t.ok(type(p.name) == "string" and p.name ~= "", "a name")
      t.ok(not seen[p.name], p.name .. " is listed once")
      seen[p.name] = true
      t.ok(type(p.brew) == "string" and p.brew:find("^brew ") ~= nil, p.name .. " installs with brew")
      t.ok(type(p.purpose) == "string" and p.purpose ~= "", p.name .. " says what it is for")
    end
  end,

  ["every have() in the configuration names a program in the list"] = function(t)
    local need = require("ach.need")
    local files = vim.fs.find(function(name)
      return name:match("%.lua$") ~= nil
    end, { path = t.root .. "/lua", type = "file", limit = math.huge })
    t.ok(#files > 0, "the configuration's Lua files are found")
    for _, file in ipairs(files) do
      local text = table.concat(vim.fn.readfile(file), "\n")
      for name in text:gmatch('have%("([^"]+)"%)') do
        t.ok(need.get(name) ~= nil, ("%s asks for %s, which ach.need does not list"):format(file, name))
      end
    end
  end,

  ["the Integrations section holds Neovim to the 0.12.4 floor VimTeX sets"] = function(t)
    local need = require("ach.need")
    local old = integrations({ { need, "programs", {} }, { vim.fn, "has", release(true) } })
    t.eq(#old, 1, "one line")
    t.eq(old[1].kind, "error", "an older Neovim is an error")
    t.ok(old[1].msg:find("0.12.4", 1, true) ~= nil, "naming the floor")
    t.eq(old[1].advice, { "brew upgrade neovim" }, "with the command that fixes it")
    local now = integrations({ { need, "programs", {} }, { vim.fn, "has", release(false) } })
    t.eq(now[1].kind, "ok", "0.12.4 or later is fine")
  end,

  ["the Integrations section reports each program, with the install line for one that is missing"] = function(t)
    local need = require("ach.need")
    local out = integrations({
      { need, "programs", fake },
      { vim.fn, "has", release(false) },
      { vim.fn, "executable", only({ lazygit = true }) },
    })
    t.eq(#out, 3, "the Neovim line and one line per program")
    t.eq(out[2], { kind = "ok", msg = "lazygit is installed, for Lazygit on Space g g" })
    t.eq(out[3], {
      kind = "warn",
      msg = "GitHub's gh is not installed, so GitHub issues and pull requests will not work",
      advice = { "brew install gh, then run: gh auth login" },
    })
  end,

  ["Integrations is the last section of :checkhealth ach"] = function(t)
    local sections = require("ach.health").sections
    t.eq(sections[#sections][1], "Integrations")
  end,
}
```

In `tests/test_health.lua`, the test `the sections come in order, and one that fails is reported without stopping the rest` lists every title. Add the new one after `"Mason"`, so the list reads:

```lua
    t.eq(titles, {
      "Neovim",
      "Build tools",
      "Runtimes",
      "Programs Mason does not carry",
      "Languages",
      "Metals",
      "Debugging",
      "Mason",
      "Integrations",
    }, "every section, in order")
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_need`
Expected: `0 passed, 8 failed, 0 need a person, 0 skipped`, exit 1. The first five fail on `module 'ach.need' not found`. The next two fail on `no Integrations section in :checkhealth ach`, and the last because the final section is still Mason.

Run: `scripts/check --only test_health`
Expected: `14 passed, 1 failed, 0 need a person, 0 skipped`, exit 1. The section order test fails because the report still ends at Mason.

- [ ] **Write the list of programs**

`lua/ach/need.lua`:

```lua
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
function M.found(name)
  return vim.fn.executable(name) == 1
end

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
```

- [ ] **Add the Integrations section**

In `lua/ach/health.lua`, add this function just above `M.sections = {`:

```lua
-- What the integrations need: the Neovim release VimTeX asks for, which is
-- later than the rest of the configuration needs, and each program in
-- ach.need, installed or with the line that installs it.
local function integrations()
  local need = require("ach.need")
  if vim.fn.has("nvim-0.12.4") == 1 then
    vim.health.ok("Neovim is 0.12.4 or later, as VimTeX needs")
  else
    vim.health.error(
      ("Neovim %s is older than 0.12.4, which VimTeX needs"):format(tostring(vim.version())),
      { "brew upgrade neovim" }
    )
  end
  for _, p in ipairs(need.programs) do
    local name = p.label or p.name
    if need.found(p.name) then
      vim.health.ok(("%s is installed, for %s"):format(name, p.purpose))
    else
      vim.health.warn(("%s is not installed, so %s will not work"):format(name, p.purpose), { p.brew })
    end
  end
end
```

Then add its line at the end of the list, so `M.sections` reads:

```lua
M.sections = {
  { "Neovim", neovim },
  { "Build tools", build },
  { "Runtimes", runtimes },
  { "Programs Mason does not carry", programs },
  { "Languages", languages },
  { "Metals", metals },
  { "Debugging", debugging },
  { "Mason", mason },
  { "Integrations", integrations },
}
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the eight `test_need` tests and all fifteen `test_health` tests among them, exit 0.

- [ ] **Read the report once**

Run: `nvim -u init.lua "+checkhealth ach"`
Expected: nine headings under `ach:`, the last of them Integrations, holding one line: `OK Neovim is 0.12.4 or later, as VimTeX needs`. The list of programs is still empty, so nothing follows it. Quit with `:qa`.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/need.lua tests/test_need.lua
git commit --only lua/ach/need.lua tests/test_need.lua lua/ach/health.lua tests/test_health.lua -m "feat(health): list the Homebrew programs the integrations call, and hold Neovim to VimTeX's 0.12.4"
```

---

### Task: Git

**Files:**
- Create: `lua/ach/git.lua`, `lua/ach/plugins/git.lua`
- Modify: `lua/ach/icons.lua`, which gains a line in `M.keys` for each key below and two lines in `M.toggles`; `lua/ach/need.lua`, which gains lazygit and gh; `lazy-lock.json`, which gains gitsigns.nvim, neogit, diffview.nvim, octo.nvim and plenary.nvim
- Test: `tests/test_git.lua`

**Interfaces:**
- Consumes: `require("ach.util").git_root(buf?)`, which is `vim.fs.root(buf or 0, ".git")`; `require("ach.icons")` (`gitsigns`, the six bar glyphs `add`, `change`, `delete`, `topdelete`, `changedelete` and `untracked`; `toggle(toggle)`; `key(desc)`); `require("ach.need").have(name)`; the global `Snacks` with its `lazygit(opts)`, `gitbrowse(opts)`, `picker[source](opts)` and `toggle(opts)`; snacks' status column, which the foundation turns on and which draws any sign whose highlight starts with `GitSign`.
- Produces:
  - `require("ach.git")`: `repo(): string|nil`, the top of the repository holding the current buffer, or the working folder's when the buffer is not a file, printing `Not inside a git repository: <folder>` when there is none; `where(where?: "cwd"): string|nil`, the same, or with `"cwd"` the working folder when it is inside a repository; `lazygit(where?)`; `neogit()`; `diffview(what: "open"|"file")`; `octo(args: string)`; `pick(source: string, where?)`; `clip(text)`, which puts text on the system clipboard and exists so tests can replace it; `scrub(url): string`; `copy_link()`; `browse()`; `gitsigns_opts(): table`; `on_attach(buf)`; and `toggles()`.
  - `vim.b.gitsigns_status_dict`, with `head`, `added`, `changed` and `removed`, which the foundation's status bar already reads and shows once this task lands.

The foundation leaves `Space g` as an empty menu and the status bar with a branch slot that stays blank. This task fills both. It brings four plugins and leans on snacks for the rest, and each does one thing. gitsigns draws a coloured bar beside every line that differs from the last commit and gives the keys that work on one change at a time, which git calls a hunk: a run of added, changed or removed lines. lazygit is a full-screen git program run in a floating terminal. Neogit is git's status page inside Neovim, for the owner who wants to stage and commit without leaving a buffer. diffview shows a change side by side, and a file's history commit by commit. octo opens GitHub issues and pull requests as buffers.

Every key goes through `lua/ach/git.lua`, which first finds the repository. A key pressed in a scratch file in `/tmp` therefore prints one line, `Not inside a git repository: /tmp`, and opens nothing, rather than a lazygit window on whatever folder Neovim happened to start in. A key whose program is missing prints the Homebrew line from `ach.need` and stops. From a file deep inside a repository, the keys marked Root Dir open at the repository's top, so lazygit and Neogit see every change, not only the ones below the current folder.

The browse link needs one guard of its own. A remote's address can carry a user name or a token, as `https://build_bot@github.com/owner/project.git` does, and snacks copies it into the link. A token pasted into a chat or an issue is a leaked token, so `scrub` removes everything between `https://` and the `@` before the link is copied or opened, and the copy key prints the link it copied so the owner can see what is on the clipboard.

| Key | Description | What it does |
| --- | --- | --- |
| `Space g g` | Lazygit (Root Dir) | Opens lazygit in a floating window at the top of the current file's repository |
| `Space g G` | Lazygit (cwd) | Opens lazygit in Neovim's working folder |
| `Space g n` | Neogit (Root Dir) | Opens Neogit's status page in a new tab, for staging and committing |
| `Space g D` | Diff View (Root Dir) | Opens every uncommitted change side by side in a new tab; `:DiffviewClose` closes it |
| `Space g F` | File History (Diff View) | Lists every commit that touched the current file, each as a side-by-side diff |
| `Space g s` | Git Status | Lists the changed files in a picker, with a preview of each change |
| `Space g S` | Git Stash | Lists the saved stashes |
| `Space g d` | Git Diff (hunks) | Lists every hunk in the repository, to jump to one |
| `Space g l` | Git Log (Root Dir) | Lists the repository's commits |
| `Space g L` | Git Log (cwd) | Lists the commits that touched the working folder |
| `Space g f` | Git File History | Lists the commits that touched the current file |
| `Space g b` | Git Line History | Lists the commits that touched the current line |
| `Space g c` | Git Branches | Lists the branches, to switch to one |
| `Space g B` | Git Browse (open) | Opens the current file and line on GitHub in the browser; in visual mode, the selected lines |
| `Space g Y` | Git Browse (copy link) | Copies a link to the current line, pinned to its last commit, and prints it |
| `Space g i` | GitHub Issues | Lists the repository's issues on GitHub, through `gh` |
| `Space g p` | GitHub Pull Requests | Lists the repository's pull requests on GitHub |
| `]h` | Next Hunk | Moves to the next change; in a diff window, to the next difference |
| `[h` | Prev Hunk | Moves to the previous change |
| `]H` | Last Hunk | Moves to the last change in the file |
| `[H` | First Hunk | Moves to the first change in the file |
| `Space g h s` | Stage or Unstage Hunk | Stages the change under the cursor, or unstages it if it is staged; in visual mode, only the selected lines |
| `Space g h r` | Reset Hunk | Throws away the change under the cursor, putting back the committed lines |
| `Space g h S` | Stage Buffer | Stages every change in the file |
| `Space g h R` | Reset Buffer | Throws away every change in the file |
| `Space g h p` | Preview Hunk Inline | Shows the removed lines in place, above the new ones |
| `Space g h b` | Blame Line | Shows who last changed the line, when, and the whole commit message |
| `Space g h B` | Blame Buffer | Opens a side pane with the last commit for every line |
| `Space g h d` | Diff This | Splits the window into the file against its staged copy |
| `Space g h D` | Diff This ~ | Splits the window into the file against the commit before the last |
| `ih` | Select Hunk | A text object: `dih` deletes the change under the cursor, `vih` selects it |
| `Space u G` | Toggle Git Signs | Hides or shows the change bars |
| `Space u b` | Toggle Git Blame Line | Shows the current line's author and date at the end of the line, after a short pause |

The hunk keys exist only in a buffer gitsigns has attached to, which is a file inside a repository, so pressing `]h` elsewhere does what Neovim does by default. Two gitsigns functions LazyVim still maps are left out because gitsigns has deprecated them: `undo_stage_hunk`, since staging a staged hunk now unstages it, and `toggle_deleted`, which inline preview replaces.

- [ ] **Write the failing tests**

`tests/test_git.lua`:

```lua
-- Git. Each test makes its own repository in a scratch folder, with a fixed
-- name and email and with commit signing and hooks off, so no setting of the
-- owner's reaches it. lazygit, gh, the clipboard and the browser are
-- stand-ins: no test starts lazygit, reaches GitHub or touches the owner's
-- clipboard.
local I = require("ach.icons")

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Runs git in dir with the owner's settings that could interfere turned
-- off, checks that it worked, and returns what it printed, trimmed.
local function git(t, dir, ...)
  local argv = {
    "git",
    "--no-optional-locks",
    "-C",
    dir,
    "-c",
    "user.name=ACH",
    "-c",
    "user.email=ach@example.invalid",
    "-c",
    "commit.gpgsign=false",
    "-c",
    "core.hooksPath=/dev/null",
    ...,
  }
  local r = vim.system(argv, { text = true }):wait()
  t.eq(r.code, 0, table.concat(argv, " ") .. ": " .. (r.stderr or ""))
  return vim.trim(r.stdout or "")
end

-- Ten lines, "line 1" to "line 10", with the lines named in changed edited.
local function lines(changed)
  local out = {}
  for i = 1, 10 do
    out[i] = changed[i] and ("line %d, changed"):format(i) or ("line %d"):format(i)
  end
  return out
end

-- A repository in a fresh folder holding notes.txt, ten lines committed on
-- main. Returns the folder.
local function repo(t)
  local dir = t.tmpdir()
  git(t, dir, "init", "-q", "-b", "main")
  vim.fn.writefile(lines({}), dir .. "/notes.txt")
  git(t, dir, "add", "notes.txt")
  git(t, dir, "commit", "-q", "-m", "notes")
  return dir
end

-- Opens file and waits until gitsigns has read it, which is when its status
-- counts the given number of changed lines. Returns the buffer.
local function open(t, file, changed)
  vim.cmd.edit(vim.fn.fnameescape(file))
  local buf = vim.api.nvim_get_current_buf()
  local ready = vim.wait(5000, function()
    local d = vim.b[buf].gitsigns_status_dict
    return d ~= nil and d.changed == changed
  end, 20)
  t.ok(ready, ("gitsigns counts %d changed lines in %s"):format(changed, file))
  return buf
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

return {
  ["change bars come from gitsigns, in snacks' column, with the database's glyphs"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      local buf = open(t, dir .. "/notes.txt", 1)
      local ns = vim.api.nvim_get_namespaces()["gitsigns_signs_"]
      t.ok(ns ~= nil, "gitsigns' namespace for its bars")
      -- gitsigns numbers each bar by its line.
      local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, 3, { details = true })
      t.eq(mark[1], 2, "a bar on line 3")
      t.eq(mark[3].sign_hl_group, "GitSignsChange", "coloured as a change")
      t.eq(vim.trim(mark[3].sign_text), I.gitsigns.change, "drawn with the glyph from the icon database")
      t.ok(vim.wo.statuscolumn:find("snacks.statuscolumn", 1, true) ~= nil, "in snacks' column")
      t.eq(vim.b[buf].gitsigns_status_dict.head, "main", "and the branch is there for the status bar")
    end)
  end,

  ["the hunk keys belong to the buffer, and each has an icon"] = function(t)
    tidy(function()
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local keys = {
        { "]h", "n" },
        { "[h", "n" },
        { "]H", "n" },
        { "[H", "n" },
        { "<leader>ghs", "n" },
        { "<leader>ghs", "x" },
        { "<leader>ghr", "n" },
        { "<leader>ghr", "x" },
        { "<leader>ghS", "n" },
        { "<leader>ghR", "n" },
        { "<leader>ghp", "n" },
        { "<leader>ghb", "n" },
        { "<leader>ghB", "n" },
        { "<leader>ghd", "n" },
        { "<leader>ghD", "n" },
        { "ih", "o" },
        { "ih", "x" },
      }
      for _, k in ipairs(keys) do
        local m = vim.fn.maparg(k[1], k[2], false, true)
        t.eq(m.buffer, 1, ("%s in mode %s belongs to the buffer"):format(k[1], k[2]))
        t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
      end
    end)
  end,

  ["]h and the other hunk moves land on the changed lines"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true, [8] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 2)
      local function at(line)
        return vim.wait(2000, function()
          return vim.fn.line(".") == line
        end, 20)
      end
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      press("]h")
      t.ok(at(3), "]h from line 1 goes to the change on line 3")
      press("]H")
      t.ok(at(8), "]H goes to the last change, on line 8")
      press("[H")
      t.ok(at(3), "[H goes back to the first")
    end)
  end,

  ["Space g h s stages the change under the cursor"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 1)
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      press("<leader>ghs")
      local staged = vim.wait(5000, function()
        return git(t, dir, "diff", "--cached", "--name-only") == "notes.txt"
      end, 100)
      t.ok(staged, "notes.txt is staged")
    end)
  end,

  ["Space u G and Space u b turn the bars and the line's blame off and on"] = function(t)
    tidy(function()
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local function config()
        return require("gitsigns.config").config
      end
      local signs, blame = config().signcolumn, config().current_line_blame
      press("<leader>uG")
      t.eq(config().signcolumn, not signs, "Space u G flips the bars")
      press("<leader>uG")
      t.eq(config().signcolumn, signs, "and back")
      press("<leader>ub")
      t.eq(config().current_line_blame, not blame, "Space u b flips the line's blame")
      press("<leader>ub")
      t.eq(config().current_line_blame, blame, "and back")
    end)
  end,

  ["lazygit opens at the top of the repository, from a file in a subfolder"] = function(t)
    tidy(function()
      local dir = repo(t)
      vim.fn.mkdir(dir .. "/sub", "p")
      vim.fn.writefile({ "deep" }, dir .. "/sub/deep.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/sub/deep.txt"))
      local got
      with({
        { vim.fn, "executable", only({ lazygit = true }) },
        {
          Snacks,
          "lazygit",
          function(opts)
            got = opts
          end,
        },
      }, function()
        press("<leader>gg")
      end)
      t.eq(got and got.cwd, dir, "lazygit starts at the repository's top")
    end)
  end,

  ["outside a repository, every git action says so once and opens nothing"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = t.tmpdir()
      vim.fn.writefile({ "scratch" }, dir .. "/scratch.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/scratch.txt"))
      local tabs = #vim.api.nvim_list_tabpages()
      local opened, said = {}, {}
      local function record(what)
        return function()
          opened[#opened + 1] = what
        end
      end
      with({
        { vim.fn, "executable", only({ lazygit = true, gh = true }) },
        { Snacks, "lazygit", record("lazygit") },
        {
          Snacks,
          "picker",
          setmetatable({}, {
            __index = function(_, source)
              return record(source)
            end,
          }),
        },
        { package.loaded, "neogit", { open = record("neogit") } },
        { G, "clip", record("clipboard") },
        { vim.ui, "open", record("browser") },
        {
          vim,
          "notify",
          function(msg)
            said[#said + 1] = msg
          end,
        },
      }, function()
        G.lazygit()
        G.neogit()
        G.diffview("open")
        G.diffview("file")
        G.pick("git_status")
        G.copy_link()
        G.browse()
      end)
      t.eq(opened, {}, "nothing opens")
      t.eq(#vim.api.nvim_list_tabpages(), tabs, "no tab opens")
      t.eq(#said, 7, "one message for each")
      for _, msg in ipairs(said) do
        t.eq(msg, "Not inside a git repository: " .. dir)
      end
    end)
  end,

  ["a missing lazygit or gh prints the line that installs it"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      open(t, dir .. "/notes.txt", 0)
      local opened, said = {}, {}
      with({
        { vim.fn, "executable", only({}) },
        {
          Snacks,
          "lazygit",
          function()
            opened[#opened + 1] = "lazygit"
          end,
        },
        {
          vim,
          "notify",
          function(msg)
            said[#said + 1] = msg
          end,
        },
      }, function()
        G.lazygit()
        G.octo("issue list")
      end)
      t.eq(opened, {}, "lazygit does not open")
      t.eq(package.loaded["octo"], nil, "octo does not load")
      t.eq(said, {
        "lazygit is not installed. Install it with: brew install lazygit",
        "gh is not installed. Install it with: brew install gh, then run: gh auth login",
      })
    end)
  end,

  ["the copied link leaves out the user in the remote's address"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      git(t, dir, "remote", "add", "origin", "https://build_bot@github.com/owner/project.git")
      local sha = git(t, dir, "rev-parse", "HEAD")
      open(t, dir .. "/notes.txt", 0)
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      local copied, said = {}, {}
      with({
        {
          G,
          "clip",
          function(text)
            copied[#copied + 1] = text
          end,
        },
        {
          vim,
          "notify",
          function(msg)
            said[#said + 1] = msg
          end,
        },
        {
          vim.ui,
          "open",
          function()
            error("the browser was opened")
          end,
        },
      }, function()
        G.copy_link()
      end)
      local want = ("https://github.com/owner/project/blob/%s/notes.txt#L4-L4"):format(sha)
      t.eq(copied, { want }, "the link to line 4 at its commit, without build_bot")
      t.eq(said, { "Copied " .. want }, "and it says what it copied")
      local ssh = "git@github.com:owner/project.git"
      t.eq(G.scrub(ssh), ssh, "an ssh address is left alone")
      t.eq(G.scrub("https://github.com/owner/project"), "https://github.com/owner/project", "as is a plain one")
    end)
  end,

  ["Diff View opens in a tab of its own and closes with :DiffviewClose"] = function(t)
    tidy(function()
      local G = require("ach.git")
      local dir = repo(t)
      vim.fn.writefile(lines({ [3] = true }), dir .. "/notes.txt")
      open(t, dir .. "/notes.txt", 1)
      local tabs = #vim.api.nvim_list_tabpages()
      G.diffview("open")
      local shown = vim.wait(5000, function()
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(b):match("^diffview://") then
            return true
          end
        end
        return false
      end, 50)
      t.ok(shown, "a diffview buffer appears")
      t.eq(#vim.api.nvim_list_tabpages(), tabs + 1, "in one new tab")
      vim.cmd("DiffviewClose")
      local closed = vim.wait(2000, function()
        return #vim.api.nvim_list_tabpages() == tabs
      end, 50)
      t.ok(closed, "and :DiffviewClose takes the tab away")
    end)
  end,

  ["Neogit opens in a tab at the repository's top, with diffview and snacks"] = function(t)
    tidy(function()
      local plugin = require("lazy.core.config").plugins["neogit"]
      t.ok(plugin ~= nil, "Neogit is in the plugin list")
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      t.eq(opts.kind, "tab", "in a tab")
      t.eq(opts.graph_style, "unicode", "with a graph drawn in box characters")
      t.eq(opts.integrations, { diffview = true, snacks = true }, "using diffview and the snacks picker")
      local dir = repo(t)
      vim.fn.mkdir(dir .. "/sub", "p")
      vim.fn.writefile({ "deep" }, dir .. "/sub/deep.txt")
      vim.cmd.edit(vim.fn.fnameescape(dir .. "/sub/deep.txt"))
      local got
      with({
        {
          package.loaded,
          "neogit",
          {
            open = function(o)
              got = o
            end,
          },
        },
      }, function()
        require("ach.git").neogit()
      end)
      t.eq(got, { cwd = dir }, "at the repository's top")
    end)
  end,

  ["octo waits for its command and lists through the snacks picker"] = function(t)
    local plugin = require("lazy.core.config").plugins["octo.nvim"]
    t.ok(plugin ~= nil, "octo is in the plugin list")
    local opts = require("lazy.core.plugin").values(plugin, "opts", false)
    t.eq(opts.picker, "snacks", "lists in the snacks picker")
    t.eq(opts.enable_builtin, true, "a bare :Octo offers a menu of its commands")
    t.eq(plugin._.loaded, nil, "not loaded at startup")
  end,

  ["every git key is set, with a description that has an icon"] = function(t)
    local keys = {
      { "<leader>gg", "n" },
      { "<leader>gG", "n" },
      { "<leader>gn", "n" },
      { "<leader>gD", "n" },
      { "<leader>gF", "n" },
      { "<leader>gs", "n" },
      { "<leader>gS", "n" },
      { "<leader>gd", "n" },
      { "<leader>gl", "n" },
      { "<leader>gL", "n" },
      { "<leader>gf", "n" },
      { "<leader>gb", "n" },
      { "<leader>gc", "n" },
      { "<leader>gB", "n" },
      { "<leader>gB", "x" },
      { "<leader>gY", "n" },
      { "<leader>gY", "x" },
      { "<leader>gi", "n" },
      { "<leader>gp", "n" },
    }
    for _, k in ipairs(keys) do
      local m = vim.fn.maparg(k[1], k[2], false, true)
      t.ok(m.desc ~= nil, ("%s is set in mode %s"):format(k[1], k[2]))
      t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
    end
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_git`
Expected: `0 passed, 13 failed, 0 need a person, 0 skipped`, exit 1. The five tests that open a file wait the full five seconds for gitsigns and fail on `gitsigns counts … changed lines`, since gitsigns is not installed. The key tests fail on keys that are not set, and the rest on `module 'ach.git' not found` or on Neogit and octo missing from the plugin list.

- [ ] **Write the git module**

`lua/ach/git.lua`:

```lua
-- Git: the guards in front of every git key, gitsigns' options and its keys
-- for one change at a time, and the browse link with any user or token
-- removed. Each key finds the repository first, and each program is checked
-- before it is started, so a key pressed in the wrong place prints one line
-- and opens nothing.
local I = require("ach.icons")
local need = require("ach.need")
local util = require("ach.util")

local M = {}

local function nowhere(dir)
  vim.notify(("Not inside a git repository: %s"):format(dir), vim.log.levels.WARN)
end

-- The top of the repository holding the current buffer. A buffer that is not
-- a file, such as the dashboard, uses the working folder instead. Prints why
-- and returns nil when there is no repository.
---@return string?
function M.repo()
  local root = util.git_root(0)
  if not root then
    local name = vim.api.nvim_buf_get_name(0)
    nowhere(name ~= "" and vim.bo.buftype == "" and vim.fs.dirname(name) or assert(vim.uv.cwd()))
  end
  return root
end

-- The folder a git action runs in: the repository's top, as repo() finds it,
-- or with "cwd" the working folder itself, when it is inside a repository.
---@param where? "cwd"
---@return string?
function M.where(where)
  if where ~= "cwd" then
    return M.repo()
  end
  local cwd = assert(vim.uv.cwd())
  if vim.fs.root(cwd, ".git") then
    return cwd
  end
  nowhere(cwd)
end

---@param where? "cwd"
function M.lazygit(where)
  if not need.have("lazygit") then
    return
  end
  local cwd = M.where(where)
  if cwd then
    Snacks.lazygit({ cwd = cwd })
  end
end

function M.neogit()
  local root = M.repo()
  if root then
    require("neogit").open({ cwd = root })
  end
end

-- "open" shows every uncommitted change; "file" the current file's history.
---@param what "open"|"file"
function M.diffview(what)
  local root = M.repo()
  if not root then
    return
  end
  if what ~= "file" then
    vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(root))
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("This buffer is not a file, so it has no history", vim.log.levels.WARN)
    return
  end
  vim.cmd(("DiffviewFileHistory -C%s %s"):format(vim.fn.fnameescape(root), vim.fn.fnameescape(file)))
end

-- octo works on the working folder's repository, through gh.
---@param args string such as "issue list"
function M.octo(args)
  if need.have("gh") and M.where("cwd") then
    vim.cmd("Octo " .. args)
  end
end

---@param source string a snacks picker, such as "git_status"
---@param where? "cwd"
function M.pick(source, where)
  local cwd = M.where(where)
  if cwd then
    Snacks.picker[source]({ cwd = cwd })
  end
end

-- A field rather than a local, so the tests can keep the clipboard untouched.
function M.clip(text)
  vim.fn.setreg("+", text)
end

-- A remote's address can carry a user name or a token, as
-- https://build_bot@github.com/owner/project.git does, and snacks keeps it in
-- the link it builds. This removes everything between the scheme and the @.
-- An ssh address such as git@github.com:owner/project.git has no scheme and is
-- left as it is; snacks turns those into plain https links itself.
---@param url string
---@return string
function M.scrub(url)
  return (url:gsub("^(%a[%w+.-]*://)[^/@]*@", "%1"))
end

-- Copies a link to the current line, or the selected lines, pinned to the
-- file's last commit so it still points at the same text after later edits.
-- notify = false stops snacks printing the link before it is scrubbed.
function M.copy_link()
  if not M.repo() then
    return
  end
  Snacks.gitbrowse({
    what = "permalink",
    notify = false,
    open = function(url)
      url = M.scrub(url)
      M.clip(url)
      vim.notify("Copied " .. url, vim.log.levels.INFO)
    end,
  })
end

-- Opens the current file and line, or the selected lines, in the browser.
function M.browse()
  if not M.repo() then
    return
  end
  Snacks.gitbrowse({
    notify = false,
    open = function(url)
      vim.ui.open(M.scrub(url))
    end,
  })
end

function M.gitsigns_opts()
  local g = I.gitsigns
  return {
    signs = {
      add = { text = g.add },
      change = { text = g.change },
      delete = { text = g.delete },
      topdelete = { text = g.topdelete },
      changedelete = { text = g.changedelete },
      untracked = { text = g.untracked },
    },
    -- Staged changes keep the same shapes; gitsigns colours them more dimly.
    signs_staged = {
      add = { text = g.add },
      change = { text = g.change },
      delete = { text = g.delete },
      topdelete = { text = g.topdelete },
      changedelete = { text = g.changedelete },
    },
    attach_to_untracked = true,
    current_line_blame_opts = { delay = 300 },
    on_attach = M.on_attach,
  }
end

-- The keys for one change at a time, set on each buffer gitsigns attaches to.
---@param buf integer
function M.on_attach(buf)
  local gs = require("gitsigns")
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
  end
  -- In a diff window, ]c and [c already move between differences.
  map("n", "]h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      gs.nav_hunk("next")
    end
  end, "Next Hunk")
  map("n", "[h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      gs.nav_hunk("prev")
    end
  end, "Prev Hunk")
  map("n", "]H", function()
    gs.nav_hunk("last")
  end, "Last Hunk")
  map("n", "[H", function()
    gs.nav_hunk("first")
  end, "First Hunk")
  map("n", "<leader>ghs", function()
    gs.stage_hunk()
  end, "Stage or Unstage Hunk")
  map("x", "<leader>ghs", function()
    gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Stage or Unstage Hunk")
  map("n", "<leader>ghr", function()
    gs.reset_hunk()
  end, "Reset Hunk")
  map("x", "<leader>ghr", function()
    gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, "Reset Hunk")
  map("n", "<leader>ghS", function()
    gs.stage_buffer()
  end, "Stage Buffer")
  map("n", "<leader>ghR", function()
    gs.reset_buffer()
  end, "Reset Buffer")
  map("n", "<leader>ghp", function()
    gs.preview_hunk_inline()
  end, "Preview Hunk Inline")
  map("n", "<leader>ghb", function()
    gs.blame_line({ full = true })
  end, "Blame Line")
  map("n", "<leader>ghB", function()
    gs.blame()
  end, "Blame Buffer")
  map("n", "<leader>ghd", function()
    gs.diffthis()
  end, "Diff This")
  map("n", "<leader>ghD", function()
    gs.diffthis("~")
  end, "Diff This ~")
  map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select Hunk")
end

-- Space u G and Space u b. Called once gitsigns is set up, so the keys exist
-- from the first file opened on.
function M.toggles()
  local gs = require("gitsigns")
  local function config()
    return require("gitsigns.config").config
  end
  I.toggle(Snacks.toggle({
    id = "git_signs",
    name = "Git Signs",
    get = function()
      return config().signcolumn
    end,
    set = function(state)
      gs.toggle_signs(state)
    end,
  })):map("<leader>uG")
  I.toggle(Snacks.toggle({
    id = "git_blame_line",
    name = "Git Blame Line",
    get = function()
      return config().current_line_blame
    end,
    set = function(state)
      gs.toggle_current_line_blame(state)
    end,
  })):map("<leader>ub")
end

return M
```

- [ ] **Write the plugin specs**

`lua/ach/plugins/git.lua`:

```lua
-- Git: gitsigns for the change bars and the keys for one change at a time,
-- Neogit for staging and committing in a tab, diffview for side-by-side diffs
-- and file history, octo for GitHub, and lazygit, the browse link and the git
-- pickers from snacks. Every key calls ach.git, which checks for a repository
-- and for the program first.

-- A key's action: the ach.git function called name, given a and b.
local function git(name, a, b)
  return function()
    require("ach.git")[name](a, b)
  end
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      return require("ach.git").gitsigns_opts()
    end,
    config = function(_, opts)
      require("gitsigns").setup(opts)
      require("ach.git").toggles()
    end,
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = { "sindrets/diffview.nvim" },
    opts = {
      kind = "tab",
      graph_style = "unicode",
      integrations = { diffview = true, snacks = true },
    },
    keys = {
      { "<leader>gn", git("neogit"), desc = "Neogit (Root Dir)" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
      -- A merge conflict shows the two sides above and the result below.
      view = { merge_tool = { layout = "diff3_mixed" } },
    },
    keys = {
      { "<leader>gD", git("diffview", "open"), desc = "Diff View (Root Dir)" },
      { "<leader>gF", git("diffview", "file"), desc = "File History (Diff View)" },
    },
  },
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    -- Reopening an octo:// buffer, from the jump list or a session, loads it.
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { picker = "snacks", enable_builtin = true },
    keys = {
      { "<leader>gi", git("octo", "issue list"), desc = "GitHub Issues" },
      { "<leader>gp", git("octo", "pr list"), desc = "GitHub Pull Requests" },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", git("lazygit"), desc = "Lazygit (Root Dir)" },
      { "<leader>gG", git("lazygit", "cwd"), desc = "Lazygit (cwd)" },
      { "<leader>gs", git("pick", "git_status"), desc = "Git Status" },
      { "<leader>gS", git("pick", "git_stash"), desc = "Git Stash" },
      { "<leader>gd", git("pick", "git_diff"), desc = "Git Diff (hunks)" },
      { "<leader>gl", git("pick", "git_log"), desc = "Git Log (Root Dir)" },
      { "<leader>gL", git("pick", "git_log", "cwd"), desc = "Git Log (cwd)" },
      { "<leader>gf", git("pick", "git_log_file"), desc = "Git File History" },
      { "<leader>gb", git("pick", "git_log_line"), desc = "Git Line History" },
      { "<leader>gc", git("pick", "git_branches"), desc = "Git Branches" },
      { "<leader>gB", git("browse"), mode = { "n", "x" }, desc = "Git Browse (open)" },
      { "<leader>gY", git("copy_link"), mode = { "n", "x" }, desc = "Git Browse (copy link)" },
    },
  },
}
```

- [ ] **List lazygit and gh**

In `lua/ach/need.lua`, add above `-- Programs added by later tasks go above this line.`:

```lua
  { name = "lazygit", brew = "brew install lazygit", purpose = "Lazygit on Space g g and Space g G" },
  {
    name = "gh",
    brew = "brew install gh, then run: gh auth login",
    purpose = "GitHub issues and pull requests on Space g i and Space g p",
  },
```

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add above `-- Keys added by later tasks go above this line.`:

```lua
  -- Git: gitsigns' keys for one change at a time
  ["Next Hunk"] = { "git.hunk", "orange" },
  ["Prev Hunk"] = { "git.hunk", "orange" },
  ["Last Hunk"] = { "git.hunk", "orange" },
  ["First Hunk"] = { "git.hunk", "orange" },
  ["Stage or Unstage Hunk"] = { "git.hunk_stage", "orange" },
  ["Reset Hunk"] = { "git.hunk_reset", "orange" },
  ["Stage Buffer"] = { "git.staged", "orange" },
  ["Reset Buffer"] = { "git.hunk_reset", "orange" },
  ["Preview Hunk Inline"] = { "git.diff", "orange" },
  ["Blame Line"] = { "git.blame", "orange" },
  ["Blame Buffer"] = { "git.blame", "orange" },
  ["Diff This"] = { "git.diff", "orange" },
  ["Diff This ~"] = { "git.diff", "orange" },
  ["Select Hunk"] = { "textobj.inside", "cyan" },
  -- Git: lazygit, Neogit, diffview, octo and the snacks pickers
  ["Lazygit (Root Dir)"] = { "git.lazygit", "orange" },
  ["Lazygit (cwd)"] = { "git.lazygit", "orange" },
  ["Neogit (Root Dir)"] = { "git.git", "orange" },
  ["Diff View (Root Dir)"] = { "git.diff", "orange" },
  ["File History (Diff View)"] = { "git.log", "orange" },
  ["Git Status"] = { "git.modified", "orange" },
  ["Git Stash"] = { "git.stash", "orange" },
  ["Git Diff (hunks)"] = { "git.hunk", "orange" },
  ["Git Log (Root Dir)"] = { "git.log", "orange" },
  ["Git Log (cwd)"] = { "git.log", "orange" },
  ["Git File History"] = { "git.commit", "orange" },
  ["Git Line History"] = { "git.log", "orange" },
  ["Git Branches"] = { "git.branch", "orange" },
  ["Git Browse (open)"] = { "actions.open_external", "orange" },
  ["Git Browse (copy link)"] = { "actions.link", "orange" },
  ["GitHub Issues"] = { "git.issue", "orange" },
  ["GitHub Pull Requests"] = { "git.pull_request", "orange" },
```

And above `-- Toggles added by later tasks go above this line.`:

```lua
  git_signs = "git.hunk",
  git_blame_line = "git.blame",
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: exit 0. `lazy-lock.json` gains five lines: `gitsigns.nvim`, `neogit`, `diffview.nvim`, `octo.nvim` and `plenary.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the thirteen `test_git` tests among them, exit 0. The foundation's `every key which-key can show has an icon from the database` passes too, which shows every new description has its line in `M.keys`.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/git.lua lua/ach/plugins/git.lua tests/test_git.lua
git commit --only lua/ach/git.lua lua/ach/plugins/git.lua tests/test_git.lua lua/ach/need.lua lua/ach/icons.lua lazy-lock.json -m "feat(git): change bars and hunk keys, lazygit, Neogit, diffview and octo, each behind a repository check"
```

---

### Task: Claude Code

**Files:**
- Create: `lua/ach/claude.lua`, `lua/ach/plugins/claude.lua`
- Modify: `lua/ach/plugins/ui.lua`, whose edgy `right` edge gains the panel's view in front of Grug Far's; `lua/ach/icons.lua`, which gains a line in `M.keys` for each key below; `lua/ach/need.lua`, which gains claude; `lazy-lock.json`, which gains claudecode.nvim
- Test: `tests/test_claude.lua`

**Interfaces:**
- Consumes: `require("ach.need").have(name)` from the Programs task; `require("ach.icons")` (`key(desc)`, and the glyphs in `M.claude`: `claude`, `focus`, `resume`, `continue`, `model`, `add_buffer`, `send`, `add_file`, `accept` and `deny`); the foundation's which-key group `<leader>a`, named claude; the foundation's edgy spec in `lua/ach/plugins/ui.lua`, whose loop appends a generic `snacks_terminal` view to every edge; the global `Snacks` and its terminal module, which claudecode opens the panel with; the status bar's `M.claude()`, which reads `package.loaded["ach.claude"]` and calls its `status()`; `scripts/check`, which points `CLAUDE_CONFIG_DIR` at a scratch folder; and `tests/run.lua`, which fires UIEnter in a headless run so VeryLazy plugins load.
- Produces: `require("ach.claude")`: `status(): "connected"|"waiting"|"off"`; `opts(): table`, claudecode's setup table; `view(): table`, the panel's edgy view; and `cmd(command: string)`, which runs a claudecode command once the `claude` program is found.

The foundation leaves `Space a` as an empty menu named claude, and a Claude tile in the status bar that stays blank. This task fills both with claudecode.nvim, the plugin Anthropic's Claude Code connects to in the same way it connects to VS Code. It does two things. It runs the `claude` program in a panel on the right of the editor, and it opens a small server that Claude Code talks to while it works. Through that server Claude sees which file is open and what is selected, and when it wants to change a file it shows the change as a side-by-side diff in Neovim for the owner to accept or reject, rather than writing the file behind the editor's back.

The server is a WebSocket server: a program that waits on a numbered port for another program to connect, then keeps the connection open so either side can send a message at any time. When it starts, claudecode writes a lock file, `~/.claude/ide/<port>.lock`, holding the port, the folder being edited and a token, which is 32 random hexadecimal characters. Claude Code, started anywhere on the Mac, reads that folder to find editors, and its `/ide` command lists them. So a Claude Code session started in another Ghostty tab can connect to this Neovim too, not only the one in the panel.

Two guards keep anyone else off that server. The first is the address. The server listens on `127.0.0.1`, the address a Mac uses to talk to itself, so no other machine on the network can reach it. A test reads the bound address back from `lsof`, the program that lists what each process has open. The second is the token. Any program on this Mac can reach `127.0.0.1`, so the server also refuses a connection that does not send the token from the lock file. The lock file can be read by the owner alone, because the folder's permissions are 700 and the file's are 600, which in both cases means the owner may read and write and nobody else may do anything. A program running as another user cannot read the token, and a web page cannot send it at all, because a browser does not let a page add that header. A test sends a wrong token and checks for the refusal, then sends the right one and checks that it is let in.

A Neovim nobody can see starts no server. Neovim run by a script, by `nvim --headless` or by this test suite has no screen, and a server there would be offered to Claude Code as an editor to connect to, with no one to watch the diffs it opens. `opts()` turns the automatic start off whenever Neovim has no screen, which `vim.api.nvim_list_uis()` reports as an empty list, and a test checks that the suite's own Neovim writes no lock file. A Neovim in Ghostty always has a screen by the time the server would start, because Neovim waits for its screen to attach before it reads the configuration.

The panel needs one fix to the foundation's docked panes. edgy, the plugin that docks panes to the edges, makes a side bar as wide as the widest view in it, and counts a view that names no width as the bar's default of 30 columns. The foundation's loop gives every edge a generic view for any snacks terminal, and that view names a height but no width. Left alone, it would claim the Claude panel and squeeze it into 30 columns. `view()` is a view of the panel's own, 40 percent of the screen wide, which knows the panel by a mark claudecode puts on its window. It goes first in the `right` list, because edgy gives a window to the first view that matches it. claudecode closes the panel's window when it is hidden and builds a new one when it is shown again, and it puts the mark back on the new window, so the panel keeps its width after a hide. A test checks the width alone, beside Grug Far, and after a hide and a show.

The status bar's Claude tile is a four-pointed star. It is violet while Claude Code is connected, dim while the server waits with nobody connected, and absent when no server runs. `status()` reads claudecode only when something else has loaded it, because the bar redraws often and a check that loaded the plugin would undo its lazy loading.

Claude starts at the top of the current file's repository, as `claude` started from a terminal at that folder would, so it sees the repository's `CLAUDE.md` and the whole project rather than one subfolder. A key pressed with the `claude` program missing prints its Homebrew line and opens nothing.

| Key | Description | What it does |
| --- | --- | --- |
| `Space a c` | Toggle Claude | Opens Claude Code in a panel on the right, or hides the panel; Claude keeps running while it is hidden |
| `Space a f` | Focus Claude | Moves the cursor into the panel, opening it first if needed; pressed inside the panel, hides it |
| `Space a r` | Resume Claude | Opens Claude with a list of past conversations, to pick one and carry on |
| `Space a C` | Continue Claude | Opens Claude in the most recent conversation |
| `Space a m` | Select Claude Model | Asks which model to use, then opens Claude with it |
| `Space a b` | Add Buffer to Claude | Puts the current file into Claude's prompt as an @ mention |
| `Space a s` | Send to Claude | In visual mode: sends the selected lines to Claude, as a reference to the file and those lines |
| `Space a s` | Add File to Claude | In oil or the snacks file explorer: adds the file under the cursor, or every selected file, to Claude's prompt |
| `Space a a` | Accept Diff | Accepts the change Claude proposed in the side-by-side diff |
| `Space a d` | Deny Diff | Rejects the change Claude proposed and closes the diff |

`Space a s` is one key with two jobs. In a file it takes a selection, and in a file list it takes the file. The keys claudecode sets inside its own panel and diff windows are its own and are not listed, as the Global Constraints say.

- [ ] **Write the failing tests**

`tests/test_claude.lua`:

```lua
-- Claude Code. No test starts the claude program. The server tests start
-- claudecode's server and talk to it through a client written here, which
-- sends the request Claude Code sends. The panel test runs `sleep 60` in the
-- panel in claude's place. scripts/check points CLAUDE_CONFIG_DIR at a scratch
-- folder, so every lock file lands there and never in ~/.claude/ide.
local I = require("ach.icons")

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level)
        said[#said + 1] = { msg = msg, level = level }
      end,
    },
  }, body)
  return said
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- Starts claudecode's server, runs body with its port, and stops the server
-- again, even when body fails.
local function serving(t, body)
  local C = require("claudecode")
  local started, port = C.start(false)
  t.ok(started, "the server starts: " .. tostring(port))
  local ok, err = pcall(body, port)
  local stopped = C.stop()
  if not ok then
    error(err, 0)
  end
  t.eq(stopped, true, "the server stops")
end

-- Connects to the server on port and asks to turn the connection into a
-- WebSocket, sending token as Claude Code sends it. Waits up to three seconds
-- for the reply to contain want. Returns the reply and the connection, which
-- the caller closes.
local function ask(port, token, want)
  local tcp = assert(vim.uv.new_tcp())
  local reply = ""
  tcp:connect("127.0.0.1", port, function(err)
    if err then
      return
    end
    tcp:read_start(function(_, chunk)
      if chunk then
        reply = reply .. chunk
      end
    end)
    tcp:write(table.concat({
      "GET / HTTP/1.1",
      "Host: 127.0.0.1:" .. port,
      "Upgrade: websocket",
      "Connection: Upgrade",
      -- The sample key from the WebSocket standard, RFC 6455. The server
      -- checks that a key is 24 characters long, and this one is.
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
      "Sec-WebSocket-Version: 13",
      "x-claude-code-ide-authorization: " .. token,
      "",
      "",
    }, "\r\n"))
  end)
  vim.wait(3000, function()
    return reply:find(want, 1, true) ~= nil
  end, 20)
  return reply, tcp
end

-- Closes a connection ask opened.
local function hang_up(tcp)
  if not tcp:is_closing() then
    tcp:close()
  end
end

-- The window edgy has docked under the view called title, or nil.
local function docked_as(title)
  local edgy = require("edgy.editor")
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local e = edgy.get_win(win)
    if e and e.view.title == title then
      return win
    end
  end
end

-- The width of the docked Claude Code panel, or nil when it is not docked.
local function panel_width()
  local win = docked_as("Claude Code")
  return win and vim.api.nvim_win_get_width(win)
end

return {
  ["a headless Neovim starts no Claude Code server and writes no lock file"] = function(t)
    t.eq(#vim.api.nvim_list_uis(), 0, "the suite runs with no screen")
    local C = package.loaded["claudecode"]
    t.ok(C ~= nil, "claudecode has loaded, as it does once Neovim is idle")
    t.eq(C.state.server, nil, "but it started no server")
    local dir = vim.env.CLAUDE_CONFIG_DIR
    t.ok(
      dir ~= nil and dir ~= "" and not vim.startswith(dir, vim.env.HOME .. "/.claude"),
      "scripts/check gives Claude Code a scratch folder"
    )
    t.eq(vim.fn.glob(dir .. "/ide/*.lock", false, true), {}, "and no lock file was written there")
    t.eq(require("ach.claude").opts().auto_start, false, "because the automatic start is off with no screen")
  end,

  ["the status bar's check never loads claudecode"] = function(t)
    local A = require("ach.claude")
    with({ { package.loaded, "claudecode", nil } }, function()
      t.eq(A.status(), "off", "off while claudecode is not loaded")
      t.eq(package.loaded["claudecode"], nil, "and asking did not load it")
    end)
  end,

  ["the server listens on 127.0.0.1 alone and keeps a private lock file until it stops"] = function(t)
    local C = require("claudecode")
    local dir = vim.env.CLAUDE_CONFIG_DIR .. "/ide"
    local file
    serving(t, function(port)
      -- Every socket this Neovim listens on at port, one address per line,
      -- each line starting with n. -a makes lsof require all three conditions.
      local argv = { "lsof", "-nP", "-a", "-p", tostring(vim.fn.getpid()), "-iTCP:" .. port, "-sTCP:LISTEN", "-Fn" }
      local r = vim.system(argv, { text = true }):wait()
      local names = {}
      for line in vim.gsplit(r.stdout or "", "\n", { trimempty = true }) do
        if line:sub(1, 1) == "n" then
          names[#names + 1] = line
        end
      end
      t.eq(names, { "n127.0.0.1:" .. port }, "one listening socket, on the address the Mac uses for itself")

      file = ("%s/%d.lock"):format(dir, port)
      t.eq(("%o"):format(vim.uv.fs_stat(dir).mode % 512), "700", "the lock folder is the owner's alone")
      t.eq(("%o"):format(vim.uv.fs_stat(file).mode % 512), "600", "and so is the lock file")

      local lock = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
      t.eq(lock.pid, vim.fn.getpid(), "the lock file names this Neovim")
      t.eq(lock.ideName, "Neovim")
      t.eq(lock.transport, "ws")
      t.eq(type(lock.workspaceFolders), "table", "and the folders being edited")
      t.ok(
        type(lock.authToken) == "string" and #lock.authToken == 32 and lock.authToken:match("^%x+$") ~= nil,
        "the token is 32 hexadecimal characters"
      )
      t.eq(lock.authToken, C.state.auth_token, "and it is the token the server checks")
    end)
    t.eq(vim.uv.fs_stat(file), nil, "stopping the server removes the lock file")
  end,

  ["the server refuses the wrong token, lets in the right one, and the status follows"] = function(t)
    local A = require("ach.claude")
    t.eq(A.status(), "off", "off before the server starts")
    serving(t, function(port)
      t.eq(A.status(), "waiting", "waiting once the server listens")

      local reply, tcp = ask(port, string.rep("0", 32), "Invalid authentication token")
      hang_up(tcp)
      t.eq(vim.split(reply, "\r\n")[1], "HTTP/1.1 400 Bad Request", "a wrong token is refused")
      t.ok(
        reply:find("Bad WebSocket upgrade request: Invalid authentication token", 1, true) ~= nil,
        "and the refusal says why"
      )
      t.eq(A.status(), "waiting", "a refused connection does not count as Claude")

      reply, tcp = ask(port, require("claudecode").state.auth_token, "101 Switching Protocols")
      local connected = vim.wait(3000, function()
        return A.status() == "connected"
      end, 20)
      hang_up(tcp)
      t.eq(vim.split(reply, "\r\n")[1], "HTTP/1.1 101 Switching Protocols", "the right token is let in")
      t.ok(connected, "and the status bar shows Claude as connected")
    end)
    t.eq(A.status(), "off", "off again once the server stops")
  end,

  ["the panel takes 40 percent of the width alone, beside Grug Far, and after a hide"] = function(t)
    with({ { vim.o, "columns", 200 } }, function()
      tidy(function()
        local provider = require("claudecode.terminal.snacks")
        -- The panel's own settings, except that it stays in normal mode, so
        -- the test never sits in the terminal waiting for keys.
        local config = vim.tbl_extend("force", require("ach.claude").opts().terminal, { auto_insert = false })
        provider.open("sleep 60", {}, config, false)
        t.ok(vim.wait(3000, function()
          return panel_width() == 80
        end, 20), "alone on the right, the panel is 80 of 200 columns, not 30")

        require("grug-far").open()
        t.ok(vim.wait(3000, function()
          return docked_as("Grug Far") ~= nil and panel_width() == 80
        end, 20), "with Grug Far docked beside it, still 80")

        provider.simple_toggle("sleep 60", {}, config)
        t.ok(vim.wait(3000, function()
          return docked_as("Claude Code") == nil
        end, 20), "the first toggle hides the panel")
        provider.simple_toggle("sleep 60", {}, config)
        t.ok(vim.wait(3000, function()
          return panel_width() == 80
        end, 20), "the second shows it again, docked at 80")

        provider.close()
      end)
    end)
  end,

  ["every Space a key is set, with a description that has an icon"] = function(t)
    local keys = {
      { "<leader>ac", "n" },
      { "<leader>af", "n" },
      { "<leader>ar", "n" },
      { "<leader>aC", "n" },
      { "<leader>am", "n" },
      { "<leader>ab", "n" },
      { "<leader>as", "x" },
      { "<leader>aa", "n" },
      { "<leader>ad", "n" },
    }
    for _, k in ipairs(keys) do
      local m = vim.fn.maparg(k[1], k[2], false, true)
      t.ok(m.desc ~= nil, ("%s is set in mode %s"):format(k[1], k[2]))
      t.ok(I.key(m.desc) ~= nil, ("%s, %q, has a line in M.keys"):format(k[1], tostring(m.desc)))
    end
    tidy(function()
      vim.cmd.enew()
      vim.bo.filetype = "snacks_picker_list"
      local m = vim.fn.maparg("<leader>as", "n", false, true)
      t.eq(m.buffer, 1, "in the file explorer, Space a s belongs to the buffer")
      t.eq(m.desc, "Add File to Claude", "and adds the file rather than a selection")
      t.ok(I.key(m.desc) ~= nil, "and has a line in M.keys")
    end)
  end,

  ["with no claude program, a Space a key prints the Homebrew line and opens nothing"] = function(t)
    tidy(function()
      local wins = #vim.api.nvim_list_wins()
      local said = notices(function()
        with({ { vim.fn, "executable", only({}) } }, function()
          press("<leader>ac")
        end)
      end)
      t.eq(
        vim.tbl_map(function(n)
          return n.msg
        end, said),
        { "Claude Code is not installed. Install it with: brew install --cask claude-code" },
        "one line, saying what to run"
      )
      t.eq(#vim.api.nvim_list_wins(), wins, "and no panel opened")
    end)
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_claude`
Expected: `0 passed, 7 failed, 0 need a person, 0 skipped`, exit 1. The headless test fails on `claudecode has loaded`, since the plugin is not installed, and the server tests fail on `module 'claudecode' not found`. The status test fails on `module 'ach.claude' not found`, the panel test on `module 'claudecode.terminal.snacks' not found`, and the two key tests on `<leader>ac is set in mode n` and `no key <leader>ac in mode n`.

- [ ] **Write the claude module**

`lua/ach/claude.lua`:

```lua
-- Claude Code: what the status bar shows, claudecode's options, and the
-- panel's place among the docked panes. claudecode opens a WebSocket server on
-- 127.0.0.1 and writes its port and a token to a lock file only the owner can
-- read; Claude Code finds the file, connects with the token, and can then see
-- the selection and propose changes as diffs. With no screen, as in a script
-- or the tests, no server starts and no lock file is written.
local need = require("ach.need")

local M = {}

-- "connected" while Claude Code is connected, "waiting" while the server
-- listens with nobody connected, and "off" otherwise. The status bar calls
-- this on every redraw, so it reads claudecode only once something else has
-- loaded it.
---@return "connected"|"waiting"|"off"
function M.status()
  local cc = package.loaded["claudecode"]
  if not (cc and cc.state and cc.state.server) then
    return "off"
  end
  return cc.is_claude_connected() and "connected" or "waiting"
end

-- claudecode's setup table.
---@return table
function M.opts()
  return {
    -- A Neovim nobody can see gets no server, so Claude Code never offers it.
    auto_start = #vim.api.nvim_list_uis() > 0,
    terminal = {
      provider = "snacks",
      split_side = "right",
      split_width_percentage = 0.4,
      -- Claude starts at the top of the current file's repository.
      git_repo_cwd = true,
      -- A mark on the panel's window, which its edgy view looks for.
      -- claudecode puts it back on the new window it builds after a hide.
      snacks_win_opts = { w = { ach_claude = true } },
    },
  }
end

-- The panel's view on edgy's right edge. It names its own width because edgy
-- makes a bar as wide as the widest view in it, counting a view that names no
-- width as the bar's default of 30 columns.
---@return table
function M.view()
  return {
    title = "Claude Code",
    ft = "snacks_terminal",
    size = { width = 0.4 },
    filter = function(_, win)
      return vim.w[win].ach_claude == true
    end,
  }
end

-- Runs a claudecode command once the claude program is found. When it is
-- missing, ach.need prints the line that installs it and nothing opens.
---@param command string
function M.cmd(command)
  if need.have("claude") then
    vim.cmd(command)
  end
end

return M
```

- [ ] **Write the plugin spec**

`lua/ach/plugins/claude.lua`:

```lua
-- Claude Code: claudecode.nvim runs the claude program in a panel on the right
-- and opens the server Claude Code connects to. Every key calls ach.claude,
-- which checks for the program first.

-- A key's action: the claudecode command, once the claude program is found.
local function claude(command)
  return function()
    require("ach.claude").cmd(command)
  end
end

return {
  {
    "coder/claudecode.nvim",
    -- Loaded once Neovim is idle, so the server is up before Claude Code looks
    -- for an editor, without slowing the start.
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeAdd",
      "ClaudeCodeClose",
      "ClaudeCodeCloseAllDiffs",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeFocus",
      "ClaudeCodeOpen",
      "ClaudeCodeSelectModel",
      "ClaudeCodeSend",
      "ClaudeCodeSendText",
      "ClaudeCodeStart",
      "ClaudeCodeStatus",
      "ClaudeCodeStop",
      "ClaudeCodeTreeAdd",
    },
    opts = function()
      return require("ach.claude").opts()
    end,
    keys = {
      { "<leader>ac", claude("ClaudeCode"), desc = "Toggle Claude" },
      { "<leader>af", claude("ClaudeCodeFocus"), desc = "Focus Claude" },
      { "<leader>ar", claude("ClaudeCode --resume"), desc = "Resume Claude" },
      { "<leader>aC", claude("ClaudeCode --continue"), desc = "Continue Claude" },
      { "<leader>am", claude("ClaudeCodeSelectModel"), desc = "Select Claude Model" },
      -- ClaudeCodeAdd completes file names, so Neovim turns % into this file's name.
      { "<leader>ab", claude("ClaudeCodeAdd %"), desc = "Add Buffer to Claude" },
      { "<leader>as", claude("ClaudeCodeSend"), mode = "x", desc = "Send to Claude" },
      {
        "<leader>as",
        claude("ClaudeCodeTreeAdd"),
        ft = { "oil", "snacks_picker_list" },
        desc = "Add File to Claude",
      },
      { "<leader>aa", claude("ClaudeCodeDiffAccept"), desc = "Accept Diff" },
      { "<leader>ad", claude("ClaudeCodeDiffDeny"), desc = "Deny Diff" },
    },
  },
}
```

- [ ] **Dock the panel**

In `lua/ach/plugins/ui.lua`, inside edgy's `opts` function, replace:

```lua
        right = {
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
```

with:

```lua
        right = {
          -- The Claude Code panel's view comes first, so it claims the panel
          -- before the generic terminal view the loop below appends, which
          -- names no width and would leave the panel 30 columns wide.
          require("ach.claude").view(),
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
```

- [ ] **List claude**

In `lua/ach/need.lua`, add above `-- Programs added by later tasks go above this line.`:

```lua
  {
    name = "claude",
    label = "Claude Code",
    brew = "brew install --cask claude-code",
    purpose = "the Claude Code panel on Space a",
  },
```

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add above `-- Keys added by later tasks go above this line.`:

```lua
  -- Claude Code
  ["Toggle Claude"] = { "claude.claude", "orange" },
  ["Focus Claude"] = { "claude.focus", "orange" },
  ["Resume Claude"] = { "claude.resume", "orange" },
  ["Continue Claude"] = { "claude.continue", "orange" },
  ["Select Claude Model"] = { "claude.model", "orange" },
  ["Add Buffer to Claude"] = { "claude.add_buffer", "orange" },
  ["Send to Claude"] = { "claude.send", "orange" },
  ["Add File to Claude"] = { "claude.add_file", "orange" },
  ["Accept Diff"] = { "claude.accept", "green" },
  ["Deny Diff"] = { "claude.deny", "red" },
```

This task adds no toggle.

- [ ] **Install the plugin**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: exit 0. `lazy-lock.json` gains one line, `claudecode.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the seven `test_claude` tests among them, exit 0. The foundation's `every key which-key can show has an icon from the database` passes too, which shows every new description has its line in `M.keys`, and the status bar's tests still pass with the real `ach.claude` loaded.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/claude.lua lua/ach/plugins/claude.lua tests/test_claude.lua
git commit --only lua/ach/claude.lua lua/ach/plugins/claude.lua tests/test_claude.lua lua/ach/plugins/ui.lua lua/ach/need.lua lua/ach/icons.lua lazy-lock.json -m "feat(claude): Claude Code in a docked panel on Space a, its server on 127.0.0.1 behind a token, and none when headless"
```

---

### Task: LaTeX

**Files:**
- Create: `lua/ach/latex.lua`, `lua/ach/plugins/latex.lua`
- Modify: `lua/ach/treesitter.lua`, whose `attach` keeps Vim's regex highlighting and VimTeX's indentation for the file types in a new table, `with_regex`; `lua/ach/lsp.lua`, whose keys gain a `not_ft` field so `]]` and `[[` stay VimTeX's in LaTeX; `lua/ach/icons.lua`, which gains a line in `M.keys` for each key below and the latex group in `M.groups`; `lua/ach/need.lua`, which gains latexmk and displayline; `lazy-lock.json`, which gains vimtex
- Test: `tests/test_latex.lua`

**Interfaces:**
- Consumes: `require("ach.need").have(name)` from the Programs task, which prints `<label> is not installed. Install it with: <brew>` and returns false when the program is missing; `require("ach.icons")` (`key(desc)` and `group(name)`); which-key's `add`; the global `Snacks` and its `terminal.open(cmd, opts)`; the languages plan's `require("ach.lsp")`, its `M.keys` and `attach(buf, client)`; the languages plan's `require("ach.treesitter").attach(buf)`, which runs on every FileType; the foundation's `maplocalleader = "\\"` and `o.exrc = true`; `scripts/check`; and `tests/run.lua`, which fires UIEnter so VeryLazy plugins load.
- Produces: `require("ach.latex")`: `globals(): table<string, any>`, VimTeX's settings; `aux_dir(root: string): string`; `build_with(fn?: ach.latex.hook): ach.latex.hook?`, where `ach.latex.hook` is `fun(file: string): (string|string[])?, string?`, which sets a project's build command and returns the one it replaces; `build(buf: integer)`; `run(cmd: string|string[], cwd: string)`; `describe: table<string, string>`, a description for each of VimTeX's actions; and `attach(buf: integer)`. Also `require("ach.treesitter").with_regex: table<string, true>`, and an optional field on an `ach.lsp` key, `not_ft: string[]`.

LaTeX is a language for writing documents. Nearly every paper in mathematics, physics and engineering is written in it, and so are the owner's books. A LaTeX file is plain text with commands in it: `\section{Barrett Reduction}` starts a section, and `$x^2$` is a formula. A program reads the file and writes a PDF. It often has to read the file more than once, because the first reading only learns where each section and figure falls, and only a second reading can print the page numbers in the table of contents. latexmk is the program that works out how many readings a document needs and runs them. It comes with MacTeX, the Mac's LaTeX distribution.

This task adds VimTeX, the LaTeX plugin LazyVim also uses, and joins it to Skim, a free PDF viewer for the Mac that other programs can drive. Four things come of it.

Building. `Space c b` builds the document once. `Backslash l l` starts latexmk in its watching mode, where it rebuilds after every save until it is stopped. Either way latexmk leaves build files behind, such as `main.aux` and `main.log`, and VimTeX is told to put them in a folder of their own under Neovim's cache, `~/.cache/nvim/latex/<project>-<8 characters>`, so they never clutter the project or show up in `git status`. The eight characters come from a hash of the project's path, a short fingerprint that differs for two projects that happen to share a name. Only the PDF and `main.synctex.gz` stay beside the main file, the second because Skim looks for it next to the PDF; it is the file that records which line of the source produced which spot on the page. A project whose own `.latexmkrc` names a different folder keeps its own, because VimTeX gives that file the last word.

Forward search. `Backslash l v` opens the PDF in Skim at the line under the cursor and draws Skim's reading bar, a tinted band across that line, so the eye lands on it. VimTeX does this by running `osascript`, the Mac's program for scripting other applications, with a short script in JavaScript. After every successful build Skim reloads the PDF and moves to the cursor's line again, so the PDF follows the writing.

Inverse search runs the other way. Command-Shift-click a word in Skim, and Neovim's cursor moves to the line that produced it. Skim cannot reach into a running Neovim, so it starts a second Neovim that nobody sees, running the command `VimtexInverseSearch` with the line and file clicked. That Neovim reads `~/.cache/vimtex/nvim_servernames.log`, a list VimTeX keeps of the address of every Neovim that has opened a LaTeX file, sends the line and file to each, and quits. A Neovim working on that document moves its cursor there, and the others ignore the message. The addresses of Neovims that have since quit are dropped from the list the next time a LaTeX file opens. Skim's half of this, its preference naming `/opt/homebrew/bin/nvim` with the arguments `--headless -c "VimtexInverseSearch %line '%file'"`, is set by the Mac's own setup, because it lives in Skim's settings rather than in this repository. VimTeX is loaded when Neovim starts, not when a LaTeX file opens, because that invisible Neovim opens no LaTeX file and still needs the command.

Highlighting. The languages plan colours every file with tree-sitter, a library that parses a file into a tree of its parts, and starting tree-sitter turns off Vim's older highlighting, which works by matching regular expressions, patterns written over the text. VimTeX needs the older kind. It reads it to tell a formula from the text around it, and four features depend on that: the `i $` and `a $` text objects, the `d s $`, `c s $` and `t s $` keys, the symbols drawn in place of commands such as `\alpha`, and the insert-mode shortcuts, most of which work only inside a formula. So for LaTeX the tree-sitter code now turns the older highlighting back on after starting tree-sitter, which is how Neovim's own help says to have both, and leaves indentation to VimTeX, whose rules know LaTeX's environments. Tree-sitter's colours are drawn over the older ones, so a LaTeX file looks like every other language.

The build hook. The owner's books are not built by latexmk alone. Each has a `scripts/build.sh` that runs latexmk with its own settings and tidies afterwards, and a one-off document goes through a general build script. `build_with` lets a project give `Space c b` its own command. A project calls it from a `.nvim.lua` file, which Neovim runs at start because the foundation turns on its `exrc` option. Neovim asks before running such a file the first time, and again whenever the file changes, so a cloned repository cannot run code just by shipping one. The function receives the main file's path and returns the command and the folder to run it in, and the command runs in a terminal along the bottom of the screen, which stays open when the build ends so its output can be read. Returning nothing falls back to latexmk, and a hook that fails prints why and runs nothing. The private repository that holds those books writes its own `.nvim.lua`, which stays private.

Keys. VimTeX sets its own keys on LaTeX buffers, a menu of them under `Backslash l` and editing keys such as `d s e`, and sets them without descriptions. `attach` sets each one again with a description from `describe`, so which-key shows it with its icon, like every other key. Three choices go beyond VimTeX's defaults. `K` stays the language server's hover, as in every other language, rather than VimTeX's package documentation. `]]` and `[[` keep VimTeX's meaning, the next and previous section, rather than the languages plan's next and previous reference, because that is what they mean in Vim and what a writer moving through a chapter wants. And `Space c b`, in the code menu, builds the way the project wants.

A text object, in the last rows of the table, is a key typed after an operator such as `d` (delete), `c` (change) or `y` (copy), or in visual mode, and it names the stretch of text to act on: `d a e` deletes the whole environment the cursor is in. A motion, in the rows before those, moves the cursor and can also follow an operator: `d ] m` deletes up to the next `\begin`.

The suite never opens Skim and never needs MacTeX. Stand-in scripts named `latexmk` and `osascript` sit first on the `PATH`, the list of folders searched for a program, and write down the arguments they are given, so a test reads exactly what VimTeX would have run.

| Key | Description | What it does |
| --- | --- | --- |
| `Space c b` | Build Document | Builds the document once, with the project's own command when it has set one, otherwise with latexmk |
| `Backslash l l` | Compile Continuously | Starts latexmk watching the document, rebuilding after every save; pressed again, stops it |
| `Backslash l S` | Compile Once | Builds the document once with latexmk, whatever the project's own command |
| `Backslash l L` | Compile Selection | Builds some lines alone, with the document's preamble, into a PDF of their own: in visual mode the selection, in normal mode the lines a motion or text object covers |
| `Backslash l o` | Compiler Output | Shows what latexmk printed during the last build |
| `Backslash l k` | Stop Compiling | Stops this document's build |
| `Backslash l K` | Stop All Compiling | Stops every build running in this Neovim |
| `Backslash l e` | Compile Errors | Opens the list of errors from the last build, each one a jump to its line |
| `Backslash l g` | Compiler Status | Says whether this document's build is running, finished or failed |
| `Backslash l G` | All Compilers Status | Says the same for every LaTeX document open |
| `Backslash l c` | Clean Build Files | Deletes latexmk's build files, keeping the PDF |
| `Backslash l C` | Clean All Build Files | Deletes the build files and the PDF |
| `Backslash l v` | View PDF | Opens the PDF in Skim at the cursor's line, marked with the reading bar |
| `Backslash l t` | Table of Contents | Opens a list of the document's sections, labels and figures; Enter on one jumps to it |
| `Backslash l T` | Toggle Table of Contents | Opens that list, or closes it when it is open |
| `Backslash l m` | Insert Shortcuts | Lists VimTeX's insert-mode shortcuts, such as a backtick then `a` for `\alpha` |
| `Backslash l i` | VimTeX Info | Shows what VimTeX knows about this document: its main file, its builder and its viewer |
| `Backslash l I` | VimTeX Full Info | Shows the same for every LaTeX document open |
| `Backslash l s` | Toggle Main File | Switches between building the whole document and building only the current file |
| `Backslash l x` | Reload VimTeX | Reloads VimTeX's own scripts |
| `Backslash l X` | Reload VimTeX State | Forgets what VimTeX knew about this document and works it out again, such as which file is the main one |
| `Backslash l q` | VimTeX Log | Shows VimTeX's own messages and warnings |
| `Backslash l a` | Context Menu | Shows what can be done with the thing under the cursor, such as opening a citation's entry |
| `d s e` | Delete Surrounding Environment | Removes the `\begin` and `\end` around the cursor, keeping what is between them |
| `c s e` | Change Surrounding Environment | Asks for a new name and puts it in both the `\begin` and the `\end` |
| `t s e` | Toggle Environment | Swaps the environment for its partner, such as `itemize` for `enumerate` |
| `t s s` | Toggle Starred Environment | Adds or removes the star, so `equation` becomes `equation*`, the version without a number |
| `d s $` | Delete Surrounding Math | Removes the marks around the formula under the cursor, such as the two `$`, keeping the formula |
| `c s $` | Change Surrounding Math | Changes those marks, for instance from `$…$` to an `equation` environment |
| `t s $` | Toggle Inline or Display Math | Swaps a formula inside the line, `$…$`, for one on a line of its own, `\[…\]`, and back |
| `F6` | Surround Line with Environment | Asks for an environment name and puts the current line inside a `\begin` and `\end` of it |
| `F6` | Surround with Environment | In visual mode, does the same for the selected lines |
| `d s c` | Delete Surrounding Command | Removes the command around the cursor and keeps its argument, so `\textbf{word}` becomes `word` |
| `c s c` | Change Surrounding Command | Asks for a new name, so `\textbf{word}` can become `\emph{word}` |
| `t s c` | Toggle Starred Command | Adds or removes a command's star, so `\section` becomes `\section*`, the version without a number |
| `t s f` | Toggle Fraction | Swaps `\frac{a}{b}` for `a/b` and back; in visual mode, the selected fraction |
| `t s b` | Toggle Line Break | Adds or removes the `\\` line break at the end of the line |
| `F7` | Create Command | In insert mode, turns the word just typed into a command, so `emph` becomes `\emph{`; in normal and visual mode, asks for a command and wraps the word or the selection in it |
| `d s d` | Delete Surrounding Delimiters | Removes the brackets around the cursor, `\left(` and `\right)` included |
| `c s d` | Change Surrounding Delimiters | Changes those brackets, for instance `(…)` into `[…]` |
| `t s d` | Toggle Delimiter Size | Swaps `(…)` for `\left(…\right)`, brackets that grow with what they hold, and back; in visual mode, every pair in the selection |
| `t s D` | Toggle Delimiter Size Back | Steps the other way through the same sizes |
| `] ]` | Close Environment or Delimiter | In insert mode, types the `\end{…}` or the closing bracket the cursor is inside |
| `F8` | Size Delimiters to Content | Adds `\left` and `\right` to every plain bracket pair in the formula around the cursor |
| `%` | Matching Pair | Jumps to the partner of the bracket, `\begin` or `\end` under the cursor |
| `] ]` | Next Section Start | Moves to the start of the next section |
| `] [` | Next Section End | Moves to the end of the next section |
| `[ [` | Prev Section Start | Moves to the start of the previous section |
| `[ ]` | Prev Section End | Moves to the end of the previous section |
| `] m` | Next Environment Start | Moves to the next `\begin` |
| `] M` | Next Environment End | Moves to the next `\end` |
| `[ m` | Prev Environment Start | Moves to the previous `\begin` |
| `[ M` | Prev Environment End | Moves to the previous `\end` |
| `] n` | Next Math Start | Moves to the start of the next formula |
| `] N` | Next Math End | Moves to the end of the next formula |
| `[ n` | Prev Math Start | Moves to the start of the previous formula |
| `[ N` | Prev Math End | Moves to the end of the previous formula |
| `] r` | Next Frame Start | Moves to the start of the next slide, which Beamer, LaTeX's slide class, writes as a `frame` environment |
| `] R` | Next Frame End | Moves to the end of the next slide |
| `[ r` | Prev Frame Start | Moves to the start of the previous slide |
| `[ R` | Prev Frame End | Moves to the end of the previous slide |
| `] /` | Next Comment Start | Moves to the start of the next comment, the text after a `%` |
| `] *` | Next Comment End | Moves to the end of the next comment |
| `[ /` | Prev Comment Start | Moves to the start of the previous comment |
| `[ *` | Prev Comment End | Moves to the end of the previous comment |
| `i c` | Inside Command | A command's name without its backslash or arguments, so `c i c` on `\textbf{word}` replaces `textbf` |
| `a c` | Around Command | The whole command, backslash and arguments included |
| `i d` | Inside Delimiters | What is inside the brackets around the cursor |
| `a d` | Around Delimiters | The brackets and what is inside them |
| `i e` | Inside Environment | What is between the `\begin` and `\end` around the cursor |
| `a e` | Around Environment | The environment with its `\begin` and `\end` |
| `i $` | Inside Math | The formula under the cursor without its `$` marks |
| `a $` | Around Math | The formula with its marks |
| `i P` | Inside Section | The body of the section under the cursor |
| `a P` | Around Section | The whole section, its heading included |
| `i m` | Inside Item | The text of the list item under the cursor, after its `\item` |
| `a m` | Around Item | The item with its `\item` |

`] ]` appears twice because it is two keys: in insert mode it closes what the cursor is inside, and elsewhere it moves to the next section. `F6` likewise takes the line in normal mode and the selection in visual mode.

- [ ] **Write the failing tests**

`tests/test_latex.lua`:

```lua
-- LaTeX. No test opens Skim or runs LaTeX. Stand-in shell scripts named
-- latexmk and osascript sit first on PATH and write their arguments to a
-- file, so a test reads exactly what VimTeX would have run. The inverse search
-- test starts a second Neovim nobody can see, as Skim does.
local I = require("ach.icons")

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level)
        said[#said + 1] = { msg = msg, level = level }
      end,
    },
  }, body)
  return said
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- Writes a shell script called name into bin that adds each of its arguments,
-- one to a line, to the file record, then runs line.
local function stand_in(bin, name, record, line)
  vim.fn.mkdir(bin, "p")
  local path = bin .. "/" .. name
  vim.fn.writefile({
    "#!/bin/sh",
    ("printf '%%s\\n' \"$@\" >> '%s'"):format(record),
    line or "",
  }, path)
  vim.uv.fs_chmod(path, tonumber("755", 8))
end

-- What a stand-in has written to record, or "" when it never ran.
local function recorded(record)
  local f = io.open(record)
  if not f then
    return ""
  end
  local text = f:read("*a")
  f:close()
  return text
end

-- Writes a one-page document to dir/main.tex and returns its path. On line 3
-- the formula $x^2$ runs from column 8 to column 12.
local function write_tex(dir)
  local tex = dir .. "/main.tex"
  vim.fn.writefile({
    "\\documentclass{article}",
    "\\begin{document}",
    "Hello, $x^2$.",
    "\\section{One}",
    "\\end{document}",
  }, tex)
  return tex
end

-- Runs body with fn as the build hook, then puts the previous hook back, even
-- when body fails.
local function hooked(fn, body)
  local latex = require("ach.latex")
  local previous = latex.build_with(fn)
  local ok, err = pcall(body)
  latex.build_with(previous)
  if not ok then
    error(err, 0)
  end
end

-- Every key on buf whose action is one of VimTeX's, with the name of that
-- action, such as vimtex-info.
local function vimtex_keys(buf)
  local found = {}
  for _, mode in ipairs({ "n", "x", "o", "i" }) do
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      local name = (m.rhs or ""):match("^<[Pp][Ll][Uu][Gg]>%((vimtex%-.-)%)")
      if name then
        found[#found + 1] = { mode = mode, lhs = m.lhs, name = name, desc = m.desc }
      end
    end
  end
  return found
end

-- VimTeX's build status for buf's document: 1 while a build runs, 2 when it
-- succeeded and 3 when it failed.
local function build_status(buf)
  return vim.api.nvim_buf_call(buf, function()
    return vim.fn.eval("get(get(get(b:, 'vimtex', {}), 'compiler', {}), 'status', -1)")
  end)
end

return {
  ["VimTeX is set up for Skim, with its build folder under the cache"] = function(t)
    t.eq(vim.g.vimtex_view_method, "skim", "the viewer")
    t.eq(vim.g.vimtex_view_skim_sync, 1, "Skim follows the cursor after each build")
    t.eq(vim.g.vimtex_view_skim_activate, 1, "Skim comes to the front")
    t.eq(vim.g.vimtex_view_skim_reading_bar, 1, "Skim marks the line with its reading bar")
    t.eq(vim.g.vimtex_mappings_disable, { n = { "K" } }, "K is left to the language server")
    t.eq(vim.fn.exists(":VimtexInverseSearch"), 2, "the inverse search command exists before any LaTeX file opens")
    local latex = require("ach.latex")
    local cache = vim.fn.stdpath("cache") .. "/latex/"
    local aux = latex.aux_dir("/Users/someone/My Book")
    t.eq(aux:sub(1, #cache), cache, "the build folder is under the cache")
    t.ok(not aux:find(" ", 1, true), ("%s has no space"):format(aux))
    t.ok(aux:find("/My-Book-", 1, true), ("%s names the project"):format(aux))
    t.ok(latex.aux_dir("/a/book") ~= latex.aux_dir("/b/book"), "two projects with the same name get different folders")
  end,

  ["a LaTeX file gets both highlighters, and VimTeX's indentation"] = function(t)
    local ok, added = pcall(vim.treesitter.language.add, "latex")
    if not (ok and added) then
      t.skip("the latex parser is not installed; scripts/check --full installs it")
    end
    tidy(function()
      vim.cmd.edit(vim.fn.fnameescape(write_tex(t.tmpdir())))
      local buf = vim.api.nvim_get_current_buf()
      t.eq(vim.bo[buf].filetype, "tex", "the file type")
      t.ok(vim.treesitter.highlighter.active[buf] ~= nil, "tree-sitter colours the file")
      t.eq(vim.b[buf].current_syntax, "tex", "Vim's LaTeX syntax is loaded too")
      t.eq(vim.bo[buf].indentexpr, "VimtexIndentExpr()", "VimTeX indents the file")
      t.eq(vim.fn["vimtex#syntax#in_mathzone"](3, 9), 1, "VimTeX sees the x of $x^2$ as math")
      t.eq(vim.fn["vimtex#syntax#in_mathzone"](3, 2), 0, "and the e of Hello as text")
    end)
  end,

  ["every VimTeX key has a description and an icon, and ] ] stays VimTeX's"] = function(t)
    local latex = require("ach.latex")
    local added = {}
    tidy(function()
      with({
        {
          require("which-key"),
          "add",
          function(specs)
            vim.list_extend(added, specs)
          end,
        },
      }, function()
        vim.cmd.edit(vim.fn.fnameescape(write_tex(t.tmpdir())))
      end)
      local buf = vim.api.nvim_get_current_buf()
      local keys = vimtex_keys(buf)
      t.ok(#keys > 0, "VimTeX set its keys")
      local seen = {}
      for _, k in ipairs(keys) do
        local want = latex.describe[k.name]
        t.ok(want ~= nil, ("%s, on %s in mode %s, has a description"):format(k.name, k.lhs, k.mode))
        t.eq(k.desc, want, ("%s in mode %s"):format(k.lhs, k.mode))
        t.ok(I.key(want) ~= nil, ("%q has a line in M.keys"):format(want))
        seen[k.name] = true
      end
      for name in pairs(latex.describe) do
        t.ok(seen[name], ("%s is on a key"):format(name))
      end

      local build = vim.fn.maparg("<leader>cb", "n", false, true)
      t.eq(build.buffer, 1, "Space c b belongs to the LaTeX buffer")
      t.eq(build.desc, "Build Document", "Space c b")
      t.ok(I.key(build.desc) ~= nil, '"Build Document" has a line in M.keys')
      local group = { "<localleader>l", group = "latex", icon = I.group("latex"), buffer = buf, mode = { "n", "x" } }
      t.ok(
        vim.iter(added):any(function(spec)
          return vim.deep_equal(spec, group)
        end),
        "which-key names Backslash l latex, with its icon"
      )

      -- A language server that offers references, as texlab does.
      require("ach.lsp").attach(buf, {
        supports_method = function(_, method)
          return method == "textDocument/documentHighlight"
        end,
      })
      t.eq(vim.fn.maparg("]]", "n", false, true).desc, "Next Section Start", "] ] after a language server attaches")
      t.eq(vim.fn.maparg("[[", "n", false, true).desc, "Prev Section Start", "[ [ after a language server attaches")
    end)
  end,

  ["Space c b with no hook builds once with latexmk into the cache, and Skim shows the PDF"] = function(t)
    local latex = require("ach.latex")
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    stand_in(bin, "latexmk", dir .. "/latexmk.args", ": > main.pdf")
    stand_in(bin, "osascript", dir .. "/osascript.args", "echo net.sourceforge.skim-app")
    -- VimTeX makes the build folder when the build starts, in the real
    -- cache, so it is removed afterwards whether or not the test passed.
    local ok, err = pcall(tidy, function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
        local buf = vim.api.nvim_get_current_buf()
        press("<leader>cb")
        vim.wait(10000, function()
          return build_status(buf) >= 2
        end, 20)
        t.eq(build_status(buf), 2, "the build finished and succeeded")
        local args = vim.split(vim.trim(recorded(dir .. "/latexmk.args")), "\n")
        t.ok(vim.tbl_contains(args, "-synctex=1"), "latexmk writes the file that links the PDF to the source")
        t.ok(vim.tbl_contains(args, "-emulate-aux-dir"), "latexmk keeps its build files apart")
        t.ok(vim.tbl_contains(args, "-auxdir=" .. latex.aux_dir(dir)), "in the project's folder under the cache")
        t.eq(args[#args], "main.tex", "latexmk builds the main file")
        t.ok(
          vim.wait(10000, function()
            return recorded(dir .. "/osascript.args"):find(('Path("%s/main.pdf")'):format(dir), 1, true) ~= nil
          end, 20),
          "Skim is asked to show the PDF"
        )
      end)
    end)
    vim.fn.delete(latex.aux_dir(dir), "rf")
    if not ok then
      error(err, 0)
    end
  end,

  ["a build hook's command runs in a terminal; returning nothing falls back, and failing runs nothing"] = function(t)
    require("ach.latex")
    local dir = t.tmpdir()
    local opened = {}
    tidy(function()
      vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
      with({
        {
          Snacks.terminal,
          "open",
          function(cmd, opts)
            opened[#opened + 1] = { cmd = cmd, opts = opts }
          end,
        },
      }, function()
        hooked(function(file)
          return { "scripts/build.sh", vim.fs.basename(file) }, dir .. "/book"
        end, function()
          press("<leader>cb")
        end)
        t.eq(#opened, 1, "one terminal opened")
        t.eq(opened[1].cmd, { "scripts/build.sh", "main.tex" }, "running the hook's command on the main file")
        t.eq(opened[1].opts.cwd, dir .. "/book", "in the hook's folder")
        t.eq(opened[1].opts.interactive, false, "and it stays open when the build ends, to be read")

        local said = notices(function()
          with({ { vim.fn, "executable", only({}) } }, function()
            hooked(function() end, function()
              press("<leader>cb")
            end)
          end)
        end)
        t.eq(
          said,
          {
            {
              msg = "MacTeX is not installed. Install it with: brew install --cask mactex",
              level = vim.log.levels.WARN,
            },
          },
          "a hook that returns nothing falls back to latexmk, which is missing here"
        )
        t.eq(#opened, 1, "and no terminal opened")

        said = notices(function()
          hooked(function()
            error("no build script here")
          end, function()
            press("<leader>cb")
          end)
        end)
        t.eq(#said, 1, "a hook that fails prints one line")
        t.eq(said[1].level, vim.log.levels.ERROR, "as an error")
        t.ok(vim.startswith(said[1].msg, "The LaTeX build hook failed: "), "saying the hook failed")
        t.ok(said[1].msg:find("no build script here", 1, true), "and why")
        t.eq(#opened, 1, "and nothing ran")
      end)
    end)
  end,

  ["with no latexmk, Space c b prints the Homebrew line and runs nothing"] = function(t)
    require("ach.latex")
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    stand_in(bin, "latexmk", dir .. "/latexmk.args")
    tidy(function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        vim.cmd.edit(vim.fn.fnameescape(write_tex(dir)))
        local said = notices(function()
          with({ { vim.fn, "executable", only({}) } }, function()
            press("<leader>cb")
          end)
        end)
        t.eq(
          vim.tbl_map(function(n)
            return n.msg
          end, said),
          { "MacTeX is not installed. Install it with: brew install --cask mactex" },
          "one line, saying what to run"
        )
        vim.wait(500)
        t.eq(recorded(dir .. "/latexmk.args"), "", "and latexmk never ran")
      end)
    end)
  end,

  ["View PDF opens Skim at the cursor's line, with the reading bar"] = function(t)
    local dir = t.tmpdir()
    local bin = dir .. "/bin"
    local record = dir .. "/osascript.args"
    stand_in(bin, "latexmk", dir .. "/latexmk.args")
    stand_in(bin, "osascript", record, "echo net.sourceforge.skim-app")
    vim.fn.writefile({}, dir .. "/main.pdf")
    tidy(function()
      with({ { vim.env, "PATH", bin .. ":" .. vim.env.PATH } }, function()
        local tex = write_tex(dir)
        vim.cmd.edit(vim.fn.fnameescape(tex))
        vim.api.nvim_win_set_cursor(0, { 3, 0 })
        vim.cmd("VimtexView")
        t.ok(
          vim.wait(10000, function()
            return recorded(record):find("app.open(theFile);", 1, true) ~= nil
          end, 20),
          "Skim is asked to open the PDF"
        )
        local script = recorded(record)
        for _, want in ipairs({
          ('Path("%s/main.pdf")'):format(dir),
          "app.activate();",
          "app.texLines[2]",
          ('from: Path("%s")'):format(tex),
          "showingReadingBar: true",
        }) do
          t.ok(script:find(want, 1, true), ("the script Skim runs contains %s"):format(want))
        end
      end)
    end)
  end,

  ["Skim's inverse search moves this Neovim's cursor to the line clicked"] = function(t)
    -- VimTeX lists this Neovim's address when a LaTeX file opens, so the
    -- address must exist first.
    if vim.v.servername == "" then
      vim.fn.serverstart()
    end
    tidy(function()
      local tex = write_tex(t.tmpdir())
      vim.cmd.edit(vim.fn.fnameescape(tex))
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      local exited
      -- The command Skim runs, less the path to Neovim. The trailing qa! ends
      -- the second Neovim even when the command is unknown.
      vim.system({
        vim.v.progpath,
        "--headless",
        "-u",
        t.root .. "/init.lua",
        "-c",
        ("VimtexInverseSearch 3 '%s'"):format(tex),
        "-c",
        "qa!",
      }, { text = true }, function(out)
        exited = out
      end)
      t.ok(
        vim.wait(60000, function()
          return exited ~= nil
        end, 50),
        "the second Neovim quits"
      )
      t.ok(
        vim.wait(5000, function()
          return vim.api.nvim_win_get_cursor(0)[1] == 3
        end, 20),
        "the cursor moved to line 3"
      )
      t.eq(exited.code, 0, "the second Neovim's exit code")
    end)
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_latex`
Expected: `0 passed, 8 failed, 0 need a person, 0 skipped`, exit 1. The settings test fails on `the viewer: expected "skim", got nil`, and the highlighting test on `Vim's LaTeX syntax is loaded too: expected "tex", got nil`, because starting tree-sitter turned the older highlighting off. The key, build, hook and missing-latexmk tests fail on `module 'ach.latex' not found`, the forward search on `Vim:E492: Not an editor command: VimtexView`, and the inverse search on `the cursor moved to line 3`, after the second Neovim reports the unknown command and quits. Where the latex parser has not been installed, the highlighting test is skipped instead, and the line reads `0 passed, 7 failed, 0 need a person, 1 skipped`.

- [ ] **Write the latex module**

`lua/ach/latex.lua`:

```lua
-- LaTeX: VimTeX's settings, the build key, and a description for each of
-- VimTeX's own keys. VimTeX builds with latexmk into a folder under Neovim's
-- cache, shows the PDF in Skim, and moves the cursor when Skim is
-- Command-Shift-clicked. A project can give Space c b its own command
-- through build_with.
local need = require("ach.need")

local M = {}

-- The project's build command, set by build_with, or nil.
---@type ach.latex.hook?
local hook

-- The folder latexmk writes its build files to for the project in root: one
-- per project under Neovim's cache, named after the project with eight
-- characters of a hash of its path, so two projects with the same name stay
-- apart. Anything but a letter, digit, dot, dash or underscore becomes a
-- dash, because the path goes on a shell command line.
---@param root string
---@return string
function M.aux_dir(root)
  local name = vim.fs.basename(root):gsub("[^%w._-]", "-")
  return ("%s/latex/%s-%s"):format(vim.fn.stdpath("cache"), name, vim.fn.sha256(root):sub(1, 8))
end

-- VimTeX's settings, as global variables. The plugin spec sets them before
-- VimTeX loads, because VimTeX reads them then.
---@return table<string, any>
function M.globals()
  return {
    vimtex_view_method = "skim",
    -- After each build Skim moves to the cursor's line, marks it with the
    -- reading bar, and comes to the front.
    vimtex_view_skim_sync = 1,
    vimtex_view_skim_activate = 1,
    vimtex_view_skim_reading_bar = 1,
    -- K stays the language server's hover, as in every other language.
    vimtex_mappings_disable = { n = { "K" } },
    -- The error list opens after a failed build, not for warnings alone.
    vimtex_quickfix_open_on_warning = 0,
    -- The build files go under the cache. A project whose .latexmkrc names
    -- its own folder keeps it, because VimTeX gives that file the last word.
    vimtex_compiler_latexmk = {
      aux_dir = function(info)
        return M.aux_dir(info.root)
      end,
    },
  }
end

-- Sets the project's build command, or clears it with nil, and returns the
-- one it replaces. fn receives the main file's path and returns the command,
-- as a string or a list, and the folder to run it in, which defaults to the
-- main file's. Returning nothing falls back to latexmk. A project sets it in
-- its own .nvim.lua, which Neovim runs only once its owner has trusted it.
---@alias ach.latex.hook fun(file: string): (string|string[])?, string?
---@param fn? ach.latex.hook
---@return ach.latex.hook?
function M.build_with(fn)
  vim.validate("fn", fn, "function", true)
  local previous = hook
  hook = fn
  return previous
end

-- The document's main file, which VimTeX works out by following \input and
-- the like back to the file with \documentclass, so a chapter builds the
-- whole book. buf's own file when VimTeX has not looked at buf.
local function main_file(buf)
  local main = vim.api.nvim_buf_call(buf, function()
    return vim.fn.eval("get(get(b:, 'vimtex', {}), 'tex', '')")
  end)
  return main ~= "" and main or vim.api.nvim_buf_get_name(buf)
end

-- Runs cmd in cwd in a terminal along the bottom, which stays open when the
-- command ends so its output can be read.
---@param cmd string|string[]
---@param cwd string
function M.run(cmd, cwd)
  Snacks.terminal.open(cmd, { cwd = cwd, interactive = false, win = { position = "bottom" } })
end

-- Builds buf's document: with the project's hook when it gives a command,
-- otherwise once with latexmk. A hook that fails is reported and nothing
-- runs.
---@param buf integer
function M.build(buf)
  local file = main_file(buf)
  if hook then
    local ok, cmd, cwd = pcall(hook, file)
    if not ok then
      vim.notify(("The LaTeX build hook failed: %s"):format(cmd), vim.log.levels.ERROR)
      return
    end
    if cmd then
      M.run(cmd, cwd or vim.fs.dirname(file))
      return
    end
  end
  if need.have("latexmk") then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("VimtexCompileSS")
    end)
  end
end

-- A description for each of VimTeX's actions that VimTeX puts on a key by
-- default, keyed by the action's name. Actions VimTeX leaves off every key,
-- or puts on one only for another viewer, have none.
M.describe = {
  -- About VimTeX itself.
  ["vimtex-info"] = "VimTeX Info",
  ["vimtex-info-full"] = "VimTeX Full Info",
  ["vimtex-reload"] = "Reload VimTeX",
  ["vimtex-reload-state"] = "Reload VimTeX State",
  ["vimtex-toggle-main"] = "Toggle Main File",
  ["vimtex-log"] = "VimTeX Log",
  ["vimtex-context-menu"] = "Context Menu",
  -- Building.
  ["vimtex-compile"] = "Compile Continuously",
  ["vimtex-compile-ss"] = "Compile Once",
  ["vimtex-compile-output"] = "Compiler Output",
  ["vimtex-compile-selected"] = "Compile Selection",
  ["vimtex-stop"] = "Stop Compiling",
  ["vimtex-stop-all"] = "Stop All Compiling",
  ["vimtex-errors"] = "Compile Errors",
  ["vimtex-clean"] = "Clean Build Files",
  ["vimtex-clean-full"] = "Clean All Build Files",
  ["vimtex-status"] = "Compiler Status",
  ["vimtex-status-all"] = "All Compilers Status",
  -- Contents, viewing and shortcuts.
  ["vimtex-toc-open"] = "Table of Contents",
  ["vimtex-toc-toggle"] = "Toggle Table of Contents",
  ["vimtex-view"] = "View PDF",
  ["vimtex-imaps-list"] = "Insert Shortcuts",
  -- Environments and formulas.
  ["vimtex-env-delete"] = "Delete Surrounding Environment",
  ["vimtex-env-change"] = "Change Surrounding Environment",
  ["vimtex-env-toggle"] = "Toggle Environment",
  ["vimtex-env-toggle-star"] = "Toggle Starred Environment",
  ["vimtex-env-delete-math"] = "Delete Surrounding Math",
  ["vimtex-env-change-math"] = "Change Surrounding Math",
  ["vimtex-env-toggle-math"] = "Toggle Inline or Display Math",
  ["vimtex-env-surround-line"] = "Surround Line with Environment",
  ["vimtex-env-surround-visual"] = "Surround with Environment",
  -- Commands.
  ["vimtex-cmd-delete"] = "Delete Surrounding Command",
  ["vimtex-cmd-change"] = "Change Surrounding Command",
  ["vimtex-cmd-toggle-star"] = "Toggle Starred Command",
  ["vimtex-cmd-toggle-frac"] = "Toggle Fraction",
  ["vimtex-cmd-toggle-break"] = "Toggle Line Break",
  ["vimtex-cmd-create"] = "Create Command",
  -- Brackets.
  ["vimtex-delim-delete"] = "Delete Surrounding Delimiters",
  ["vimtex-delim-change-math"] = "Change Surrounding Delimiters",
  ["vimtex-delim-toggle-modifier"] = "Toggle Delimiter Size",
  ["vimtex-delim-toggle-modifier-reverse"] = "Toggle Delimiter Size Back",
  ["vimtex-delim-close"] = "Close Environment or Delimiter",
  ["vimtex-delim-add-modifiers"] = "Size Delimiters to Content",
  -- Motions.
  ["vimtex-%"] = "Matching Pair",
  ["vimtex-]]"] = "Next Section Start",
  ["vimtex-]["] = "Next Section End",
  ["vimtex-[["] = "Prev Section Start",
  ["vimtex-[]"] = "Prev Section End",
  ["vimtex-]m"] = "Next Environment Start",
  ["vimtex-]M"] = "Next Environment End",
  ["vimtex-[m"] = "Prev Environment Start",
  ["vimtex-[M"] = "Prev Environment End",
  ["vimtex-]n"] = "Next Math Start",
  ["vimtex-]N"] = "Next Math End",
  ["vimtex-[n"] = "Prev Math Start",
  ["vimtex-[N"] = "Prev Math End",
  ["vimtex-]r"] = "Next Frame Start",
  ["vimtex-]R"] = "Next Frame End",
  ["vimtex-[r"] = "Prev Frame Start",
  ["vimtex-[R"] = "Prev Frame End",
  ["vimtex-]/"] = "Next Comment Start",
  ["vimtex-]*"] = "Next Comment End",
  ["vimtex-[/"] = "Prev Comment Start",
  ["vimtex-[*"] = "Prev Comment End",
  -- Text objects.
  ["vimtex-ic"] = "Inside Command",
  ["vimtex-ac"] = "Around Command",
  ["vimtex-id"] = "Inside Delimiters",
  ["vimtex-ad"] = "Around Delimiters",
  ["vimtex-ie"] = "Inside Environment",
  ["vimtex-ae"] = "Around Environment",
  ["vimtex-i$"] = "Inside Math",
  ["vimtex-a$"] = "Around Math",
  ["vimtex-iP"] = "Inside Section",
  ["vimtex-aP"] = "Around Section",
  ["vimtex-im"] = "Inside Item",
  ["vimtex-am"] = "Around Item",
}

-- The modes VimTeX sets keys in.
local modes = { "n", "x", "o", "i" }

-- Gives each of VimTeX's keys on buf its description, so which-key shows it
-- with its icon, and adds the build key and the name of the Backslash l menu.
-- VimTeX sets its keys without descriptions, so each is set again here with
-- the same action. It runs on VimtexEventInitPost, which VimTeX fires once
-- its keys are set.
---@param buf integer
function M.attach(buf)
  for _, mode in ipairs(modes) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
      -- VimTeX writes <plug> in lower case; Neovim may report it as <Plug>.
      local name = (map.rhs or ""):match("^<[Pp][Ll][Uu][Gg]>%((vimtex%-.-)%)")
      local desc = name and M.describe[name]
      if desc then
        vim.keymap.set(mode, map.lhs, map.rhs, {
          buf = buf,
          remap = true,
          silent = map.silent == 1,
          nowait = map.nowait == 1,
          desc = desc,
        })
      end
    end
  end
  vim.keymap.set("n", "<leader>cb", function()
    M.build(buf)
  end, { buf = buf, desc = "Build Document" })
  require("which-key").add({
    {
      "<localleader>l",
      group = "latex",
      icon = require("ach.icons").group("latex"),
      buffer = buf,
      mode = { "n", "x" },
    },
  })
end

return M
```

- [ ] **Write the plugin spec**

`lua/ach/plugins/latex.lua`:

```lua
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/lang/tex.lua.
-- LaTeX: VimTeX builds with latexmk, shows the PDF in Skim, and follows
-- Skim's clicks back to the source. Its settings, keys and build hook live in
-- ach.latex.
return {
  {
    "lervag/vimtex",
    -- Loaded at start rather than on a LaTeX file, because the Neovim that
    -- Skim starts for an inverse search opens no LaTeX file and still needs
    -- the VimtexInverseSearch command.
    lazy = false,
    -- VimTeX reads its settings when it loads, so they are set first.
    init = function()
      for name, value in pairs(require("ach.latex").globals()) do
        vim.g[name] = value
      end
    end,
    config = function()
      vim.api.nvim_create_autocmd("User", {
        group = vim.api.nvim_create_augroup("ach_latex", { clear = true }),
        pattern = "VimtexEventInitPost",
        callback = function()
          require("ach.latex").attach(vim.api.nvim_get_current_buf())
        end,
      })
    end,
  },
}
```

- [ ] **Keep both highlighters for LaTeX**

In `lua/ach/treesitter.lua`, replace:

```lua
function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if not (ok and added) then
    return
  end
  if has_query(lang, "highlights") then
    pcall(vim.treesitter.start, buf, lang)
  end
  if has_query(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  if has_query(lang, "textobjects") then
    M.moves_for(buf)
  end
end
```

with:

```lua
-- File types that keep Vim's regex highlighting beside tree-sitter's, and
-- their own indentation. VimTeX reads the regex highlighting to tell a
-- formula from text, for the i$ and a$ text objects, the ds$, cs$ and ts$
-- keys, the symbols it draws in place of commands such as \alpha, and its
-- insert-mode shortcuts. vim.treesitter.start turns regex highlighting off,
-- and its help says to set 'syntax' afterwards to have both.
M.with_regex = { tex = true }

function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
  if not lang then
    return
  end
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if not (ok and added) then
    return
  end
  local regex = M.with_regex[vim.bo[buf].filetype]
  if has_query(lang, "highlights") then
    pcall(vim.treesitter.start, buf, lang)
    if regex then
      -- "ON" in capitals: Vim's syntax loader compares the value with ==,
      -- which follows 'ignorecase', and only capitals match either way.
      vim.bo[buf].syntax = "ON"
    end
  end
  if has_query(lang, "indents") and not regex then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  if has_query(lang, "textobjects") then
    M.moves_for(buf)
  end
end
```

- [ ] **Leave ] ] and [ [ to VimTeX**

In `lua/ach/lsp.lua`, replace the comment above `M.keys`:

```lua
-- Each key is set on a buffer only when one of its servers supports the
-- method in has, or one of the methods when has is a list. A key with no has
-- is set for any server.
```

with:

```lua
-- Each key is set on a buffer only when one of its servers supports the
-- method in has, or one of the methods when has is a list. A key with no has
-- is set for any server. A key with not_ft is left off buffers of those file
-- types, where the key already means something else.
```

Then replace the `]]` and `[[` entries in `M.keys`:

```lua
  {
    "]]",
    function()
      Snacks.words.jump(vim.v.count1)
    end,
    desc = "Next Reference",
    has = "textDocument/documentHighlight",
  },
  {
    "[[",
    function()
      Snacks.words.jump(-vim.v.count1)
    end,
    desc = "Prev Reference",
    has = "textDocument/documentHighlight",
  },
```

with:

```lua
  -- In LaTeX, VimTeX's ]] and [[ move between sections, as they do in Vim.
  {
    "]]",
    function()
      Snacks.words.jump(vim.v.count1)
    end,
    desc = "Next Reference",
    has = "textDocument/documentHighlight",
    not_ft = { "tex" },
  },
  {
    "[[",
    function()
      Snacks.words.jump(-vim.v.count1)
    end,
    desc = "Prev Reference",
    has = "textDocument/documentHighlight",
    not_ft = { "tex" },
  },
```

Then replace `M.attach`:

```lua
function M.attach(buf, client)
  for _, key in ipairs(M.keys) do
    if supports(client, key.has, buf) then
      vim.keymap.set(key.mode or "n", key[1], key[2], { buf = buf, desc = key.desc })
    end
  end
  if vim.bo[buf].buftype == "" and client:supports_method("textDocument/inlayHint", buf) then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end
  if client:supports_method("textDocument/codeLens", buf) then
    vim.lsp.codelens.enable(true, { bufnr = buf })
  end
end
```

with:

```lua
function M.attach(buf, client)
  local ft = vim.bo[buf].filetype
  for _, key in ipairs(M.keys) do
    if supports(client, key.has, buf) and not vim.tbl_contains(key.not_ft or {}, ft) then
      vim.keymap.set(key.mode or "n", key[1], key[2], { buf = buf, desc = key.desc })
    end
  end
  if vim.bo[buf].buftype == "" and client:supports_method("textDocument/inlayHint", buf) then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end
  if client:supports_method("textDocument/codeLens", buf) then
    vim.lsp.codelens.enable(true, { bufnr = buf })
  end
end
```

- [ ] **List latexmk and Skim**

In `lua/ach/need.lua`, add above `-- Programs added by later tasks go above this line.`:

```lua
  {
    name = "latexmk",
    label = "MacTeX",
    brew = "brew install --cask mactex",
    purpose = "building LaTeX documents on Space c b and Backslash l",
  },
  {
    name = "displayline",
    label = "Skim",
    brew = "brew install --cask skim",
    purpose = "showing LaTeX PDFs and jumping between them and the source",
  },
```

Skim's cask links `displayline`, a small program inside Skim, into `/opt/homebrew/bin`, which is how a check that looks only for programs can see that Skim is installed.

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add above `-- Keys added by later tasks go above this line.`:

```lua
  -- LaTeX
  ["Build Document"] = { "actions.build", "green" },
  ["Compile Continuously"] = { "actions.build", "green" },
  ["Compile Once"] = { "actions.run", "green" },
  ["Compile Selection"] = { "actions.select", "green" },
  ["Compiler Output"] = { "terminal.term", "grey" },
  ["Stop Compiling"] = { "actions.stop", "red" },
  ["Stop All Compiling"] = { "actions.stop_circle", "red" },
  ["Compile Errors"] = { "lists.quickfix", "red" },
  ["Compiler Status"] = { "ui.health", "green" },
  ["All Compilers Status"] = { "ui.health", "cyan" },
  ["Clean Build Files"] = { "actions.clean", "yellow" },
  ["Clean All Build Files"] = { "actions.delete_sweep", "yellow" },
  ["View PDF"] = { "files.pdf", "red" },
  ["Table of Contents"] = { "code.outline", "azure" },
  ["Toggle Table of Contents"] = { "code.outline", "purple" },
  ["Insert Shortcuts"] = { "ui.keyboard", "purple" },
  ["VimTeX Info"] = { "ui.info", "blue" },
  ["VimTeX Full Info"] = { "ui.info", "cyan" },
  ["Toggle Main File"] = { "files.star", "yellow" },
  ["Reload VimTeX"] = { "actions.reload", "orange" },
  ["Reload VimTeX State"] = { "actions.refresh", "orange" },
  ["VimTeX Log"] = { "ui.log", "grey" },
  ["Context Menu"] = { "ui.menu", "azure" },
  ["Delete Surrounding Environment"] = { "actions.delete", "red" },
  ["Change Surrounding Environment"] = { "edit.change", "orange" },
  ["Toggle Environment"] = { "actions.swap", "purple" },
  ["Toggle Starred Environment"] = { "actions.star", "yellow" },
  ["Delete Surrounding Math"] = { "actions.delete", "red" },
  ["Change Surrounding Math"] = { "edit.change", "orange" },
  ["Toggle Inline or Display Math"] = { "actions.swap_vertical", "purple" },
  ["Surround Line with Environment"] = { "edit.wrap", "blue" },
  ["Surround with Environment"] = { "edit.wrap", "blue" },
  ["Delete Surrounding Command"] = { "actions.delete", "red" },
  ["Change Surrounding Command"] = { "edit.change", "orange" },
  ["Toggle Starred Command"] = { "actions.star", "yellow" },
  ["Toggle Fraction"] = { "actions.calculate", "purple" },
  ["Toggle Line Break"] = { "actions.wrap", "purple" },
  ["Create Command"] = { "actions.add_box", "green" },
  ["Delete Surrounding Delimiters"] = { "actions.delete", "red" },
  ["Change Surrounding Delimiters"] = { "edit.change", "orange" },
  ["Toggle Delimiter Size"] = { "actions.increase", "purple" },
  ["Toggle Delimiter Size Back"] = { "actions.decrease", "purple" },
  ["Close Environment or Delimiter"] = { "code.tag", "green" },
  ["Size Delimiters to Content"] = { "actions.add", "green" },
  ["Matching Pair"] = { "nav.match", "azure" },
  ["Next Section Start"] = { "nav.paragraph", "blue" },
  ["Next Section End"] = { "nav.paragraph", "blue" },
  ["Prev Section Start"] = { "nav.paragraph", "blue" },
  ["Prev Section End"] = { "nav.paragraph", "blue" },
  ["Next Environment Start"] = { "textobj.tag", "cyan" },
  ["Next Environment End"] = { "textobj.tag", "cyan" },
  ["Prev Environment Start"] = { "textobj.tag", "cyan" },
  ["Prev Environment End"] = { "textobj.tag", "cyan" },
  ["Next Math Start"] = { "code.function", "purple" },
  ["Next Math End"] = { "code.function", "purple" },
  ["Prev Math Start"] = { "code.function", "purple" },
  ["Prev Math End"] = { "code.function", "purple" },
  ["Next Frame Start"] = { "files.powerpoint", "orange" },
  ["Next Frame End"] = { "files.powerpoint", "orange" },
  ["Prev Frame Start"] = { "files.powerpoint", "orange" },
  ["Prev Frame End"] = { "files.powerpoint", "orange" },
  ["Next Comment Start"] = { "code.comment", "grey" },
  ["Next Comment End"] = { "code.comment", "grey" },
  ["Prev Comment Start"] = { "code.comment", "grey" },
  ["Prev Comment End"] = { "code.comment", "grey" },
  ["Inside Command"] = { "lang.latex", "green" },
  ["Around Command"] = { "lang.latex", "green" },
  ["Inside Delimiters"] = { "textobj.parens", "yellow" },
  ["Around Delimiters"] = { "textobj.parens", "yellow" },
  ["Inside Environment"] = { "textobj.tag", "cyan" },
  ["Around Environment"] = { "textobj.tag", "cyan" },
  ["Inside Math"] = { "code.function", "purple" },
  ["Around Math"] = { "code.function", "purple" },
  ["Inside Section"] = { "textobj.paragraph", "blue" },
  ["Around Section"] = { "textobj.paragraph", "blue" },
  ["Inside Item"] = { "ui.list", "azure" },
  ["Around Item"] = { "ui.list", "azure" },
```

Then add this line to `M.groups`, directly above `-- Groups added by later tasks go above this line.`:

```lua
  ["latex"] = { "lang.latex", "green" },
```

This task adds no toggle.

- [ ] **Install the plugin**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: exit 0. `lazy-lock.json` gains one line, `vimtex`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the eight `test_latex` tests among them, exit 0; where the latex parser has not been installed, seven pass and the highlighting test is skipped, and `scripts/check --full` installs the parser and runs it too. The foundation's `every key which-key can show has an icon from the database` passes, which shows every new description has its line in `M.keys`, and the languages plan's tree-sitter and language-server tests still pass with `with_regex` and `not_ft` in place.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/latex.lua lua/ach/plugins/latex.lua tests/test_latex.lua
git commit --only lua/ach/latex.lua lua/ach/plugins/latex.lua tests/test_latex.lua lua/ach/treesitter.lua lua/ach/lsp.lua lua/ach/need.lua lua/ach/icons.lua lazy-lock.json -m "feat(latex): VimTeX with Skim's forward and inverse search, builds into the cache, a project build hook on Space c b, and a description and icon for every VimTeX key"
```

---

### Task: Markdown

**Files:**
- Create: `lua/ach/preview.lua`, `lua/ach/plugins/markdown.lua`
- Modify: `lua/ach/icons.lua`, which gains a line in `M.keys` for `Space c p` and a line in `M.toggles` for `Space u m`; `lua/ach/need.lua`, which gains ImageMagick, MacTeX's pdflatex and Ghostscript; `lazy-lock.json`, which gains render-markdown.nvim and live-preview.nvim
- Test: `tests/test_markdown.lua`

**Interfaces:**
- Consumes: `require("ach.need").have(name)` from the Programs task, which prints `<label> is not installed. Install it with: <brew>` and returns false when the program is missing; `require("ach.icons").toggle(t)`, which gives a snacks toggle its icon from `M.toggles` and returns it; the global `Snacks` and its `toggle(opts)`; the foundation's blink.cmp spec, whose default sources are `lsp`, `path`, `snippets` and `buffer`, and its `SnacksImageMath` highlight, the text colour `#CBE0F0`; the languages plan's markdown row, which installs the `markdown` and `markdown_inline` parsers and the marksman server, and maps the `rmd` and `quarto` file types to the markdown parser; `scripts/check`; and `tests/run.lua`, which fires UIEnter so VeryLazy plugins load.
- Produces: `require("ach.preview")`: `file_types: string[]`; `opts(): table`, live-preview's settings; `inside(root: string, file: string): string?`, which returns `file` when its real location is inside `root`; `trusted(request: string): boolean`; `guard()`; `toggle()`; `graphics(): boolean`; `check_drawing(force?: boolean)`; and `attach(buf: integer)`.

Markdown is a way of writing formatted text in a plain text file. A line that starts with `#` is a heading, a line that starts with `-` is an item in a list, a word between two `*` is in italics, and a formula sits between dollar signs, as in `$x^2$`. Every README on GitHub is written in it, and so are the owner's book sources. A Markdown file reads well as it stands, but it reads better drawn: the heading in a larger, coloured style, the list with real bullets, the formula as mathematics rather than as the commands that describe it. This task draws Markdown in three places.

In the editor. render-markdown.nvim, the plugin LazyVim also uses, draws over the text. Each heading gets a coloured band across the window and an icon for its level, list items get bullets, the checkboxes `- [ ]` and `- [x]` become boxes, tables get borders, and a code block gets a shaded background as wide as its longest line. Nothing in the file changes. The drawing is made of extmarks, marks Neovim lays over the text without altering it, and the line under the cursor shows its plain text so it can be edited. `Space u m` switches the drawing off and on. render-markdown also adds suggestions to blink.cmp, the completion menu: after the `-` that starts a list item it offers the checkbox states, and after the `>` that starts a quotation it offers the callouts GitHub draws as coloured boxes, such as `[!NOTE]` and `[!WARNING]`.

Pictures and formulas in the editor. snacks.nvim's image module draws a picture the file names, such as `![the butterfly](figures/ntt.png)`, as the picture itself, under its line, and a formula as typeset mathematics. A terminal can show a picture only if it understands a picture protocol, a set of escape codes for sending one. Ghostty understands kitty's and macOS Terminal understands none, so this part works in Ghostty alone. A formula takes three programs. pdflatex, from MacTeX, typesets it into a PDF; ImageMagick turns the PDF into a picture, reading it through Ghostscript, which Homebrew installs along with MacTeX; and snacks sends the picture to Ghostty, drawn in the theme's text colour, `#CBE0F0`, so it reads as part of the page. The first Markdown file opened in Ghostty checks for all three and names any that is missing with the line that installs it, once per Neovim. Anywhere else it says nothing, since nothing there could be drawn. A picture whose name is a web address is fetched with curl to be drawn, so opening a Markdown file that names one reaches the web; a picture on disk never does.

In the browser. `Space c p` starts live-preview.nvim, a small web server inside Neovim, and opens the file in the default browser at `http://127.0.0.1:5500/<file>`. The page is drawn the way GitHub draws Markdown, with formulas typeset by KaTeX and diagrams drawn by Mermaid, and it follows the editor: each change is sent to the page as it is typed, and the page scrolls with the cursor. Everything the page loads comes from the plugin's own folder, so the preview works with no internet connection. `Space c p` again stops the server. The key is set on files whose names end in `.md` or `.markdown`, the two kinds live-preview shows as Markdown.

A web server answers anyone who can reach it, and live-preview's server, as written, answers more than it should. It is asked for a path, such as `/page.md`, joins that path onto the folder it serves, and sends back the file that names. A path may contain `..`, which means the folder above, so `/../../../etc/passwd` climbs out of the served folder to any file the owner can read, and so does `/%2e%2e/%2e%2e/etc/passwd`, where `%2e` is the code a web address uses for a dot. Three more holes sit beside that one. A file inside the folder can be a symbolic link, a pointer to a file somewhere else, and the server follows it wherever it leads. A web page from any other site, open in the same browser, can send the server requests too, because a browser lets any page send them to `127.0.0.1`; the browser's same-origin rule keeps that page from reading most answers, but not a WebSocket's, and a WebSocket, the open two-way connection the preview uses, is what carries each change typed. And a site can take this Mac's address: DNS rebinding points the attacker's own domain name at `127.0.0.1`, after which the browser treats the server's answers as the attacker's own and lets its page read them.

`guard` closes all four. Every path is checked against the real location of the file it names, found with `realpath`, which resolves every `..` and follows every link to its end, and the file is served only when that real location is inside the served folder, or inside the plugin's own `static` folder, which holds the page's styles and scripts. A path containing a NUL byte, the character that ends a string in C and so would cut the name short when the file is opened, is refused as well. Every request is also checked for the two headers a page cannot forge. `Host`, the name the browser was asked to reach, must be `127.0.0.1` or `localhost`, which DNS rebinding cannot fake, because the browser still sends the attacker's name. `Origin`, the site the asking page came from, must be the preview's own wherever it appears, and a WebSocket must carry one, as every browser's does. A refused request gets the server's own `404 Not Found` and nothing else.

The preview serves the folder the file is in and nothing above it, which is live-preview's `dynamic_root` setting. A preview started from a note deep in a large repository would otherwise put that repository's private folders one request away. The cost falls on a picture kept in a folder above the file, such as `../figures/ntt.png`: it is drawn in the editor, which reads the disk directly, but not in the browser, which may not climb out.

| Key | Description | What it does |
| --- | --- | --- |
| `Space c p` | Markdown Preview | Opens this file in the browser, served from this Mac alone, and keeps the page in step with the editor; pressed again, stops the preview |
| `Space u m` | Toggle Render Markdown | Switches the drawing of headings, lists, tables and code blocks in the editor off and on |

The suite never opens a browser. `vim.ui.open`, which live-preview calls to open one, is replaced by a recorder, and the tests talk to the preview server the way a browser would, over a plain connection to `127.0.0.1`.

- [ ] **Write the failing tests**

`tests/test_markdown.lua`:

```lua
-- Markdown. No test opens a browser. vim.ui.open, which live-preview calls to
-- open one, is replaced by a recorder, and the tests talk to the preview
-- server the way a browser would, over a plain connection to 127.0.0.1.

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level)
        said[#said + 1] = { msg = msg, level = level }
      end,
    },
  }, body)
  return said
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- A port nothing listens on. Binding port 0 asks the system for a free one;
-- the test reads which it chose and lets it go.
local function free_port()
  local tcp = assert(vim.uv.new_tcp())
  assert(tcp:bind("127.0.0.1", 0))
  local port = tcp:getsockname().port
  tcp:close()
  return port
end

-- Sends a request made of lines to the server on port, and waits up to three
-- seconds for the server to close the connection or for the reply to contain
-- want. Returns the reply.
local function fetch(port, lines, want)
  local tcp = assert(vim.uv.new_tcp())
  local reply, over = "", false
  tcp:connect("127.0.0.1", port, function(err)
    if err then
      over = true
      return
    end
    tcp:read_start(function(read_err, chunk)
      if chunk then
        reply = reply .. chunk
      end
      if read_err or not chunk then
        over = true
      end
    end)
    tcp:write(table.concat(lines, "\r\n") .. "\r\n\r\n")
  end)
  vim.wait(3000, function()
    return over or (want ~= nil and reply:find(want, 1, true) ~= nil)
  end, 20)
  if not tcp:is_closing() then
    tcp:close()
  end
  return reply
end

-- Asks for path the way a browser on this Mac would.
local function get(port, path)
  return fetch(port, { "GET " .. path .. " HTTP/1.1", "Host: 127.0.0.1:" .. port })
end

-- The three-digit status at the start of a reply, such as "404".
local function status(reply)
  return reply:match("^HTTP/1%.1 (%d%d%d)")
end

-- The options lazy.nvim passes to a plugin's setup, merged from every spec
-- that names the plugin.
local function opts_of(name)
  local plugin = assert(require("lazy.core.config").plugins[name], name .. " is not in the plugin list")
  return require("lazy.core.plugin").values(plugin, "opts", false)
end

-- A folder holding a secret and, beneath it, the site the preview serves: a
-- page, and a link pointing back up at the secret. Returns the folder and the
-- page.
local function site(t)
  local dir = t.tmpdir()
  vim.fn.mkdir(dir .. "/site", "p")
  vim.fn.writefile({ "SECRET" }, dir .. "/secret.txt")
  vim.fn.writefile({ "# Hello from the preview" }, dir .. "/site/page.md")
  assert(vim.uv.fs_symlink("../secret.txt", dir .. "/site/link.txt"))
  return dir, dir .. "/site/page.md"
end

-- Opens page and presses Space c p, with the preview on a free port and the
-- browser replaced by a recorder, then runs body with the port and the list
-- of addresses the browser was sent to. Stops the server afterwards, even
-- when body fails.
local function previewing(page, body)
  local port, opened = free_port(), {}
  local config = require("livepreview.config").config
  tidy(function()
    with({
      { config, "port", port },
      {
        vim.ui,
        "open",
        function(url)
          opened[#opened + 1] = url
        end,
      },
    }, function()
      local ok, err = pcall(function()
        vim.cmd.edit(page)
        press("<leader>cp")
        body(port, opened)
      end)
      require("livepreview").close()
      if not ok then
        error(err, 0)
      end
    end)
  end)
end

return {
  ["render-markdown leaves formulas to snacks and suggests through blink, and the preview stays local"] = function(t)
    local o = opts_of("render-markdown.nvim")
    t.eq(o.latex.enabled, false, "formulas are drawn by snacks alone")
    t.eq(o.completions.blink.enabled, true, "suggestions go through blink")
    t.ok(o.checkbox == nil or o.checkbox.enabled ~= false, "checkboxes are drawn")
    t.eq(o.file_types, { "markdown", "markdown.mdx", "rmd", "quarto" }, "the file types it draws")
    local lp = opts_of("live-preview.nvim")
    t.eq(lp.address, "127.0.0.1", "the preview listens on this Mac alone")
    t.eq(lp.dynamic_root, true, "and serves the file's own folder")
  end,

  ["headings are drawn in the editor, and Space u m turns the drawing off and on"] = function(t)
    -- Neovim ships the markdown parser, so this needs no install.
    local file = t.tmpdir() .. "/notes.md"
    vim.fn.writefile({ "# Heading", "", "Some text." }, file)
    local ns = vim.api.nvim_create_namespace("render-markdown.nvim")
    local function marks()
      return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
    end
    tidy(function()
      local ok, err = pcall(function()
        vim.cmd.edit(file)
        vim.wait(2000, function()
          return marks() > 0
        end, 20)
        t.ok(marks() > 0, "the heading is drawn")
        press("<leader>um")
        vim.wait(2000, function()
          return marks() == 0
        end, 20)
        t.eq(marks(), 0, "Space u m clears the drawing")
        press("<leader>um")
        vim.wait(2000, function()
          return marks() > 0
        end, 20)
        t.ok(marks() > 0, "and pressed again draws it again")
      end)
      -- Leaves the drawing on for the tests after this one.
      pcall(function()
        require("render-markdown").set(true)
      end)
      if not ok then
        error(err, 0)
      end
    end)
  end,

  ["a Markdown file gets render-markdown's suggestions as well as blink's own"] = function(t)
    local file = t.tmpdir() .. "/notes.md"
    vim.fn.writefile({ "- [ ] a task" }, file)
    tidy(function()
      vim.cmd.edit(file)
      local lib = require("blink.cmp.sources.lib")
      vim.wait(2000, function()
        return vim.tbl_contains(lib.get_enabled_provider_ids("default"), "markdown")
      end, 20)
      local ids = lib.get_enabled_provider_ids("default")
      for _, id in ipairs({ "markdown", "lsp", "path", "snippets", "buffer" }) do
        t.ok(vim.tbl_contains(ids, id), id .. " is offered")
      end
    end)
  end,

  ["snacks draws pictures and formulas in Markdown"] = function(t)
    t.eq(Snacks.image.config.enabled, true, "images are on")
    t.eq(Snacks.image.config.math.enabled, true, "and so are formulas")
    t.ok(vim.tbl_contains(Snacks.image.langs(), "markdown"), "Markdown is one of the languages it reads")
  end,

  ["formulas and pictures name the programs they need, once, and only where pictures can be shown"] = function(t)
    local P = require("ach.preview")
    -- What check_drawing says in a terminal named term_program, with uis as
    -- the screens attached and none of the three programs installed.
    local function check(term_program, uis, force)
      local said = notices(function()
        with({
          { vim.env, "TERM_PROGRAM", term_program },
          { vim.env, "TERM", "xterm-256color" },
          {
            vim.api,
            "nvim_list_uis",
            function()
              return uis
            end,
          },
          { vim.fn, "executable", only({}) },
        }, function()
          P.check_drawing(force)
        end)
      end)
      return vim.tbl_map(function(n)
        return n.msg
      end, said)
    end
    t.eq(check("ghostty", { {} }, true), {
      "ImageMagick is not installed. Install it with: brew install imagemagick",
      "MacTeX is not installed. Install it with: brew install --cask mactex",
      "Ghostscript is not installed. Install it with: brew install ghostscript",
    }, "Ghostty, with none of the three")
    t.eq(check("ghostty", { {} }), {}, "said once per Neovim")
    t.eq(check("Apple_Terminal", { {} }, true), {}, "macOS Terminal shows no pictures, so it needs none of them")
    t.eq(check("ghostty", {}, true), {}, "nor does a Neovim with no screen")
  end,

  ["Space c p serves the file on 127.0.0.1 alone and opens it in the browser, and pressed again stops"] = function(t)
    local _, page = site(t)
    previewing(page, function(port, opened)
      t.eq(opened, { ("http://127.0.0.1:%d/page.md"):format(port) }, "the browser is sent to the file on this Mac")
      local reply = get(port, "/page.md")
      t.eq(status(reply), "200", "the page is served")
      t.ok(reply:find("Hello from the preview", 1, true) ~= nil, "with the file's text")

      -- Every socket this Neovim listens on at port, one address per line,
      -- each line starting with n. -a makes lsof require all three conditions.
      local argv = { "lsof", "-nP", "-a", "-p", tostring(vim.fn.getpid()), "-iTCP:" .. port, "-sTCP:LISTEN", "-Fn" }
      local r = vim.system(argv, { text = true }):wait()
      local names = {}
      for line in vim.gsplit(r.stdout or "", "\n", { trimempty = true }) do
        if line:sub(1, 1) == "n" then
          names[#names + 1] = line
        end
      end
      t.eq(names, { "n127.0.0.1:" .. port }, "one listening socket, on the address the Mac uses for itself")

      press("<leader>cp")
      t.eq(require("livepreview").is_running(), false, "Space c p again stops the preview")
    end)
  end,

  ["the preview refuses every path that leads outside its folder"] = function(t)
    local dir, page = site(t)
    previewing(page, function(port)
      local climb = ("%2e%2e/"):rep(30)
      local refused = {
        "/%2e%2e/secret.txt",
        "/../secret.txt",
        "/" .. climb .. "etc/passwd",
        "/link.txt",
        "/page.md%00",
        "/live-preview.nvim/" .. climb .. dir:sub(2) .. "/secret.txt",
        "/live-preview.nvim/lua/livepreview/utils.lua",
      }
      for _, path in ipairs(refused) do
        local reply = get(port, path)
        t.eq(status(reply), "404", path)
        t.ok(
          not reply:find("SECRET", 1, true) and not reply:find("root:", 1, true),
          path .. " shows nothing of the file"
        )
      end
      local css = get(port, "/live-preview.nvim/static/katex/katex.min.css")
      t.eq(status(css), "200", "the page's own styles are still served")
    end)
  end,

  ["the preview answers only the pages it served itself"] = function(t)
    local _, page = site(t)
    previewing(page, function(port)
      local here = "127.0.0.1:" .. port
      local renamed = fetch(port, { "GET /page.md HTTP/1.1", "Host: attacker.example:" .. port })
      t.eq(status(renamed), "404", "a site that pointed its own name at this Mac")
      t.ok(not renamed:find("Hello", 1, true), "learns nothing of the page")

      -- Asks to turn the connection into a WebSocket, as the preview page
      -- does, from origin or from no site at all.
      local function upgrade(origin)
        local lines = {
          "GET / HTTP/1.1",
          "Host: " .. here,
          "Upgrade: websocket",
          "Connection: Upgrade",
          -- The sample key from the WebSocket standard, RFC 6455.
          "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
          "Sec-WebSocket-Version: 13",
        }
        if origin then
          lines[#lines + 1] = "Origin: " .. origin
        end
        return fetch(port, lines, "101 Switching Protocols")
      end
      t.eq(status(upgrade("https://attacker.example")), "404", "a WebSocket from another site")
      t.eq(status(upgrade(nil)), "404", "a WebSocket that names no site")
      t.eq(status(upgrade("http://" .. here)), "101", "the preview page's own WebSocket")
    end)
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_markdown`
Expected: `0 passed, 8 failed, 0 need a person, 0 skipped`, exit 1. The options test fails on `render-markdown.nvim is not in the plugin list`, the drawing test on `the heading is drawn`, the suggestions test on `markdown is offered`, and the snacks test on `images are on: expected true, got nil`. The test of the drawing programs fails on `module 'ach.preview' not found`, and the three server tests on `module 'livepreview.config' not found`.

- [ ] **Write the preview module**

`lua/ach/preview.lua`:

```lua
-- Markdown: live-preview's settings and the guard on its server, Space c p,
-- and the check for the programs that draw formulas and pictures in the
-- editor.
local M = {}

-- The file types drawn in the editor. rmd and quarto are Markdown with code
-- that R and Quarto run, and markdown.mdx is MDX, the website's Markdown with
-- components in it.
M.file_types = { "markdown", "markdown.mdx", "rmd", "quarto" }

-- live-preview's settings. dynamic_root serves the folder the file is in and
-- nothing above it.
function M.opts()
  return {
    picker = "snacks.picker",
    address = "127.0.0.1",
    port = 5500,
    browser = "default",
    dynamic_root = true,
    sync_scroll = true,
  }
end

-- file, when its real location, with every .. resolved and every link
-- followed, is root or inside it; otherwise nil. nil too for a name holding a
-- NUL byte, which would cut the name short when the file is opened. Runs inside
-- the server's network callback, where only plain Lua and vim.uv may be called.
function M.inside(root, file)
  if file:find("\0", 1, true) then
    return nil
  end
  local base, full = vim.uv.fs_realpath(root), vim.uv.fs_realpath(file)
  if not base or not full then
    return nil
  end
  local prefix = base == "/" and "/" or base .. "/"
  if full == base or vim.startswith(full, prefix) then
    return file
  end
  return nil
end

-- Whether a request came from a page this server sent. Host, the name the
-- browser was asked to reach, must be this Mac: a site that pointed its own
-- name at 127.0.0.1 still sends its own name here. Origin, the site the asking
-- page came from, must be the preview's own wherever it appears, and a
-- WebSocket must carry one, as every browser's does. Runs inside the network
-- callback, so it uses plain Lua.
function M.trusted(request)
  local head = request:lower()
  local host = head:match("\r\nhost:[ \t]*([^\r\n]-)[ \t]*\r")
  if not host then
    return false
  end
  local name = host:match("^(.*):%d+$") or host
  if name ~= "127.0.0.1" and name ~= "localhost" then
    return false
  end
  local origin = head:match("\r\norigin:[ \t]*([^\r\n]-)[ \t]*\r")
  if origin then
    return origin == "http://" .. host
  end
  -- live-preview treats any request holding this text as a WebSocket.
  return not request:find("Upgrade: websocket", 1, true)
end

local guarded = false

-- Wraps live-preview's server so it serves a file only from inside the folder
-- it was started on, or from its own static folder, which holds the page's
-- styles and scripts, and answers only the requests M.trusted accepts. Every
-- refusal is the server's own 404. Calling it again does nothing.
function M.guard()
  if guarded then
    return
  end
  guarded = true
  local Server = require("livepreview.server").Server
  local handler = require("livepreview.server.handler")
  local static = vim.fs.joinpath(require("livepreview.utils").get_plugin_path(), "static")
  local routes, request = Server.routes, handler.request
  -- An empty name opens no file, so the server answers 404.
  Server.routes = function(self, path)
    local file = routes(self, path)
    return M.inside(self.webroot, file) or M.inside(static, file) or ""
  end
  -- A path of one NUL byte is refused by the routes above.
  handler.request = function(client, req)
    if M.trusted(req) then
      return request(client, req)
    end
    return { path = "\0", accept = "" }
  end
end

-- Space c p: starts the preview of this file and opens it in the browser, or
-- stops the preview when one is running.
function M.toggle()
  local lp = require("livepreview")
  if lp.is_running() then
    lp.close()
  else
    vim.cmd("LivePreview start")
  end
end

-- Whether this terminal can show pictures: Ghostty, or kitty, whose picture
-- protocol Ghostty speaks. False for a Neovim with no screen.
function M.graphics()
  if #vim.api.nvim_list_uis() == 0 then
    return false
  end
  local term = vim.env.TERM or ""
  return vim.env.TERM_PROGRAM == "ghostty"
    or term:find("ghostty", 1, true) ~= nil
    or term:find("kitty", 1, true) ~= nil
end

local checked = false

-- Names any program missing for formulas and pictures, with the line that
-- installs it: once per Neovim, and only where pictures can be shown. force
-- checks again.
function M.check_drawing(force)
  if (checked and not force) or not M.graphics() then
    return
  end
  checked = true
  local need = require("ach.need")
  need.have("magick")
  need.have("pdflatex")
  need.have("gs")
end

-- Runs on every file in M.file_types. Space c p goes only on files whose
-- names end in .md or .markdown, the two kinds live-preview shows as Markdown.
function M.attach(buf)
  M.check_drawing()
  local name = vim.api.nvim_buf_get_name(buf)
  if name:match("%.md$") or name:match("%.markdown$") then
    vim.keymap.set("n", "<leader>cp", M.toggle, { buffer = buf, desc = "Markdown Preview" })
  end
end

return M
```

`guard` replaces two functions inside live-preview rather than copying its server, so a plugin update keeps working as long as those two keep their names and shapes: `Server:routes(path)`, which returns the file a path names, and `handler.request(client, request)`, which returns the path asked for. The server tests fail if either changes.

- [ ] **Write the plugin spec**

`lua/ach/plugins/markdown.lua`:

```lua
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/lang/markdown.lua.
-- Markdown: render-markdown.nvim draws headings, lists, tables and code blocks
-- in the editor, snacks draws pictures and formulas, and live-preview.nvim
-- shows the page in the browser. The preview's guard, Space c p and the check
-- for the drawing programs live in ach.preview.
local P = require("ach.preview")
local I = require("ach.icons")

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = P.file_types,
    opts = {
      file_types = P.file_types,
      completions = { blink = { enabled = true } },
      -- snacks draws formulas as pictures, and two drawings would overlap.
      latex = { enabled = false },
      code = { sign = false, width = "block", right_pad = 1 },
      heading = { sign = false },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      I.toggle(Snacks.toggle({
        id = "render_markdown",
        name = "Render Markdown",
        get = function()
          return require("render-markdown").get()
        end,
        set = function(state)
          require("render-markdown").set(state)
        end,
      })):map("<leader>um")
    end,
  },
  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    opts = P.opts(),
    -- Runs at start, so Space c p is on every Markdown file before the plugin
    -- itself has loaded.
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ach_markdown", { clear = true }),
        pattern = P.file_types,
        callback = function(ev)
          require("ach.preview").attach(ev.buf)
        end,
      })
    end,
    -- The guard goes on as the plugin loads, before its server can start.
    config = function(_, opts)
      require("livepreview.config").set(opts)
      P.guard()
    end,
  },
  {
    "folke/snacks.nvim",
    opts = { image = { enabled = true } },
  },
}
```

live-preview's own `setup` is marked deprecated in favour of `require("livepreview.config").set`, which the spec calls instead. snacks keeps its default image settings: pictures drawn in the line below the one that names them, and formulas typeset with the `amsmath`, `amssymb`, `amsfonts`, `amscd` and `mathtools` packages, the ones a formula in the PQC sources reaches for.

- [ ] **List ImageMagick, pdflatex and Ghostscript**

In `lua/ach/need.lua`, add above `-- Programs added by later tasks go above this line.`:

```lua
  {
    name = "magick",
    label = "ImageMagick",
    brew = "brew install imagemagick",
    purpose = "turning pictures and formulas into images the terminal can show",
  },
  {
    name = "pdflatex",
    label = "MacTeX",
    brew = "brew install --cask mactex",
    purpose = "typesetting the formulas in Markdown files",
  },
  {
    name = "gs",
    label = "Ghostscript",
    brew = "brew install ghostscript",
    purpose = "letting ImageMagick read the PDF a formula is typeset into",
  },
```

Homebrew's MacTeX depends on its `ghostscript` formula, so installing MacTeX brings `gs` too; the entry is there for a MacTeX installed some other way.

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add above `-- Keys added by later tasks go above this line.`:

```lua
  -- Markdown
  ["Markdown Preview"] = { "ui.preview", "cyan" },
```

And above `-- Toggles added by later tasks go above this line.`:

```lua
  render_markdown = "lang.markdown",
```

The keyword rule `{ "preview", "ui.preview", "cyan" }` would already give `Markdown Preview` this icon; the line in `M.keys` makes it explicit, as every key in this plan is.

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: exit 0. `lazy-lock.json` gains two lines, `live-preview.nvim` and `render-markdown.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, the eight `test_markdown` tests among them, exit 0. The foundation's `every key which-key can show has an icon from the database` passes too, which shows `Markdown Preview` has its line in `M.keys`, and so does its `every toggle and every which-key group draws the database's icon`, which shows `render_markdown` has its line in `M.toggles`. The Programs task's `every have() in the configuration names a program in the list` passes with `magick`, `pdflatex` and `gs` in the list.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/preview.lua lua/ach/plugins/markdown.lua tests/test_markdown.lua
git commit --only lua/ach/preview.lua lua/ach/plugins/markdown.lua tests/test_markdown.lua lua/ach/need.lua lua/ach/icons.lua lazy-lock.json -m "feat(markdown): render-markdown in the editor, snacks pictures and formulas, and a browser preview on Space c p guarded against paths outside its folder and requests from other sites"
```

---

### Task: Intel's Manual and the News Reader

**Files:**
- Create: `lua/ach/x86.lua`, `lua/ach/news.lua`, `lua/ach/plugins/tools.lua`
- Modify: `lua/ach/icons.lua`, which gains two lines in `M.keys`, for `Space c x` and `Space N`; `lua/ach/need.lua`, which gains Poppler's `pdftotext` and newsboat
- Test: `tests/test_tools.lua`

**Interfaces:**
- Consumes: `require("ach.need").have(name)` from the Programs task, which prints `<label or name> is not installed. Install it with: <brew>` and returns false when the program is missing, and the LaTeX task's `displayline` entry in its list, which stands for Skim, since Skim's cask puts `displayline` on the path; the global `Snacks` and its `terminal.toggle(cmd, opts)`; the foundation's `Space c` code group; `scripts/check`, whose `t.full` is true under `--full`; and `tests/run.lua`, which fires UIEnter so VeryLazy plugins load.
- Produces: `require("ach.x86")`: `pdf: string`, `source: string`, `cache: string`, `script: string[]`, `parse(text: string): table<string, integer>`, `index(pdf: string, done: fun(index: table<string, integer>?))`, `open(pdf: string, page: integer)` and `lookup()`. `require("ach.news")`: `urls(): string` and `open()`.

A processor runs a program as a long list of instructions, each one a small step: add two numbers, copy a value from memory, jump to another part of the program if the last result was zero. Assembly language writes each instruction as a short name, its mnemonic, followed by what it works on, so `add rax, 1` adds one to `rax`, a register, one of the few storage slots inside the processor itself. Intel's processors and AMD's understand the same instruction set, called x86, and Intel documents every instruction in its Software Developer's Manual, a free PDF several thousand pages long. Each instruction has its own pages, and each such page opens the same way: a heading such as `ADD—Add`, and just below it a table whose first column is headed Opcode, for the numbers the processor actually reads.

`Space c x` opens that manual in Skim at the page for the instruction under the cursor. With the cursor on `add`, Skim comes to the front at ADD's first page. On a word that is not an instruction, such as `rax`, it lists every instruction the manual describes and opens the one picked. Intel describes some instructions as a family under one heading: `Jcc` covers every conditional jump, cc standing for a condition code, so `ja` (jump if above), `jne` (jump if not equal) and every other conditional jump open the `Jcc` pages, and `CMOVcc`, `SETcc` and the prefetch and broadcast families work the same way.

Finding the pages is the work of `pdftotext`, a program from the Poppler PDF library that turns a PDF into plain text and ends each page with a form feed, a control character that means "new page", so counting form feeds gives the page number. A page belongs to an instruction when one of its first two lines is a heading, a run of names followed by an em dash, and one of the three lines after the heading starts with the word Opcode. That rule, and the list of families, come from x86-lookup, a lookup tool for the same manual whose author released it into the public domain. Reading the whole manual takes a while, so the first `Space c x` says so and the next ones are instant: the pages found are saved as a small file in `~/.cache/nvim/x86-lookup/`, named after the manual's size and date, so a newer manual saved over the old one is read again.

Skim is the viewer because macOS's own Preview cannot be told to open a particular page, and Skim can, through AppleScript, macOS's language for one app telling another what to do. `osascript` runs the script. The manual's location and the page number reach the script as arguments rather than being pasted into its text, so a file name with a quotation mark in it cannot break the script or change what it does. The first time, macOS asks whether Ghostty may control Skim; allowing it once is enough.

The manual itself is not in this repository, because it is Intel's to publish. Intel's page at `https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html` offers all the volumes combined into one PDF, and that file belongs at `~/.local/state/x86-lookup/intel-sdm.pdf`. When it is not there, `Space c x` says where it goes and where to get it, and does nothing else.

`Space N` opens newsboat, a feed reader. A feed is a list a website publishes of its newest articles, in a format called RSS or Atom, and a feed reader fetches many of them and shows the articles together. newsboat runs in a terminal, so `Space N` opens it in a terminal floating over the editor; pressed again while the window is hidden, it brings back the same newsboat rather than starting a second, which would refuse to run while the first holds its lock on the article store. The feeds are a plain file, one address per line, which newsboat reads from `~/.config/newsboat/urls` when the folder `~/.config/newsboat` exists, and from `~/.newsboat/urls` when it does not. This repository names no feeds, since it is public and a reading list is personal; the owner's private setup writes a list of research feeds: IACR's cryptography preprints and arXiv's lists for cryptography and security and for hardware architecture. With no list, `Space N` says which file to write.

Inside newsboat, the arrow keys move, `Enter` opens a feed or an article, `r` reloads the selected feed and `R` every feed, `n` jumps to the next unread article, `o` opens the article in the browser, `?` lists every key, and `q` goes back one screen and, from the list of feeds, quits newsboat, which closes the window. To step away without quitting, press `Esc` twice quickly, which hands the keys from newsboat back to Neovim, then `q`, which hides the window with newsboat still running; `Space N` brings it back. newsboat opens articles with the program named by the `BROWSER` setting in the environment and, with none, tries `lynx`, a text browser macOS does not have, so `Space N` sets `BROWSER` to macOS's `open`, which hands the address to the default browser. A browser named in newsboat's own configuration still wins.

| Key | Description | What it does |
| --- | --- | --- |
| `Space c x` | x86 Manual | Opens Intel's manual in Skim at the page for the instruction under the cursor; on any other word, lists every instruction to pick one |
| `Space N` | News | Opens newsboat, a feed reader, in a window floating over the editor; `q` inside newsboat goes back a screen and, from the list of feeds, quits it |

The suite opens neither Skim nor newsboat. `vim.system`, which runs `pdftotext` and `osascript`, and snacks' `terminal.toggle`, which opens newsboat, are replaced by recorders, and the one test that reads the real manual runs only under `scripts/check --full`.

- [ ] **Write the failing tests**

`tests/test_tools.lua`:

```lua
-- Intel's manual on Space c x and newsboat on Space N. No test opens Skim or
-- newsboat: vim.system and snacks' terminal.toggle are replaced by recorders,
-- and the one test that reads the real manual runs only under --full.

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A stand-in for vim.fn.executable that finds only the programs in found.
local function only(found)
  return function(name)
    return found[name] and 1 or 0
  end
end

-- Runs body with vim.notify recording, and returns what it recorded.
local function notices(body)
  local said = {}
  with({
    {
      vim,
      "notify",
      function(msg, level)
        said[#said + 1] = { msg = msg, level = level }
      end,
    },
  }, body)
  return said
end

-- Runs the key lhs in mode, as pressing it would, through its callback.
local function press(lhs, mode)
  local m = vim.fn.maparg(lhs, mode or "n", false, true)
  assert(m.callback, ("no key %s in mode %s"):format(lhs, mode or "n"))
  m.callback()
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- Nine pages of made-up manual, laid out the way pdftotext prints the real
-- one: a form feed ends every page.
local function manual()
  return table.concat({
    -- 1: the title page, with no heading.
    "Intel 64 and IA-32 Architectures Software Developer's Manual",
    -- 2: a heading on the first line and Opcode on the next.
    "ADD—Add\nOpcode Instruction Op/En 64-bit Mode",
    -- 3: ADD's second page, which also carries its heading; the first is kept.
    "ADD—Add\nOpcode Instruction Op/En 64-bit Mode",
    -- 4: a family, with a blank line before Opcode.
    "CMOVcc—Conditional Move\n\nOpcode Instruction",
    -- 5: a running header above the heading, which names four instructions.
    "INSTRUCTION SET REFERENCE, A-L\nINT n/INTO/INT3/INT1—Call to Interrupt Procedure\nOpcode",
    -- 6: a heading with Opcode four lines below it, too far to count.
    "OPERATION—How to Read the Tables\nOne\nTwo\nThree\nOpcode is the first column",
    -- 7: the prefetch family.
    "PREFETCHh—Prefetch Data Into Caches\nOpcode",
    -- 8: two hyphens for the dash, and Opcode three lines below.
    "XOR -- Logical Exclusive OR\nVol. 2D\nTable 4-1\nOpcode",
    -- 9: the jumps, with opcode in lower case and indented.
    "Jcc—Jump if Condition Is Met\n   opcode instruction",
  }, "\f") .. "\f"
end

-- Writes a file standing in for the manual, so it has a size and a date.
local function stand_in(t, text)
  local pdf = t.tmpdir() .. "/sdm.pdf"
  vim.fn.writefile({ text or "a stand-in for the manual" }, pdf)
  return pdf
end

return {
  ["the index finds each instruction's first page, expands families and skips other pages"] = function(t)
    local index = require("ach.x86").parse(manual())
    t.eq(index.add, 2, "ADD's first page")
    t.eq(index.cmovne, 4, "CMOVNE, from the CMOVcc family")
    t.eq(index.cmovz, 4, "CMOVZ, from the same family")
    t.eq(index.cmovcc, nil, "a family's own name is not an instruction")
    for _, name in ipairs({ "int", "into", "int3", "int1" }) do
      t.eq(index[name], 5, name .. ", one of four names in a heading under a running header")
    end
    t.eq(index.operation, nil, "a heading with no Opcode close below it")
    t.eq(index.prefetch, 7, "PREFETCH")
    t.eq(index.prefetchnta, 7, "PREFETCHNTA")
    t.eq(index.xor, 8, "XOR, with two hyphens for the dash")
    t.eq(index.ja, 9, "JA, with opcode in lower case")
    t.eq(index.jrcxz, 9, "JRCXZ, one of the jumps beyond the condition codes")
    t.eq(index.intel, nil, "the title page")
  end,

  ["the index is built once, read back after that, and built again when the manual changes"] = function(t)
    local x86 = require("ach.x86")
    local pdf = stand_in(t)
    local runs, reply = {}, { code = 0, stdout = manual(), stderr = "" }
    local function build()
      local got, over = nil, false
      x86.index(pdf, function(index)
        got, over = index, true
      end)
      vim.wait(2000, function()
        return over
      end, 10)
      t.ok(over, "the index is handed back")
      return got
    end
    with({
      { x86, "cache", t.tmpdir() .. "/cache" },
      {
        vim,
        "system",
        function(cmd, _, on_exit)
          runs[#runs + 1] = cmd
          on_exit(reply)
          return {}
        end,
      },
    }, function()
      local said = notices(function()
        t.eq(build().add, 2, "the first call reads the manual")
      end)
      t.eq(runs, { { "pdftotext", "-q", "-enc", "UTF-8", pdf, "-" } }, "with pdftotext, printing to its output")
      t.eq(said[1].msg, "Reading Intel's manual to index it. This happens once.", "and says so")
      t.eq(build().add, 2, "the second call has the index")
      t.eq(#runs, 1, "without reading the manual again")
      vim.fn.writefile({ "a newer manual, which is longer than the first" }, pdf)
      reply = { code = 1, stdout = "", stderr = "Syntax Error: Couldn't find trailer dictionary" }
      local failed = notices(function()
        t.eq(build(), nil, "a manual pdftotext cannot read gives no index")
      end)
      t.eq(#runs, 2, "a changed manual is read again")
      t.eq(failed[#failed].level, vim.log.levels.ERROR, "the failure is an error")
      local msg = failed[#failed].msg
      t.ok(msg:find("pdftotext could not read " .. pdf, 1, true) ~= nil, "naming the program and the file")
    end)
  end,

  ["Space c x opens the manual at the instruction under the cursor, and otherwise asks which"] = function(t)
    local x86 = require("ach.x86")
    local pdf = stand_in(t)
    local runs, asked = {}, nil
    tidy(function()
      with({
        { vim.fn, "executable", only({ pdftotext = true, displayline = true }) },
        { x86, "pdf", pdf },
        {
          x86,
          "index",
          function(_, done)
            done({ xor = 8, add = 2 })
          end,
        },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
        {
          vim.ui,
          "select",
          function(items, opts, choose)
            asked = { items = items, prompt = opts.prompt }
            choose("xor")
          end,
        },
      }, function()
        vim.cmd.enew()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "  add rax, 1" })
        vim.api.nvim_win_set_cursor(0, { 1, 3 })
        press("<leader>cx")
        t.eq(#runs, 1, "one program runs")
        t.eq(runs[1][1], "osascript", "osascript")
        t.eq(vim.list_slice(runs[1], #runs[1] - 1), { pdf, "2" }, "asking for ADD's page")
        t.eq(asked, nil, "and nothing is asked")
        vim.api.nvim_win_set_cursor(0, { 1, 7 })
        press("<leader>cx")
        t.eq(asked and asked.items, { "add", "xor" }, "on rax, every instruction is offered, in order")
        t.eq(asked and asked.prompt, "x86 instruction", "under a prompt that says what to pick")
        t.eq(#runs, 2, "and the pick runs osascript again")
        t.eq(vim.list_slice(runs[2], #runs[2] - 1), { pdf, "8" }, "for XOR's page")
      end)
    end)
  end,

  ["Space c x without the manual says where to put it and runs nothing"] = function(t)
    local x86 = require("ach.x86")
    local missing = t.tmpdir() .. "/intel-sdm.pdf"
    local runs, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({ pdftotext = true, displayline = true }) },
        { x86, "pdf", missing },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
      }, function()
        vim.cmd.enew()
        said = notices(function()
          press("<leader>cx")
        end)
      end)
    end)
    t.eq(#runs, 0, "nothing runs")
    t.eq(#said, 1, "one notice")
    t.eq(said[1].level, vim.log.levels.WARN, "a warning")
    t.ok(said[1].msg:find(missing, 1, true) ~= nil, "naming where the manual goes")
    t.ok(said[1].msg:find(x86.source, 1, true) ~= nil, "and where Intel publishes it")
  end,

  ["Space c x names Poppler and Skim when they are missing, and runs nothing"] = function(t)
    require("ach.x86")
    local runs, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({}) },
        {
          vim,
          "system",
          function(cmd)
            runs[#runs + 1] = cmd
            return {}
          end,
        },
      }, function()
        vim.cmd.enew()
        said = notices(function()
          press("<leader>cx")
        end)
      end)
    end)
    t.eq(
      vim.tbl_map(function(s)
        return s.msg
      end, said),
      {
        "Poppler is not installed. Install it with: brew install poppler",
        "Skim is not installed. Install it with: brew install --cask skim",
      },
      "both install lines"
    )
    t.eq(#runs, 0, "nothing runs")
  end,

  ["Skim is asked for the page through osascript, with the file and the page as arguments"] = function(t)
    local x86 = require("ach.x86")
    local odd = "/tmp/it's a \"manual\".pdf"
    local runs = {}
    with({
      {
        vim,
        "system",
        function(cmd)
          runs[#runs + 1] = cmd
          return {}
        end,
      },
    }, function()
      x86.open(odd, 42)
    end)
    local cmd = runs[1]
    t.eq(cmd[1], "osascript", "osascript runs the script")
    local lines = {}
    for i = 2, #cmd - 2, 2 do
      t.eq(cmd[i], "-e", "each line of the script follows -e")
      lines[#lines + 1] = cmd[i + 1]
    end
    t.eq(lines, x86.script, "the script, line by line")
    local script = table.concat(lines, "\n")
    t.ok(script:find("go theDoc to page", 1, true) ~= nil, "which tells Skim to go to a page")
    t.eq({ cmd[#cmd - 1], cmd[#cmd] }, { odd, "42" }, "the file and the page come last, as arguments")
    t.eq(script:find("it's", 1, true), nil, "and the file's name is nowhere in the script")
  end,

  ["the AppleScript that asks Skim for a page compiles"] = function(t)
    local x86 = require("ach.x86")
    if vim.fn.executable("displayline") ~= 1 then
      t.skip("Skim is not installed, and the script uses Skim's own commands")
    end
    local argv = { "osacompile", "-o", t.tmpdir() .. "/x86.scpt" }
    for _, line in ipairs(x86.script) do
      vim.list_extend(argv, { "-e", line })
    end
    local r = vim.system(argv, { text = true }):wait(30000)
    t.eq(r.code, 0, "osacompile accepts it: " .. (r.stderr or ""))
  end,

  ["the real manual gives a page for the instructions looked up most"] = function(t)
    if not t.full then
      t.skip("reads all of Intel's manual, which takes a while; scripts/check --full runs it")
    end
    local x86 = require("ach.x86")
    if vim.fn.executable("pdftotext") ~= 1 then
      t.human("install Poppler, which reads the manual: brew install poppler")
    end
    if vim.fn.filereadable(x86.pdf) ~= 1 then
      t.human(("save Intel's combined manual from %s as %s"):format(x86.source, x86.pdf))
    end
    local got, over = nil, false
    with({ { x86, "cache", t.tmpdir() } }, function()
      notices(function()
        x86.index(x86.pdf, function(index)
          got, over = index, true
        end)
        vim.wait(180000, function()
          return over
        end, 200)
      end)
    end)
    t.ok(over, "the manual is read within three minutes")
    t.ok(got ~= nil, "pdftotext reads it")
    for _, name in ipairs({ "add", "mov", "xor", "cmovne", "ja", "int3", "prefetchnta", "vbroadcastss" }) do
      t.ok(type(got[name]) == "number", name .. " has a page")
    end
    t.ok(got.add < got.xor, "ADD comes before XOR, as the manual is in alphabetical order")
  end,

  ["Space N opens newsboat in a floating terminal"] = function(t)
    local home = t.tmpdir()
    vim.fn.mkdir(home .. "/.newsboat", "p")
    vim.fn.writefile({ "https://rss.arxiv.org/rss/cs.AR" }, home .. "/.newsboat/urls")
    local opened = {}
    tidy(function()
      with({
        { vim.env, "HOME", home },
        { vim.env, "XDG_CONFIG_HOME", nil },
        { vim.env, "BROWSER", nil },
        { vim.fn, "executable", only({ newsboat = true }) },
        {
          Snacks.terminal,
          "toggle",
          function(cmd, opts)
            opened[#opened + 1] = { cmd = cmd, opts = opts }
          end,
        },
      }, function()
        press("<leader>N")
      end)
    end)
    t.eq(#opened, 1, "one terminal")
    t.eq(opened[1].cmd, "newsboat", "running newsboat")
    t.eq(opened[1].opts.win.position, "float", "in a floating window")
    t.eq(opened[1].opts.cwd, home, "started from the home folder, so pressing again finds the same one")
    t.eq(opened[1].opts.env, { BROWSER = "open" }, "and articles open in the default browser")
  end,

  ["Space N without newsboat prints the line that installs it and opens nothing"] = function(t)
    local opened, said = {}, {}
    tidy(function()
      with({
        { vim.fn, "executable", only({}) },
        {
          Snacks.terminal,
          "toggle",
          function(cmd)
            opened[#opened + 1] = cmd
          end,
        },
      }, function()
        said = notices(function()
          press("<leader>N")
        end)
      end)
    end)
    t.eq(said, {
      { msg = "newsboat is not installed. Install it with: brew install newsboat", level = vim.log.levels.WARN },
    }, "the install line")
    t.eq(#opened, 0, "nothing opens")
  end,

  ["the feed list is looked for where newsboat looks, and Space N names it when it is missing"] = function(t)
    local news = require("ach.news")
    local home = t.tmpdir()
    local opened, said = {}, {}
    with({
      { vim.env, "HOME", home },
      { vim.env, "XDG_CONFIG_HOME", nil },
    }, function()
      t.eq(news.urls(), home .. "/.newsboat/urls", "with no ~/.config/newsboat, the older place")
      vim.fn.mkdir(home .. "/.config/newsboat", "p")
      t.eq(news.urls(), home .. "/.config/newsboat/urls", "with that folder, the folder")
      vim.env.XDG_CONFIG_HOME = home .. "/elsewhere"
      t.eq(news.urls(), home .. "/.newsboat/urls", "XDG_CONFIG_HOME moves where the folder is looked for")
      vim.fn.mkdir(home .. "/elsewhere/newsboat", "p")
      t.eq(news.urls(), home .. "/elsewhere/newsboat/urls", "and the folder there is used")
      vim.env.XDG_CONFIG_HOME = "relative"
      t.eq(news.urls(), home .. "/.config/newsboat/urls", "a relative XDG_CONFIG_HOME is ignored, as newsboat does")
      tidy(function()
        with({
          { vim.fn, "executable", only({ newsboat = true }) },
          {
            Snacks.terminal,
            "toggle",
            function(cmd)
              opened[#opened + 1] = cmd
            end,
          },
        }, function()
          said = notices(function()
            press("<leader>N")
          end)
        end)
      end)
    end)
    t.eq(#opened, 0, "with no feed list, nothing opens")
    t.eq(#said, 1, "one notice")
    t.eq(said[1].level, vim.log.levels.WARN, "a warning")
    t.ok(said[1].msg:find(home .. "/.config/newsboat/urls", 1, true) ~= nil, "naming the file newsboat reads")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_tools`
Expected: `0 passed, 10 failed, 0 need a person, 1 skipped`, exit 1. The seven Space c x tests that run fail on `module 'ach.x86' not found`, and the test of the real manual skips, since it runs only under `--full`. The two Space N key tests fail on `no key <leader>N in mode n`, and the feed list test on `module 'ach.news' not found`.

- [ ] **Write the manual lookup**

`lua/ach/x86.lua`:

```lua
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
  "a", "ae", "b", "be", "c", "e", "g", "ge", "l", "le", "na", "nae", "nb", "nbe", "nc",
  "ne", "ng", "nge", "nl", "nle", "no", "np", "ns", "nz", "o", "p", "pe", "po", "s", "z",
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
local function heading(line)
  return line:match("^%s*([%w/ \t]+)—") or line:match("^%s*([%w/ \t]+)%-%-")
end

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
  local ok, cached = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
  end)
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
```

The test of the real manual names eight instructions rather than counting them all, because the count changes from one edition of the manual to the next, and those eight cover a plain instruction, a family, a heading that names several instructions, and an AVX instruction from a family.

- [ ] **Write the news reader**

`lua/ach/news.lua`:

```lua
-- Space N: newsboat, a feed reader, in a floating terminal. The feeds are
-- newsboat's own list, which this repository does not write.
local M = {}

-- The feed list newsboat reads, by newsboat's own rule: urls in the newsboat
-- folder under XDG_CONFIG_HOME, or ~/.config when that is unset or not an
-- absolute path, if that folder exists, and ~/.newsboat/urls if it does not.
---@return string
function M.urls()
  local base = vim.env.XDG_CONFIG_HOME
  if not base or base:sub(1, 1) ~= "/" then
    base = vim.fs.joinpath(vim.env.HOME, ".config")
  end
  local folder = vim.fs.joinpath(base, "newsboat")
  if vim.fn.isdirectory(folder) == 1 then
    return vim.fs.joinpath(folder, "urls")
  end
  return vim.fs.joinpath(vim.env.HOME, ".newsboat", "urls")
end

-- Space N. The terminal is toggled rather than opened, and always from the
-- home folder, so pressing again finds the same newsboat instead of starting
-- a second one, which would refuse to run while the first holds its lock.
function M.open()
  if not require("ach.need").have("newsboat") then
    return
  end
  local urls = M.urls()
  if vim.fn.filereadable(urls) ~= 1 then
    vim.notify(
      ("newsboat has no feeds to read. Put one feed address per line in %s"):format(urls),
      vim.log.levels.WARN
    )
    return
  end
  Snacks.terminal.toggle("newsboat", {
    cwd = vim.env.HOME,
    -- o in newsboat opens an article with BROWSER, and with none it tries
    -- lynx, which macOS does not have. open hands the address to the default
    -- browser. A browser set in newsboat's own config still wins.
    env = { BROWSER = vim.env.BROWSER or "open" },
    win = { position = "float", border = "rounded", title = " News " },
  })
end

return M
```

newsboat is started through snacks rather than a plain `:terminal`, so it gets snacks' floating window, with the theme's border and a title. snacks closes the window when newsboat quits normally, and when newsboat exits with an error it keeps the window open and says so, which leaves newsboat's own message on screen to read.

- [ ] **Write the keys**

`lua/ach/plugins/tools.lua`:

```lua
-- Two tools that are not about the file being edited: Intel's manual on
-- Space c x and the feed reader on Space N. Both are keys on snacks.nvim,
-- which is already loaded at start, so neither adds a plugin.
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>cx",
        function()
          require("ach.x86").lookup()
        end,
        desc = "x86 Manual",
      },
      {
        "<leader>N",
        function()
          require("ach.news").open()
        end,
        desc = "News",
      },
    },
  },
}
```

lazy.nvim merges the `keys` of every spec that names snacks.nvim, the way the Git task adds its keys, so this file adds two keys without touching the foundation's snacks spec. `Space c x` is set in every buffer, not only in assembly files, because an instruction is just as often met in a C file's inline assembly or in a note.

- [ ] **List pdftotext and newsboat**

In `lua/ach/need.lua`, add above `-- Programs added by later tasks go above this line.`:

```lua
  {
    name = "pdftotext",
    label = "Poppler",
    brew = "brew install poppler",
    purpose = "reading Intel's manual to find each instruction's page",
  },
  {
    name = "newsboat",
    brew = "brew install newsboat",
    purpose = "the feed reader on Space N",
  },
```

Skim is listed already, by the LaTeX task, under its `displayline` program.

- [ ] **Give the keys their icons**

In `lua/ach/icons.lua`, add above `-- Keys added by later tasks go above this line.`:

```lua
  -- Intel's manual and the news reader
  ["x86 Manual"] = { "hardware.cpu", "blue" },
  ["News"] = { "ui.news", "orange" },
```

The manual's key gets the processor chip, in the blue the code keys share, and the news reader the newspaper, in orange.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. `test_tools` reports ten passed and one skipped, the test of the real manual, which runs under `scripts/check --full` and, until the manual is saved at `~/.local/state/x86-lookup/intel-sdm.pdf`, reports that it needs a person, naming the address to fetch it from. The foundation's `every key which-key can show has an icon from the database` passes too, which shows `x86 Manual` and `News` have their lines in `M.keys`, and the Programs task's `every have() in the configuration names a program in the list` passes with `pdftotext` and `newsboat` in the list. No plugin is added, so `lazy-lock.json` does not change.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/x86.lua lua/ach/news.lua lua/ach/plugins/tools.lua tests/test_tools.lua
git commit --only lua/ach/x86.lua lua/ach/news.lua lua/ach/plugins/tools.lua tests/test_tools.lua lua/ach/need.lua lua/ach/icons.lua -m "feat(tools): open Intel's manual in Skim at the instruction under the cursor on Space c x, and newsboat in a floating terminal on Space N"
```

---

### Task: Ghostty

**Files:**
- Create: `ghostty/config.ghostty`
- Test: `tests/test_ghostty.lua`

**Interfaces:**
- Consumes: the foundation's `require("ach.palette")`, whose `bg`, `fg` and `bg_visual` are the navy, the text colour and the selection colour, and `require("ach.contrast").ratio(hex_a, hex_b)`, the WCAG 2 contrast ratio; the colour scheme `tokyonight-night`, loaded at startup, which sets `vim.g.terminal_color_0` to `vim.g.terminal_color_15` as it loads; and the test helper's `t.root`, `t.skip` and `t.human`.
- Produces: `ghostty/config.ghostty`, which the Mac's setup links from `~/.config/ghostty/config.ghostty`, and the table of Ghostty's own keys below, which the key card task copies.

Ghostty is the program the editor runs inside: a terminal emulator, which draws a grid of characters in a window and passes the keys typed into it to the program running there, here Neovim or the shell. Its settings are a plain text file of `name = value` lines, with comments on lines of their own that start with `#`. Ghostty 1.2 and later read `~/.config/ghostty/config.ghostty`. They still read the older name, `~/.config/ghostty/config`, and when both exist they read both and log a warning, so this repository uses the newer name alone. The file lives here, at `ghostty/config.ghostty`, so the terminal's settings are kept and versioned beside the editor's, and the Mac's setup links it into place. On macOS Ghostty reads one more file after it, `~/Library/Application Support/com.mitchellh.ghostty/config`, and a setting there would win; this Mac has no such file, checked on 2026-10-11.

The background is the navy, `#011628`. Neovim paints its own background that colour, but Ghostty shows its own in the thin margin around the grid and for the moment before Neovim draws, so a different colour there shows as a seam around the editor. The text, the cursor and a selection take the colours Neovim gives normal text and a Visual selection, `#CBE0F0` on `#275378`.

The sixteen colours need a word on how terminal programs choose colours. Most do not name an exact shade. They ask for a colour by number from a set of sixteen: black, red, green, yellow, blue, magenta, cyan and white, numbered 0 to 7, then a bright version of each, numbered 8 to 15. The terminal decides what each number looks like. Neovim has a terminal of its own inside it, where lazygit, Claude Code and newsboat run, and tokyonight tells that terminal its sixteen shades through `vim.g.terminal_color_0` to `vim.g.terminal_color_15`. Ghostty gets the same sixteen, so a program looks the same in a Ghostty tab as in a panel inside Neovim. The shades are tokyonight's night style as released: the navy overrides do not reach them, because tokyonight works out the sixteen before it applies overrides. A test reads Neovim's sixteen from the running editor and compares, so a tokyonight update that moves a shade names the line to change here. `lua/ach/palette.lua` stays the one place the navy colours are written, and this file's only other colours are these sixteen.

Every colour that draws text, 1 to 7 and 9 to 15, reads at 6.92 to 1 or better on the navy, against the 4.5 to 1 that WCAG asks of body text, and a test holds that floor. Two are left out on purpose. Colour 0, black, is a background shade. Colour 8, bright black, is `#414868`, at 2.05 to 1: tokyonight keeps it faint for text meant to stay in the background, such as the grey rest of a command that zsh-autosuggestions, which this Mac's shell runs, offers while typing, and on tokyonight's own background it is fainter still, at 1.91 to 1.

The font is JetBrainsMono Nerd Font at 15 points, two points larger than Ghostty's own default on a Mac, which is 13. A Nerd Font is a programming font with several thousand icons added, and the status bar, the file tree and the key menu draw theirs from it. Homebrew's cask `font-jetbrains-mono-nerd-font` is in the Brewfile already.

A Mac's Option key types special characters: `Option-p` types π, and `Option-e` then `e` types é. Terminal programs expect an Alt key instead, which the terminal sends as `Esc` followed by the key, and the foundation's `Alt-j` and `Alt-k`, which move lines, need it. `macos-option-as-alt = left` turns the left Option key into Alt and leaves the right one typing special characters.

Ghostty's own keys need no setting, because these are its defaults on a Mac, read from Ghostty's source. They act on Ghostty's windows, tabs and splits, side-by-side panes each with its own shell, and Neovim never sees them, so they cannot clash with the editor's keys.

| Key | What it does |
| --- | --- |
| `Command-T` | Opens a new tab |
| `Command-N` | Opens a new window |
| `Command-D` | Splits the current pane, with the new one to the right |
| `Command-Shift-D` | Splits the current pane, with the new one below |
| `Command-[` and `Command-]` | Moves to the previous or the next split |
| `Command-Option` with an arrow | Moves to the split in that direction |
| `Command-Shift-Enter` | Zooms the current split to fill the window, and back |
| `Command-Shift-[` and `Command-Shift-]` | Moves to the previous or the next tab |
| `Command-1` to `Command-8` | Moves to that tab; `Command-9` moves to the last |
| `Command-W` | Closes the current split, or the tab when it holds one pane, asking first while a program such as Neovim is running in it |
| `Command-=` and `Command-minus` | Makes the text bigger or smaller; `Command-0` returns it to 15 points |
| `Command-,` | Opens this settings file for editing |
| `Command-Shift-,` | Reads the settings file again, so a change shows without restarting |

No test opens a Ghostty window. Two of them run Ghostty's command line: `ghostty +validate-config --config-file=<path>` reads the file alone, without the user's own, and prints a line for each setting it cannot accept, and `ghostty +list-fonts --family=<name>` lists the fonts of that family Ghostty can find. Homebrew's cask installs the app but puts no `ghostty` command on the path, so the tests use the one inside the app, `/Applications/Ghostty.app/Contents/MacOS/ghostty`, and skip, naming the cask, until Ghostty is installed.

- [ ] **Write the failing tests**

`tests/test_ghostty.lua`:

```lua
-- Ghostty's settings, ghostty/config.ghostty. Every colour is checked against
-- lua/ach/palette.lua or against the terminal colours tokyonight gives Neovim.
-- No Ghostty window opens: two tests run Ghostty's command line, and they skip
-- until Ghostty is installed.

local FILE = "/ghostty/config.ghostty"

-- The cask installs the app and puts no ghostty command on the PATH, so the
-- command inside the app is used when the PATH has none.
local APP = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

local function ghostty()
  local bin = vim.fn.exepath("ghostty")
  if bin == "" and vim.fn.executable(APP) == 1 then
    bin = APP
  end
  return bin ~= "" and bin or nil
end

-- Reads the file into { key = { value, ... } }, a list per key, since palette
-- appears sixteen times. Ghostty's comments take a whole line, so a # later in
-- a line belongs to the value.
local function read(t)
  local ok, lines = pcall(vim.fn.readfile, t.root .. FILE)
  t.ok(ok and #lines > 0, "ghostty/config.ghostty exists and is not empty")
  local conf = {}
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") and not line:match("^%s*#") then
      local key, value = line:match("^%s*([%w%-]+)%s*=%s*(.-)%s*$")
      t.ok(key ~= nil, "every line is a name = value setting: " .. line)
      conf[key] = conf[key] or {}
      table.insert(conf[key], value)
    end
  end
  return conf
end

-- The sixteen palette lines as { [0] = "#rrggbb", ... }, in lowercase.
local function sixteen(t, conf)
  local got = {}
  for _, v in ipairs(conf.palette or {}) do
    local n, hex = v:match("^(%d+)=(#%x%x%x%x%x%x)$")
    t.ok(n ~= nil, "a palette line reads N=#rrggbb: " .. v)
    got[tonumber(n)] = hex:lower()
  end
  t.eq(#(conf.palette or {}), 16, "palette lines")
  return got
end

-- Neovim's own terminal colours, which tokyonight sets as it loads.
local function neovims()
  local want = {}
  for n = 0, 15 do
    local c = vim.g["terminal_color_" .. n]
    want[n] = c and c:lower()
  end
  return want
end

return {
  ["the background, text, cursor and selection are the theme's"] = function(t)
    local conf = read(t)
    local p = require("ach.palette")
    local function one(key)
      t.eq(conf[key] and #conf[key], 1, key .. " is set once")
      return conf[key][1]:upper()
    end
    t.eq(one("background"), p.bg:upper(), "background, the navy behind the editor")
    t.eq(one("foreground"), p.fg:upper(), "foreground, the text")
    t.eq(one("cursor-color"), p.fg:upper(), "cursor-color")
    t.eq(one("selection-background"), p.bg_visual:upper(), "selection-background, as Neovim's Visual")
    t.eq(one("selection-foreground"), p.fg:upper(), "selection-foreground")
  end,

  ["the sixteen colours are the ones Neovim gives its own terminal"] = function(t)
    local got = sixteen(t, read(t))
    local want = neovims()
    t.ok(want[0] ~= nil, "tokyonight has set vim.g.terminal_color_0")
    t.eq(got, want, "palette 0 to 15")
  end,

  ["every colour that draws text reads at 4.5 to 1 or better on the navy"] = function(t)
    local got = sixteen(t, read(t))
    local ratio = require("ach.contrast").ratio
    local bg = require("ach.palette").bg
    local low = {}
    for n, hex in pairs(got) do
      -- 0, black, is a background shade, and 8, bright black, is kept faint on
      -- purpose, for hints such as a shell's suggested rest of a command.
      if n ~= 0 and n ~= 8 and ratio(hex, bg) < 4.5 then
        table.insert(low, ("%d %s at %.2f to 1"):format(n, hex, ratio(hex, bg)))
      end
    end
    table.sort(low)
    t.eq(low, {}, "text colours below 4.5 to 1")
  end,

  ["no colour appears that is not the palette's or Neovim's terminal's"] = function(t)
    local conf = read(t)
    local known = {}
    for _, hex in pairs(require("ach.palette")) do
      if type(hex) == "string" then
        known[hex:lower()] = true
      end
    end
    for _, hex in pairs(neovims()) do
      known[hex] = true
    end
    local strays = {}
    for key, values in pairs(conf) do
      for _, value in ipairs(values) do
        for hex in value:gmatch("#%x%x%x%x%x%x") do
          if not known[hex:lower()] then
            table.insert(strays, key .. " " .. hex)
          end
        end
      end
    end
    table.sort(strays)
    t.eq(strays, {}, "colours from nowhere")
  end,

  ["the font is JetBrainsMono Nerd Font at 15 points, and the left Option key is Alt"] = function(t)
    local conf = read(t)
    t.eq(conf["font-family"], { "JetBrainsMono Nerd Font" }, "font-family")
    t.eq(conf["font-size"], { "15" }, "font-size, 15 points")
    t.eq(conf["macos-option-as-alt"], { "left" }, "macos-option-as-alt")
  end,

  ["Ghostty accepts every line of the file"] = function(t)
    read(t)
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+validate-config", "--config-file=" .. t.root .. FILE }, { text = true }):wait(30000)
    t.eq(r.code, 0, "ghostty +validate-config, which printed: " .. (r.stdout or "") .. (r.stderr or ""))
  end,

  ["the font the file names is one Ghostty can find"] = function(t)
    local family = (read(t)["font-family"] or {})[1] or ""
    t.ok(family ~= "", "font-family is set")
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+list-fonts", "--family=" .. family }, { text = true }):wait(30000)
    if not (r.stdout or ""):find(family, 1, true) then
      t.human(family .. " is not installed. Install it with: brew install --cask font-jetbrains-mono-nerd-font")
    end
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_ghostty`
Expected: `0 passed, 7 failed, 0 need a person, 0 skipped`, exit 1. Every test reads the file before anything else, so all seven fail on `ghostty/config.ghostty exists and is not empty`, whether or not Ghostty is installed.

- [ ] **Write Ghostty's settings**

`ghostty/config.ghostty`:

```
# Ghostty's settings for ACH-NEOVIM. Ghostty reads this file through the link
# ~/.config/ghostty/config.ghostty. tests/test_ghostty.lua checks every colour
# here against lua/ach/palette.lua and against the terminal colours Neovim's
# theme sets, so a colour changes there first.

# JetBrainsMono Nerd Font at 15 points. The Nerd Font's icons draw the
# editor's status bar, file tree and key menu.
font-family = JetBrainsMono Nerd Font
font-size = 15

# The navy behind the editor, so no seam shows around it, and the text,
# cursor and selection colours Neovim uses.
background = #011628
foreground = #CBE0F0
cursor-color = #CBE0F0
selection-background = #275378
selection-foreground = #CBE0F0

# The sixteen colours programs pick by number: black, red, green, yellow,
# blue, magenta, cyan and white, then the bright version of each. They are
# the ones tokyonight's night style gives Neovim's own terminal.
palette = 0=#15161e
palette = 1=#f7768e
palette = 2=#9ece6a
palette = 3=#e0af68
palette = 4=#7aa2f7
palette = 5=#bb9af7
palette = 6=#7dcfff
palette = 7=#a9b1d6
palette = 8=#414868
palette = 9=#ff899d
palette = 10=#9fe044
palette = 11=#faba4a
palette = 12=#8db0ff
palette = 13=#c7a9ff
palette = 14=#a4daff
palette = 15=#c0caf5

# The left Option key is Alt, which terminal programs such as Neovim expect.
# The right Option key still types special characters, such as Option-e e.
macos-option-as-alt = left
```

The sixteen are tokyonight's own, as its generated Ghostty theme for the night style lists them, and they equal what tokyonight sets in `vim.g.terminal_color_0` to `vim.g.terminal_color_15`: black is tokyonight's night background darkened by a fifth, and each bright colour is its plain one brightened by tokyonight's own rule.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. Once the Mac's setup has installed Ghostty, `test_ghostty` reports seven passed. Before that, it reports five passed and two skipped, the two that run Ghostty's command line, each naming `brew install --cask ghostty`. No key, program or plugin is added, so `lua/ach/icons.lua`, `lua/ach/need.lua` and `lazy-lock.json` do not change.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add ghostty/config.ghostty tests/test_ghostty.lua
git commit --only ghostty/config.ghostty tests/test_ghostty.lua -m "feat(ghostty): set Ghostty's font, navy background, left Option as Alt and the sixteen colours Neovim's terminal uses"
```

---

### Task: Startup Benchmark

**Files:**
- Create: `tests/helpers/startup.lua`, `tests/baseline.json` (written by `scripts/check --baseline` in this task, never by hand)
- Modify: `scripts/check` (one help line, one variable, one option and one branch)
- Test: `tests/test_startup.lua`

**Interfaces:**
- Consumes: the foundation's `scripts/check`, which exports `ACH_TEST=1`, `XDG_STATE_HOME` and `CLAUDE_CONFIG_DIR`, prints its help from line 2 down to the line that starts `# Exit`, and removes its throwaway folder `$scratch` when it exits, together with the languages plan's line that exports `ACH_DRY_INSTALL=1` outside `--full`; the foundation's `init.lua`, which installs the test instrumentation only when `ACH_TEST` is `1`; the harness's `t.root`, `t.tmpdir()`, `t.eq`, `t.ok` and `t.human`.
- Produces:
  - `tests/helpers/startup.lua`, which returns a table with `STARTS` (10), `STARTER_URL`, `STARTER` (the pinned commit), `parse(lines) -> ms | nil, reason`, `median(list) -> number`, `start(run, dir) -> ms, stderr`, `medians(runs, n, dir) -> medians, stderrs`, `ach(root) -> run`, `lazyvim(bench) -> run`, `verdict(baseline, median) -> nil | reason`, `read(path) -> table | nil, reason` and `record(root, bench, opts?) -> table`, where a run is `{ name = string, argv = string[], env = table<string, string> }`. Run as `nvim -l tests/helpers/startup.lua ROOT BENCH`, it records the baseline.
  - `tests/baseline.json`, with the fields `ach_ms`, `lazyvim_ms`, `starts`, `nvim`, `starter`, `lazyvim` and `date`.
  - `scripts/check --baseline`. No other task runs it; `scripts/update` in particular never re-records the baseline.

Startup time is how long Neovim takes from the moment its process begins to the moment it is ready for the first key. The spec holds ACH-NEOVIM to two numbers. It must stay within one and a half times its own first recorded time, so a change that makes it noticeably slower fails the check on the day it lands. And it must start no slower than stock LazyVim, the distribution it learned from, although it sets up roughly ninety languages against LazyVim's handful.

Neovim measures itself. Started with `--startuptime FILE`, it writes a log of every stage of its start, one line per stage. Shortened, a log reads like this:

```
000.003  000.003: --- NVIM STARTING ---
021.480  000.310: VimEnter autocommands
021.502  000.022: before starting main loop
021.950  000.448: first screen update
021.957  000.007: --- NVIM STARTED ---
```

The first number on each line is the milliseconds since the process began, and the second is the milliseconds since the line before. The last line is the answer: this start took 21.957 ms. Neovim writes "first screen update" once it has drawn the screen for the first time, which is when starting has really finished, and "NVIM STARTED" straight after it. That much was read in Neovim 0.12.6's `src/nvim/normal.c` and `src/nvim/profile.c` on 2026-10-11.

A start with no window must be told to quit, and the usual way, `+qa`, quits too early. Neovim runs `+` commands before its VimEnter stage, so the log would stop before starting had finished and the time would come out short. Worse, Neovim still writes an NVIM STARTED line when it quits, so a log cut short looks complete. Each timed start therefore ends with `-c "lua vim.schedule(function() vim.cmd('qa!') end)"`. `vim.schedule` holds the quit until Neovim has finished starting and entered its main loop, the loop that waits for keys, by which point the log is closed. The parser also accepts a time only when the line before NVIM STARTED is the first screen update, so a start that quit early for any other reason fails instead of reporting a flattering number.

One start is not a measurement, because the Mac is always doing something else as well. Ten starts might take 31, 29, 30, 28, 95, 30, 29, 31, 30 and 29 ms, the 95 being the moment Spotlight woke up. Their mean is 36.2 ms, dragged up by that one start. Their median, the middle value once they are sorted, ignores it. Sorted, the ten read 28, 29, 29, 29, 30, 30, 30, 31, 31, 95, and with an even count the median is the mean of the two in the middle, the fifth and the sixth, here 30 and 30, so 30 ms. Before the ten, one start runs untimed. The first start after a change reads every file from disk and compiles every Lua file, and lazy.nvim keeps the compiled files in Neovim's cache folder, so the starts after it are the ones a person meets every day.

The starts are headless, run with no window, because the suite has no terminal to draw in. A headless Neovim still draws its first screen, into memory, so its log ends at the same point as a start in Ghostty, a few milliseconds sooner because nothing is sent to a terminal. Both distributions are timed this way, so the comparison holds. Both also load some plugins only after the first screen, on lazy.nvim's VeryLazy event, which a headless Neovim never fires, so that work is left out of both times alike. No file is named on the command line, so neither opens one. ACH-NEOVIM is started with `ACH_TEST=0`, so the instrumentation `init.lua` installs for the suite is not timed, and with `ACH_DRY_INSTALL=1`, so no timed start installs anything.

The baseline is recorded once, in this task, by `scripts/check --baseline`, and afterwards only when the owner asks, for instance after a Neovim upgrade that moves both numbers. It does five things, in this order.

- It clones LazyVim's starter, the small repository whose `init.lua` sets LazyVim up, into the throwaway folder `scripts/check` already makes, and checks out commit `803bc181d7c0d6d5eeba9274d9be49b287294d99`. That is the starter's newest commit, from 11 December 2024, and nothing has been pushed to it since, as of 11 October 2026, so the pin costs nothing today and guards against a later change.
- It points Neovim's four folders into the throwaway folder. Neovim finds its settings, its plugins, its history and its caches through four environment variables, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME`. With all four inside the throwaway folder, stock LazyVim never sees ACH-NEOVIM's plugins, and ACH-NEOVIM never sees LazyVim's.
- It installs stock LazyVim's plugins with `nvim --headless "+Lazy! sync" +qa`, the headless install lazy.nvim documents. This is the only step that downloads. The starter pins only itself: LazyVim and the plugins it brings come at their newest commits on the day, so the file records which LazyVim commit was timed, read from the `lazy-lock.json` the install writes. The starter also turns on lazy.nvim's update checker, which fetches from GitHub, but lazy.nvim never starts it in a headless Neovim, so the timed starts make no network calls.
- It times both, one warm-up start each and then ten each, taking turns, ACH-NEOVIM and then LazyVim, so a moment of load on the Mac falls on both alike rather than on whichever ran second.
- It writes `tests/baseline.json`, unless ACH-NEOVIM was the slower, in which case it writes nothing, prints both times and exits 1. Everything it downloaded goes when `scripts/check` removes its throwaway folder.

| Field | What it holds |
| --- | --- |
| `ach_ms` | ACH-NEOVIM's median start, in milliseconds, to a tenth |
| `lazyvim_ms` | Stock LazyVim's median start, timed in the same run |
| `starts` | How many timed starts each median came from, 10 |
| `nvim` | The Neovim version that ran them, such as `0.12.6` |
| `starter` | The starter commit that set LazyVim up |
| `lazyvim` | The LazyVim commit the starter installed |
| `date` | The day it was recorded, year first, as `2026-10-12` |

The regular `scripts/check` reads that file and times ACH-NEOVIM the same way, eleven starts in all, which at tens of milliseconds each come to about a second. With a baseline of 20 ms and stock LazyVim at 40 ms, the limit is 30 ms: a median of 30 ms passes and 30.1 ms fails. With stock LazyVim at 25 ms, a median of 25.5 ms fails although it is well inside 30. With no file, the test needs a person and names the command that records one. A failure on a busy Mac can be noise, so run the check again, and treat a second failure as a real slowdown to find, not as a reason to re-record.

- [ ] **Write the failing tests**

`tests/test_startup.lua`:

```lua
-- The startup benchmark: tests/helpers/startup.lua, tests/baseline.json and
-- scripts/check --baseline. One test times real starts, about a second's worth.
-- Nothing here downloads stock LazyVim; scripts/check --baseline alone does.

local function startup(t)
  return dofile(t.root .. "/tests/helpers/startup.lua")
end

-- A --startuptime log as Neovim 0.12 writes it, with the stages between its
-- first and last few lines left out.
local LOG = {
  "--- Startup times for process: Primary (or UI client) ---",
  "",
  "times in msec",
  " clock   self+sourced   self:  sourced script",
  " clock   elapsed:              other lines",
  "",
  "000.003  000.003: --- NVIM STARTING ---",
  "000.120  000.117: event init",
  "021.480  000.310: VimEnter autocommands",
  "021.502  000.022: before starting main loop",
  "021.950  000.448: first screen update",
  "021.957  000.007: --- NVIM STARTED ---",
  "",
}

local HELP = "  scripts/check --baseline   time this configuration against stock LazyVim and write tests/baseline.json"

local function missing(t, why)
  t.human("No startup baseline is recorded (" .. why .. "). Record one with: scripts/check --baseline")
end

-- What every baseline file must hold, whoever wrote it.
local function valid(t, S, data)
  t.eq(type(data.ach_ms), "number", "ach_ms is a number")
  t.eq(type(data.lazyvim_ms), "number", "lazyvim_ms is a number")
  t.ok(data.ach_ms > 0 and data.ach_ms <= data.lazyvim_ms, "recorded no slower than stock LazyVim")
  t.eq(data.starts, S.STARTS, "the median of ten starts each")
  t.eq(data.starter, S.STARTER, "the pinned starter commit")
  local commit = type(data.lazyvim) == "string" and data.lazyvim or ""
  t.ok(#commit == 40 and commit:match("^%x+$") ~= nil, "LazyVim's commit, 40 hexadecimal digits")
  t.ok(type(data.nvim) == "string" and data.nvim:match("^%d+%.%d+%.%d+") ~= nil, "the Neovim version")
  t.ok(type(data.date) == "string" and data.date:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil, "the date, year first")
end

return {
  ["a timing log gives the time of NVIM STARTED, after the first screen update"] = function(t)
    local S = startup(t)
    t.eq(S.parse(LOG), 21.957, "the clock on the last line")

    local early = vim.list_slice(LOG, 1, 9)
    table.insert(early, "021.490  000.010: --- NVIM STARTED ---")
    local ms, why = S.parse(early)
    t.eq(ms, nil, "a start that quit before its first screen gives no time")
    t.eq(why, "Neovim quit before its first screen update", "and says why")

    t.eq(select(2, S.parse({})), "the log has no NVIM STARTED line", "an empty log")
    local slow = { "1234.500  000.700: first screen update", "1234.567  000.067: --- NVIM STARTED ---" }
    t.eq(S.parse(slow), 1234.567, "a start past a second")
  end,

  ["the median of ten starts is the mean of the middle two"] = function(t)
    local S = startup(t)
    t.eq(S.STARTS, 10, "ten timed starts")
    t.eq(S.median({ 9, 1, 8, 2, 7, 3, 6, 4, 5, 100 }), 5.5, "one slow start does not move it")
    t.eq(S.median({ 3, 1, 2 }), 2, "an odd count takes the middle one")
  end,

  ["a start fails above one and a half times the baseline or above stock LazyVim"] = function(t)
    local S = startup(t)
    local roomy = { ach_ms = 20, lazyvim_ms = 40 }
    t.eq(S.verdict(roomy, 30), nil, "exactly one and a half times passes")
    local over = S.verdict(roomy, 30.1) or ""
    t.ok(over:find("one and a half times the baseline of 20.0 ms", 1, true), "just over fails: " .. over)

    local close = { ach_ms = 20, lazyvim_ms = 25 }
    t.eq(S.verdict(close, 25), nil, "as fast as stock LazyVim passes")
    local slower = S.verdict(close, 25.5) or ""
    t.ok(slower:find("slower than stock LazyVim's 25.0 ms", 1, true), "slower than LazyVim fails: " .. slower)
  end,

  ["the recorded baseline holds both medians and how they were taken"] = function(t)
    local S = startup(t)
    local data, why = S.read(t.root .. "/tests/baseline.json")
    if not data then
      missing(t, why)
    end
    valid(t, S, data)
  end,

  ["--baseline times both apart and writes only when this configuration is faster"] = function(t)
    local S = startup(t)
    local bench = t.tmpdir()
    local out = bench .. "/baseline.json"
    local commit = string.rep("a", 40)
    local seen = {}
    local function prepare(dir)
      t.eq(dir, bench, "the starter goes into the throwaway folder")
      return commit
    end
    local function timed(medians)
      return function(runs, n)
        seen = { runs = runs, n = n }
        return medians, { "", "" }
      end
    end

    local ok, err = pcall(S.record, t.root, bench, { out = out, prepare = prepare, medians = timed({ 31.24, 30 }) })
    t.eq(ok, false, "a slower configuration is refused")
    local said = tostring(err)
    t.ok(said:find("31.2 ms, is slower than stock LazyVim's, 30.0 ms", 1, true), "naming both times: " .. said)
    t.eq(vim.uv.fs_stat(out), nil, "and nothing is written")

    local data = S.record(t.root, bench, { out = out, prepare = prepare, medians = timed({ 24.06, 38.75 }) })
    t.eq(seen.n, S.STARTS, "ten starts each")
    local ach, lazyvim = seen.runs[1], seen.runs[2]
    t.eq({ ach.name, lazyvim.name }, { "ACH-NEOVIM", "stock LazyVim" }, "this configuration, then stock LazyVim")
    t.eq(ach.env.ACH_TEST, "0", "timed without the test instrumentation")
    t.eq(ach.env.ACH_DRY_INSTALL, "1", "and without installing anything")
    for _, name in ipairs({ "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_CACHE_HOME" }) do
      t.ok(vim.startswith(lazyvim.env[name] or "", bench .. "/"), name .. " is inside the throwaway folder")
    end

    t.eq(S.read(out), data, "the file holds what was recorded")
    t.eq({ data.ach_ms, data.lazyvim_ms }, { 24.1, 38.8 }, "rounded to a tenth of a millisecond")
    valid(t, S, data)
    t.eq(vim.fn.readfile(out)[2], '  "ach_ms": 24.1,', "one field per line, in a fixed order")
  end,

  ["this configuration starts within its baseline and no slower than stock LazyVim"] = function(t)
    local S = startup(t)
    local baseline, why = S.read(t.root .. "/tests/baseline.json")
    if not baseline then
      missing(t, why)
    end
    local median = S.medians({ S.ach(t.root) }, S.STARTS, t.tmpdir())[1]
    local failure = S.verdict(baseline, median)
    t.ok(failure == nil, tostring(failure))
  end,

  ["scripts/check -h describes --baseline"] = function(t)
    local result = vim.system({ t.root .. "/scripts/check", "-h" }, { text = true }):wait()
    t.eq(result.code, 0, "the help exits 0")
    local lines = vim.split(vim.trim(result.stdout or ""), "\n")
    t.ok(vim.tbl_contains(lines, HELP), "names --baseline:\n" .. (result.stdout or ""))
    local last = "Exit 0 when everything passes, 1 on a failure, 2 when a person must act."
    t.eq(lines[#lines], last, "the help ends at the exit codes")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_startup`
Expected: `0 passed, 7 failed, 0 need a person, 0 skipped`, exit 1. Six tests fail on `cannot open <root>/tests/helpers/startup.lua`, and the help test fails on `names --baseline`, since the help has no such line yet.

- [ ] **Write the timing helper**

`tests/helpers/startup.lua`:

```lua
-- Times Neovim starts with Neovim's own --startuptime log. Two callers:
-- tests/test_startup.lua loads it with dofile and gets the table back, and
-- scripts/check --baseline runs it as `nvim -l tests/helpers/startup.lua ROOT BENCH`,
-- which times stock LazyVim beside this configuration and writes tests/baseline.json.
local M = {}

-- Ten timed starts per configuration, after one untimed warm-up start.
M.STARTS = 10

-- LazyVim's starter, pinned to its newest commit as of 2026-10-11.
M.STARTER_URL = "https://github.com/LazyVim/starter"
M.STARTER = "803bc181d7c0d6d5eeba9274d9be49b287294d99"

-- How a timed start ends. vim.schedule holds the quit until Neovim has entered
-- its main loop, after the first screen update has closed the log. A bare +qa
-- would quit before VimEnter and still write NVIM STARTED.
local QUIT = "lua vim.schedule(function() vim.cmd('qa!') end)"

-- The fields of tests/baseline.json, in the order they are written.
local FIELDS = { "ach_ms", "lazyvim_ms", "starts", "nvim", "starter", "lazyvim", "date" }

-- The milliseconds a --startuptime log gives for the end of startup, or nil
-- and the reason. A start that quit early still writes NVIM STARTED, so the
-- line before it must be the first screen update.
function M.parse(lines)
  for i = #lines, 2, -1 do
    local ms = lines[i]:match("^(%d+%.%d+)%s+%d+%.%d+: %-%-%- NVIM STARTED %-%-%-")
    if ms then
      if not lines[i - 1]:match(": first screen update$") then
        return nil, "Neovim quit before its first screen update"
      end
      return tonumber(ms)
    end
  end
  return nil, "the log has no NVIM STARTED line"
end

-- The middle value once sorted, or the mean of the middle two for an even count.
function M.median(list)
  local sorted = vim.deepcopy(list)
  table.sort(sorted)
  local n = #sorted
  if n % 2 == 1 then
    return sorted[(n + 1) / 2]
  end
  return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

-- One timed start in dir. Returns the milliseconds and what the start printed
-- on stderr; errors when it fails or its log is cut short.
function M.start(run, dir)
  local log = dir .. "/startuptime.log"
  os.remove(log)
  local argv = { run.argv[1], "--startuptime", log }
  vim.list_extend(argv, run.argv, 2)
  vim.list_extend(argv, { "-c", QUIT })
  local result = vim.system(argv, { cwd = dir, env = run.env, text = true, timeout = 60000 }):wait()
  local read, lines = pcall(vim.fn.readfile, log)
  os.remove(log)
  local stderr = vim.trim(result.stderr or "")
  if result.code ~= 0 then
    error(("%s exited with code %d: %s"):format(run.name, result.code, stderr), 0)
  end
  local ms, why = M.parse(read and lines or {})
  if not ms then
    error(("%s: %s"):format(run.name, why), 0)
  end
  return ms, stderr
end

-- Times each run n times after one warm-up start of each, taking turns so a
-- moment of load falls on every run alike. Returns the medians in the order
-- of runs, and what each run's last start printed.
function M.medians(runs, n, dir)
  local times, printed = {}, {}
  for i, run in ipairs(runs) do
    M.start(run, dir)
    times[i] = {}
  end
  for _ = 1, n do
    for i, run in ipairs(runs) do
      local ms, stderr = M.start(run, dir)
      table.insert(times[i], ms)
      printed[i] = stderr
    end
  end
  local medians = {}
  for i in ipairs(runs) do
    medians[i] = M.median(times[i])
  end
  return medians, printed
end

-- This configuration with the suite's instrumentation off and nothing installed.
function M.ach(root)
  return {
    name = "ACH-NEOVIM",
    argv = { vim.v.progpath, "--headless", "-u", root .. "/init.lua" },
    env = { ACH_TEST = "0", ACH_DRY_INSTALL = "1" },
  }
end

-- Stock LazyVim from the starter in bench/config/nvim, with all four of
-- Neovim's folders inside bench.
function M.lazyvim(bench)
  return {
    name = "stock LazyVim",
    argv = { vim.v.progpath, "--headless" },
    env = {
      XDG_CONFIG_HOME = bench .. "/config",
      XDG_DATA_HOME = bench .. "/data",
      XDG_STATE_HOME = bench .. "/state",
      XDG_CACHE_HOME = bench .. "/cache",
    },
  }
end

local OVER = "the median start took %.1f ms, more than one and a half times the baseline of %.1f ms"
local SLOWER = "the median start took %.1f ms, slower than stock LazyVim's %.1f ms"

-- nil when a median start passes against the recorded baseline, otherwise why not.
function M.verdict(baseline, median)
  if median > baseline.ach_ms * 1.5 then
    return OVER:format(median, baseline.ach_ms)
  end
  if median > baseline.lazyvim_ms then
    return SLOWER:format(median, baseline.lazyvim_ms)
  end
end

-- A baseline file as a table, or nil and the reason.
function M.read(path)
  local read, lines = pcall(vim.fn.readfile, path)
  if not read or #lines == 0 then
    return nil, path .. " is missing or empty"
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(data) ~= "table" then
    return nil, path .. " is not JSON"
  end
  return data
end

-- One field per line in a fixed order, so a re-recording diffs line by line.
local function encode(data)
  local lines = {}
  for i, field in ipairs(FIELDS) do
    lines[i] = ("  %s: %s"):format(vim.json.encode(field), vim.json.encode(data[field]))
  end
  return "{\n" .. table.concat(lines, ",\n") .. "\n}\n"
end

-- Runs a command that must succeed, with a long timeout for downloads.
local function must(argv, env)
  local result = vim.system(argv, { env = env, text = true, timeout = 600000 }):wait()
  if result.code ~= 0 then
    error(("%s failed with code %d: %s"):format(argv[1], result.code, vim.trim(result.stderr or "")), 0)
  end
end

-- The starter at its pinned commit in bench/config/nvim, its plugins installed
-- into bench/data. Returns the LazyVim commit the install locked.
local function prepare(bench)
  local config = bench .. "/config/nvim"
  vim.fn.mkdir(bench .. "/config", "p")
  must({ "git", "clone", "--quiet", M.STARTER_URL, config })
  must({ "git", "-C", config, "checkout", "--quiet", "--detach", M.STARTER })
  must({ vim.v.progpath, "--headless", "+Lazy! sync", "+qa" }, M.lazyvim(bench).env)
  local lock = M.read(config .. "/lazy-lock.json") or {}
  local commit = type(lock.LazyVim) == "table" and lock.LazyVim.commit or ""
  if type(commit) ~= "string" or #commit ~= 40 or not commit:match("^%x+$") then
    error("stock LazyVim did not install: its lazy-lock.json names no LazyVim commit", 0)
  end
  return commit
end

local REFUSED = "ACH-NEOVIM's median start, %.1f ms, is slower than stock LazyVim's, %.1f ms. No baseline was written."

-- scripts/check --baseline. Times this configuration and stock LazyVim, taking
-- turns, and writes the result, refusing and writing nothing when this
-- configuration is the slower. opts.out, opts.prepare and opts.medians let the
-- tests stand in for the file, the download and the timing.
function M.record(root, bench, opts)
  opts = opts or {}
  local out = opts.out or (root .. "/tests/baseline.json")
  local lazyvim = (opts.prepare or prepare)(bench)
  local dir = bench .. "/run"
  vim.fn.mkdir(dir, "p")
  local medians, printed = (opts.medians or M.medians)({ M.ach(root), M.lazyvim(bench) }, M.STARTS, dir)
  local ach_ms, lazyvim_ms = medians[1], medians[2]
  if ach_ms > lazyvim_ms then
    local why = REFUSED:format(ach_ms, lazyvim_ms)
    local said = printed and printed[2] or ""
    if said ~= "" then
      why = why .. " Stock LazyVim's last start printed: " .. said
    end
    error(why, 0)
  end
  local function tenth(ms)
    return math.floor(ms * 10 + 0.5) / 10
  end
  local data = {
    ach_ms = tenth(ach_ms),
    lazyvim_ms = tenth(lazyvim_ms),
    starts = M.STARTS,
    nvim = tostring(vim.version()),
    starter = M.STARTER,
    lazyvim = lazyvim,
    date = os.date("%Y-%m-%d"),
  }
  local file = assert(io.open(out, "w"))
  file:write(encode(data))
  file:close()
  return data
end

-- Run as a script: nvim -l tests/helpers/startup.lua ROOT BENCH
if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "startup.lua" then
  local ok, result = pcall(M.record, _G.arg[1], _G.arg[2])
  if not ok then
    io.stderr:write(tostring(result) .. "\n")
    os.exit(1)
  end
  local wrote = "Wrote tests/baseline.json: ACH-NEOVIM %.1f ms, stock LazyVim %.1f ms, median of %d starts each.\n"
  io.stdout:write(wrote:format(result.ach_ms, result.lazyvim_ms, result.starts))
end

return M
```

`_G.arg` exists only when Neovim runs the file with `-l`, so the test suite's `dofile` gets the table back and records nothing.

- [ ] **Add `--baseline` to `scripts/check`**

`scripts/check` reads as follows after this task. Against what the foundation and the languages plan leave, it adds the `--baseline` help line, `baseline=0`, the `--baseline)` option and the branch before the suite runs; every other line is unchanged. The help still prints from line 2 down to the `# Exit` line, so the new line shows up in `scripts/check -h` with no other change.

```bash
#!/usr/bin/env bash
# Run ACH-NEOVIM's headless test suite against the real configuration.
#   scripts/check              fast mode, about a minute
#   scripts/check --full       also installs every language's tools and tests them
#   scripts/check --only TEXT  run only tests whose "file :: name" label contains TEXT
#   scripts/check --baseline   time this configuration against stock LazyVim and write tests/baseline.json
# Exit 0 when everything passes, 1 on a failure, 2 when a person must act.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
full=0
only=""
baseline=0
while [ $# -gt 0 ]; do
    case "$1" in
        --full) full=1 ;;
        --only) shift; only=${1:-} ;;
        --baseline) baseline=1 ;;
        -h | --help) sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

if ! command -v nvim >/dev/null 2>&1; then
    echo "Neovim is not installed. Install it with: brew install neovim" >&2
    exit 2
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/ach-check.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/state" "$scratch/claude"

# State and Claude Code's lock folder go to a throwaway folder, so a test run
# never touches real history, sessions or ~/.claude/ide.
export ACH_TEST=1 ACH_FULL=$full ACH_ONLY=$only
export XDG_STATE_HOME="$scratch/state" CLAUDE_CONFIG_DIR="$scratch/claude"
if [ "$full" = 0 ]; then export ACH_DRY_INSTALL=1; fi

# --baseline runs no tests. It downloads stock LazyVim into the throwaway
# folder, times it beside this configuration and writes tests/baseline.json.
if [ "$baseline" = 1 ]; then
    status=0
    nvim -l "$root/tests/helpers/startup.lua" "$root" "$scratch/bench" || status=$?
    exit "$status"
fi

status=0
nvim --headless -u "$root/init.lua" "+luafile $root/tests/run.lua" || status=$?
exit "$status"
```

- [ ] **Record the baseline**

Run: `scripts/check --baseline`
Expected: a few minutes while stock LazyVim's plugins download, then `Wrote tests/baseline.json: ACH-NEOVIM <a> ms, stock LazyVim <b> ms, median of 10 starts each.`, exit 0, with `<a>` no larger than `<b>`. This is the step that reaches GitHub, which is why it is a step of its own and never part of the regular suite. If it exits 1 because ACH-NEOVIM was the slower, stop and give the owner both times: making the configuration faster is a decision about what it loads at startup, and nothing in this task should be tuned to get past it.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. `test_startup` reports seven passed.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add tests/helpers/startup.lua tests/test_startup.lua tests/baseline.json
git commit --only scripts/check tests/helpers/startup.lua tests/test_startup.lua tests/baseline.json -m "test(startup): hold startup time to a recorded baseline and to stock LazyVim"
```

---

### Task: Updates

**Files:**
- Create: `lua/ach/update.lua`, `scripts/update`
- Modify: `README.md` (one paragraph gains a sentence)
- Test: `tests/test_update.lua`

**Interfaces:**
- Consumes: `require("ach.masonlock")` from the languages plan, with `read(path?)`, `install(name, done)`, which installs a package at its pin and calls `done(ok, err)` on the main loop, and `update(done)`, which calls `done(changed, failed)`; lazy.nvim's `require("lazy").update`, `.restore` and `.check`, each taking `{ wait = true, show = false }`, and its plugin table `require("lazy.core.config").plugins`, where each plugin's `_.tasks` holds the tasks of its last run and `_.updates` holds `{ from = { commit }, to = { commit } }` after a check that found it behind; nvim-treesitter's `require("nvim-treesitter").update(nil, opts)`, which returns a task whose `pwait(ms)` returns `true, all_built` or `false, reason`; Mason's `require("mason-registry")` with `refresh(cb)` and `get_installed_packages()`; `scripts/check --full` and its exit codes; the foundation's `init.lua`; the harness's `t.root`, `t.tmpdir()`, `t.eq` and `t.ok`.
- Produces:
  - `require("ach.update")`, a table with `FILES` (`lazy-lock.json`, `mason-lock.json`, `docs/languages.md`), `TIMEOUT` (thirty minutes in milliseconds), `line(name, from, to) -> string`, `compare(url, from, to) -> string | nil`, `message(before, after) -> subject, body | nil`, `report(plugins, mason) -> string[]`, `locks(root) -> { lazy, mason }`, `deps()`, `apply(deps?) -> string[]`, `restore(deps?) -> string[]`, `pending(deps?) -> plugins, mason, errors`, `child(action)`, `exec(argv, capture?)` and `run(root, opts?) -> integer`. A `deps` table holds `lazy`, `plugins()`, `parsers()`, `masonlock`, `registry()` and `note(text)`. `run`'s `opts` may hold `apply`, `check` and `restore`, each a function returning an exit code, and `say(text)`. Run as `nvim -l lua/ach/update.lua ROOT`, the file performs a whole update of the repository at `ROOT` and exits with `run`'s code.
  - `scripts/update`, `scripts/update --list` and `scripts/update --restore`, each exiting 0 on success, 1 on a failure and 2 when a person must act.

Two files in the repository decide which version of everything is installed. `lazy-lock.json` holds one line per plugin, naming the git commit lazy.nvim checked out, such as `"snacks.nvim": { "branch": "main", "commit": "<40 hexadecimal digits>" }`. `mason-lock.json` holds one line per Mason package, naming its version, such as `"stylua": "2.0.2"`. A second Mac that clones the repository installs exactly those versions, and nothing moves until someone moves it on purpose. An update is that move: every plugin goes to the newest commit on its branch, every Mason package goes to its newest release, and both files are rewritten to say so.

The spec asks for every update to be proven before it is kept, and undone when it is not. `scripts/update` does all of it in one command, in this order.

- It refuses to start, with exit 2, when either lock file or `docs/languages.md` has changes that are not committed. Undoing an update means putting those three files back as committed, which would throw such changes away.
- It updates, inside a Neovim started headless with this configuration. lazy.nvim updates every plugin, nvim-treesitter rebuilds each parser whose pinned revision moved with it, and `ach.masonlock` updates every Mason package and its pin.
- If no line of either lock file changed, it puts the files back exactly as committed and stops with exit 0, since there is nothing to prove and nothing to commit.
- It runs `scripts/check --full`, which installs and tries every language's tools on the new versions and rewrites `docs/languages.md`.
- If that passes, it commits the two lock files and `docs/languages.md` with a message naming every change. Any other result undoes the update.

| What happened | Exit | Afterwards |
| --- | --- | --- |
| A lock file already had changes that were not committed | 2 | Nothing touched |
| A plugin, parser or Mason package failed to update | 1 | Undone |
| Nothing was behind | 0 | Nothing to commit |
| The full check failed | 1 | Undone |
| The full check needed a person to act | 2 | Undone |
| The full check passed | 0 | Committed |

The full check exits 2 when a person must act, for instance when a language needs a Homebrew program that is not installed. That says nothing for or against the new versions. It only means the check could not finish proving them, and an update counts only once proven, so it is undone like a failure while the exit stays 2. After installing what the check named, running `scripts/update` again repeats the same update, because the newest versions are still the newest. Only the time is lost.

Undoing takes two moves, because a lock file states what should be installed and is not the installed files themselves. First git puts the three files back as committed. Then a second headless Neovim makes what is installed match them again. lazy.nvim's restore checks every plugin out at the commit `lazy-lock.json` names, nvim-treesitter rebuilds each parser whose revision moved back, and every Mason package whose installed version differs from its pin is installed at the pin. A Mason package with no line at all, which happens when the full check installed one for the first time, stays installed, and `:checkhealth ach` lists it as not pinned, with `:AchMasonLock` as the fix. `scripts/update --restore` runs this second move alone. That is also what a second Mac needs after a `git pull` brings new lock files, since lazy.nvim leaves plugins that are already installed where they are.

The commit message is written from the two lock files, before against after. For an update that moved two plugins and one Mason package it reads:

```text
chore(deps): update 2 plugins and 1 Mason package

Plugins:
- blink.cmp 1a2b3c4 to 5d6e7f8
- snacks.nvim 0f1e2d3 to 4c5b6a7

Mason packages:
- stylua 2.0.2 to 2.1.0

scripts/check --full passed with these versions.
```

Each commit is cut to its first seven characters, the length git itself shows. A plugin or package that appears or disappears is named as added or removed. Nothing is pushed.

`scripts/update --list` is the first step of the spec's procedure, reading what would move before moving it. It runs lazy.nvim's check, which fetches each plugin's repository and prints the one-line log of every commit an update would take, then refreshes Mason's registry and compares each installed package with its newest release. It ends with a summary: each plugin that would move, with the GitHub page showing every change between its two commits, and each Mason package with its two versions. It installs nothing and changes no file in the repository. Whoever maintains the configuration reads those pages, and LazyVim's change log at `https://github.com/LazyVim/LazyVim/blob/main/CHANGELOG.md`, before running `scripts/update`, since LazyVim usually adapts to a breaking plugin change within days and its fix shows what changed.

The work lives in `lua/ach/update.lua`, which is used three ways. Inside Neovim, `require("ach.update")` gives the update, the restore and the list. Run as `nvim -l lua/ach/update.lua ROOT`, with no configuration loaded, it drives the whole update from outside the editor: git, the headless Neovim that updates, `scripts/check --full`, then the commit or the undo. `scripts/update` is a short shell script that picks between the two. The slow steps, the ones that download, reach `run` through three options, `apply`, `check` and `restore`, so the tests swap them for stand-ins while git runs for real in a throwaway repository. In the same way the update, the restore and the list reach lazy.nvim, nvim-treesitter and Mason through one table, `deps`, which the tests fill with stand-ins.

One trap gets a test of its own. A headless Neovim that hits an error in a `-c` command prints the error and keeps running, waiting for keys that never come, so `scripts/update` would hang instead of failing. `child`, the function each headless Neovim calls, catches every error and always ends in `qa!`, which exits 0, or `cquit 1`, which exits 1.

- [ ] **Write the failing tests**

`tests/test_update.lua`:

```lua
-- scripts/update and lua/ach/update.lua. The commit message names what moved;
-- an update is committed only when the full check passes, and every other
-- outcome puts the lock files and the installed versions back; lock files
-- with changes of their own stop it before it starts; and the headless
-- Neovim it starts always quits. Nothing here downloads: the update, the full
-- check and the restore are stand-ins, and git runs in a throwaway repository.

local A, B = string.rep("a", 40), string.rep("b", 40)
local BEFORE = { lazy = { ["snacks.nvim"] = { branch = "main", commit = A } }, mason = { stylua = "2.0.2" } }
local AFTER = { lazy = { ["snacks.nvim"] = { branch = "main", commit = B } }, mason = { stylua = "2.1.0" } }
local SUBJECT = "chore(deps): update 1 plugin and 1 Mason package"
local BACK = "every plugin and Mason package is back at its pinned version"

local HELP = {
  "Update ACH-NEOVIM's plugins and Mason packages, and keep the update only if the full check passes.",
  "  scripts/update            update, run scripts/check --full, then commit or put everything back",
  "  scripts/update --list     name what an update would move, with each plugin's commits, installing nothing",
  "  scripts/update --restore  put every plugin and Mason package back at the version the lock files pin",
  "Exit 0 on success, 1 on a failure, 2 when a person must act.",
}

local function write(dir, locks)
  vim.fn.writefile({ vim.json.encode(locks.lazy) }, dir .. "/lazy-lock.json")
  vim.fn.writefile({ vim.json.encode(locks.mason) }, dir .. "/mason-lock.json")
end

-- Runs git in dir, checks that it worked, and returns what it printed, trimmed.
local function git(t, dir, ...)
  local r = vim.system({ "git", "--no-optional-locks", "-C", dir, ... }, { text = true }):wait()
  t.eq(r.code, 0, "git " .. table.concat({ ... }, " ") .. ": " .. (r.stderr or ""))
  return vim.trim(r.stdout or "")
end

-- A throwaway repository holding both lock files at BEFORE and a languages
-- table, all committed. The owner's git settings that could interfere, such
-- as signing and hooks, are set aside in its own configuration, because the
-- update runs a plain git commit there.
local function repo(t)
  local dir = t.tmpdir()
  git(t, dir, "init", "-q", "-b", "main")
  git(t, dir, "config", "user.name", "ACH")
  git(t, dir, "config", "user.email", "ach@example.invalid")
  git(t, dir, "config", "commit.gpgsign", "false")
  git(t, dir, "config", "core.hooksPath", "/dev/null")
  vim.fn.mkdir(dir .. "/docs", "p")
  vim.fn.writefile({ "# Languages" }, dir .. "/docs/languages.md")
  write(dir, BEFORE)
  git(t, dir, "add", "lazy-lock.json", "mason-lock.json", "docs/languages.md")
  git(t, dir, "commit", "-q", "-m", "start")
  return dir
end

-- Collects what run says, so a test can look for a sentence in it.
local function listener()
  local said = {}
  return said, function(text)
    said[#said + 1] = text
  end
end

-- A stand-in for one lazy.nvim task, which failed when err is given.
local function task(err)
  return {
    has_errors = function()
      return err ~= nil
    end,
    output = function()
      return err or ""
    end,
  }
end

-- A stand-in for one installed Mason package.
local function pkg(name, installed, latest)
  return {
    name = name,
    get_installed_version = function()
      return installed
    end,
    get_latest_version = function()
      return latest
    end,
  }
end

local function registry(packages)
  return {
    refresh = function(done)
      done(true)
    end,
    get_installed_packages = function()
      return packages
    end,
  }
end

-- Stand-ins for everything the update, the restore and the list reach. The
-- second value records each call into lazy.nvim with its options.
local function deps(o)
  local calls = {}
  local function record(name)
    return function(opts)
      calls[#calls + 1] = { name, opts }
    end
  end
  return {
    lazy = { update = record("update"), restore = record("restore"), check = record("check") },
    plugins = function()
      return o.plugins or {}
    end,
    parsers = function()
      return {
        pwait = function()
          return true, o.parsers ~= false
        end,
      }
    end,
    masonlock = o.masonlock or {},
    registry = function()
      return o.registry or registry({})
    end,
    note = function() end,
  },
    calls
end

return {
  ["the commit message names every plugin and Mason package that moved, was added or was removed"] = function(t)
    local U = require("ach.update")
    local before = {
      lazy = { ["a.nvim"] = { commit = A }, ["b.nvim"] = { commit = A }, ["c.nvim"] = { commit = A } },
      mason = { stylua = "2.0.2", taplo = "0.9.3" },
    }
    local after = {
      lazy = { ["a.nvim"] = { commit = B }, ["b.nvim"] = { commit = A }, ["d.nvim"] = { commit = B } },
      mason = { stylua = "2.1.0", taplo = "0.9.3", ruff = "0.6.0" },
    }
    local subject, body = U.message(before, after)
    t.eq(subject, "chore(deps): update 3 plugins and 2 Mason packages", "the subject counts each kind")
    t.eq(
      body,
      table.concat({
        "Plugins:",
        "- a.nvim aaaaaaa to bbbbbbb",
        "- c.nvim removed, was at aaaaaaa",
        "- d.nvim added at bbbbbbb",
        "",
        "Mason packages:",
        "- ruff added at 0.6.0",
        "- stylua 2.0.2 to 2.1.0",
        "",
        "scripts/check --full passed with these versions.",
      }, "\n"),
      "the body names each change, sorted"
    )
    local plugins_only = { lazy = after.lazy, mason = before.mason }
    t.eq(U.message(before, plugins_only), "chore(deps): update 3 plugins", "plugins only")
    t.eq(U.message(before, before), nil, "nothing moved")
  end,

  ["the list names what would move, with a GitHub link for each plugin from GitHub"] = function(t)
    local U = require("ach.update")
    local d, calls = deps({
      plugins = {
        ["snacks.nvim"] = {
          url = "https://github.com/folke/snacks.nvim.git",
          _ = { updates = { from = { commit = A }, to = { commit = B } } },
        },
        ["blink.cmp"] = { url = "https://github.com/saghen/blink.cmp.git", _ = {} },
        ["local.nvim"] = {
          url = "https://example.org/me/local.nvim.git",
          _ = { updates = { from = { commit = B }, to = { commit = A } } },
        },
      },
      registry = registry({ pkg("stylua", "2.0.2", "2.1.0"), pkg("taplo", "0.9.3", "0.9.3") }),
    })
    local plugins, mason, errors = U.pending(d)
    t.eq(calls, { { "check", { wait = true, show = false } } }, "lazy.nvim's check, which fetches and moves nothing")
    t.eq(errors, {}, "every fetch worked")
    t.eq(U.report(plugins, mason), {
      "Plugins that would move:",
      "- local.nvim bbbbbbb to aaaaaaa",
      "- snacks.nvim aaaaaaa to bbbbbbb, https://github.com/folke/snacks.nvim/compare/" .. A .. "..." .. B,
      "Mason packages that would move:",
      "- stylua 2.0.2 to 2.1.0",
    }, "a GitHub link only for a plugin from GitHub")
    t.eq(U.report({}, {}), { "Every plugin and Mason package is at its latest version." }, "and when nothing would")
  end,

  ["an update names each plugin, parser and Mason package that failed"] = function(t)
    local U = require("ach.update")
    local d, calls = deps({
      plugins = {
        ["snacks.nvim"] = { _ = { tasks = { task() } } },
        ["blink.cmp"] = { _ = { tasks = { task(), task("fatal: unable to access the remote") } } },
      },
      parsers = false,
      masonlock = {
        update = function(done)
          vim.schedule(function()
            done({ "stylua" }, { "lua-language-server" })
          end)
        end,
      },
    })
    t.eq(U.apply(d), {
      "blink.cmp: fatal: unable to access the remote",
      "tree-sitter: a parser did not build, and :checkhealth nvim-treesitter names it",
      "Mason: lua-language-server did not update",
    }, "every failure, plugins first")
    t.eq(calls, { { "update", { wait = true, show = false } } }, "one lazy.nvim update, waited for, with no window")

    local clean = deps({
      plugins = { ["snacks.nvim"] = { _ = { tasks = { task() } } } },
      masonlock = {
        update = function(done)
          done({}, {})
        end,
      },
    })
    t.eq(U.apply(clean), {}, "nothing failed")
  end,

  ["a restore returns each Mason package that drifted to its pin and leaves the rest"] = function(t)
    local U = require("ach.update")
    local installed = {}
    local d, calls = deps({
      masonlock = {
        read = function()
          return { stylua = "2.0.2", taplo = "0.9.3", ["lua-language-server"] = "3.13.5" }
        end,
        install = function(name, done)
          installed[#installed + 1] = name
          vim.schedule(function()
            local ok = name ~= "lua-language-server"
            done(ok, not ok and "download failed" or nil)
          end)
        end,
      },
      registry = registry({
        pkg("stylua", "2.1.0"),
        pkg("taplo", "0.9.3"),
        pkg("ruff", "0.6.0"),
        pkg("lua-language-server", "3.14.0"),
      }),
    })
    local failed = "Mason: lua-language-server did not return to 3.13.5: download failed"
    t.eq(U.restore(d), { failed }, "the one that failed")
    table.sort(installed)
    t.eq(installed, { "lua-language-server", "stylua" }, "only pinned packages that are away from their pins")
    t.eq(calls, { { "restore", { wait = true, show = false } } }, "one lazy.nvim restore")
  end,

  ["an update the full check passes is committed with that message, and nothing else is"] = function(t)
    local U = require("ach.update")
    local dir = repo(t)
    local said, say = listener()
    local status = U.run(dir, {
      apply = function()
        write(dir, AFTER)
        return 0
      end,
      check = function()
        vim.fn.writefile({ "# Languages", "rewritten" }, dir .. "/docs/languages.md")
        return 0
      end,
      restore = function()
        error("a passing update is never restored")
      end,
      say = say,
    })
    t.eq(status, 0, "exit code")
    t.eq(
      git(t, dir, "log", "-1", "--format=%B"),
      table.concat({
        SUBJECT,
        "",
        "Plugins:",
        "- snacks.nvim aaaaaaa to bbbbbbb",
        "",
        "Mason packages:",
        "- stylua 2.0.2 to 2.1.0",
        "",
        "scripts/check --full passed with these versions.",
      }, "\n"),
      "the whole message, with no co-author line"
    )
    t.eq(
      git(t, dir, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"),
      "docs/languages.md\nlazy-lock.json\nmason-lock.json",
      "the lock files and the table the check rewrote"
    )
    t.eq(git(t, dir, "status", "--porcelain"), "", "nothing left uncommitted")
    t.eq(said[#said], "Committed: " .. SUBJECT, "says what it committed")
  end,

  ["an update the full check fails, or cannot finish, is undone and nothing is committed"] = function(t)
    local U = require("ach.update")
    local why = {
      [1] = "The full check failed after the update.",
      [2] = "The full check needs a person to act, so it has not proven the update.",
    }
    for code, reason in pairs(why) do
      local dir = repo(t)
      local head = git(t, dir, "rev-parse", "HEAD")
      local said, say = listener()
      local restored = 0
      local status = U.run(dir, {
        apply = function()
          write(dir, AFTER)
          return 0
        end,
        check = function()
          vim.fn.writefile({ "rewritten" }, dir .. "/docs/languages.md")
          return code
        end,
        restore = function()
          restored = restored + 1
          t.eq(U.locks(dir), BEFORE, "the lock files are back before the restore runs")
          return 0
        end,
        say = say,
      })
      t.eq(status, code, "exit code " .. code)
      t.eq(restored, 1, "the installed versions are put back once")
      t.eq(git(t, dir, "rev-parse", "HEAD"), head, "nothing committed")
      t.eq(git(t, dir, "status", "--porcelain"), "", "every file as committed, the languages table too")
      local text = table.concat(said, "\n")
      t.ok(text:find(reason, 1, true) and text:find(BACK, 1, true), "says why and that it is undone: " .. text)
    end
  end,

  ["an update that fails is undone without running the full check, and a failed undo says so"] = function(t)
    local U = require("ach.update")
    local dir = repo(t)
    local function run(restore_code)
      local said, say = listener()
      local status = U.run(dir, {
        apply = function()
          write(dir, AFTER)
          return 1
        end,
        check = function()
          error("the full check never runs after a failed update")
        end,
        restore = function()
          return restore_code
        end,
        say = say,
      })
      return status, table.concat(said, "\n")
    end

    local status, text = run(0)
    t.eq(status, 1, "exit code")
    t.ok(text:find("The update failed before the full check ran.", 1, true), text)
    t.ok(text:find(BACK, 1, true), text)
    t.eq(U.locks(dir), BEFORE, "the lock files are back")

    status, text = run(1)
    t.eq(status, 1, "exit code when the undo fails too")
    t.ok(text:find("run scripts/update --restore", 1, true), "names the way out: " .. text)
    t.eq(git(t, dir, "status", "--porcelain"), "", "the files are back even so")
  end,

  ["an update that moves nothing runs no check and commits nothing"] = function(t)
    local U = require("ach.update")
    local dir = repo(t)
    local head = git(t, dir, "rev-parse", "HEAD")
    local said, say = listener()
    local status = U.run(dir, {
      apply = function()
        return 0
      end,
      check = function()
        error("no check when nothing moved")
      end,
      restore = function()
        error("nothing to restore when nothing moved")
      end,
      say = say,
    })
    t.eq(status, 0, "exit code")
    t.eq(git(t, dir, "rev-parse", "HEAD"), head, "nothing committed")
    local already = "Every plugin and Mason package was already at its latest version. Nothing was committed."
    t.eq(said, { already }, "says so")
  end,

  ["lock files with changes that are not committed stop the update before anything moves"] = function(t)
    local U = require("ach.update")
    local dir = repo(t)
    vim.fn.writefile({ '{"stylua":"9.9.9"}' }, dir .. "/mason-lock.json")
    local said, say = listener()
    local status = U.run(dir, {
      apply = function()
        error("nothing updates over changes that are not committed")
      end,
      say = say,
    })
    t.eq(status, 2, "a person must act")
    local text = table.concat(said, "\n")
    t.ok(text:find("mason-lock.json", 1, true) and text:find("Commit or restore them", 1, true), text)
    t.eq(U.locks(dir).mason, { stylua = "9.9.9" }, "the change is left alone")
  end,

  ["the Neovim that scripts/update starts quits with exit 1 when its work raises an error"] = function(t)
    local argv = {
      vim.v.progpath,
      "--headless",
      "-u",
      t.root .. "/init.lua",
      "-c",
      "lua require('ach.update').child('nonsense')",
    }
    local r = vim.system(argv, { text = true, timeout = 60000 }):wait()
    t.eq(r.code, 1, "exit 1, rather than left running until the limit: " .. (r.stderr or ""))
    t.ok((r.stderr or ""):find("scripts/update has no action named nonsense", 1, true), r.stderr)
  end,

  ["scripts/update -h describes its three ways to run and its exit codes"] = function(t)
    local r = vim.system({ t.root .. "/scripts/update", "-h" }, { text = true }):wait()
    t.eq(r.code, 0, "the help exits 0")
    t.eq(vim.split(vim.trim(r.stdout or ""), "\n"), HELP, "the help")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_update`
Expected: `0 passed, 11 failed, 0 need a person, 0 skipped`, exit 1. Nine tests fail on `module 'ach.update' not found`. The help test fails because `scripts/update` does not exist. The test of the headless Neovim takes a full minute to fail, with `exit 1, rather than left running until the limit` and a code of 124: its `-c` command errors, and the Neovim keeps running until the test's sixty-second limit stops it. That minute is the hang `child` exists to prevent.

- [ ] **Write the update module**

`lua/ach/update.lua`:

```lua
-- Updates: every plugin and Mason package moved to its newest version, and the
-- move kept only when scripts/check --full passes. Three callers. scripts/update
-- runs this file as `nvim -l lua/ach/update.lua ROOT`, which drives a whole
-- update from outside the editor; the headless Neovim that run starts calls
-- child() to update, restore or list; and tests/test_update.lua requires it
-- and passes stand-ins for everything that downloads.
local M = {}

-- The files an update may change: the two lock files, and the languages table
-- scripts/check --full rewrites. They are committed together or put back
-- together.
M.FILES = { "lazy-lock.json", "mason-lock.json", "docs/languages.md" }

-- How long one wait inside the headless Neovim may last: thirty minutes, time
-- for every parser and Mason package to download and build.
M.TIMEOUT = 30 * 60 * 1000

-- A git commit is shown by its first seven characters, as git shows it.
local function short(version)
  return (#version == 40 and version:match("^%x+$")) and version:sub(1, 7) or version
end

function M.line(name, from, to)
  return ("- %s %s to %s"):format(name, short(from), short(to))
end

-- The GitHub page showing every change between two commits of a plugin, or
-- nil for a plugin that does not come from GitHub.
function M.compare(url, from, to)
  local path = type(url) == "string" and url:match("^https://github%.com/([%w._-]+/[%w._-]+)$")
  if not path then
    return nil
  end
  return ("https://github.com/%s/compare/%s...%s"):format(path:gsub("%.git$", ""), from, to)
end

-- One line per entry that differs between two lock tables, sorted by name.
-- value turns an entry into the version it names.
local function changes(before, after, value)
  local names, seen = {}, {}
  for _, side in ipairs({ before, after }) do
    for name in pairs(side) do
      if not seen[name] then
        seen[name] = true
        names[#names + 1] = name
      end
    end
  end
  table.sort(names)
  local lines = {}
  for _, name in ipairs(names) do
    local old = before[name] ~= nil and value(before[name]) or nil
    local new = after[name] ~= nil and value(after[name]) or nil
    if old == nil then
      lines[#lines + 1] = ("- %s added at %s"):format(name, short(new))
    elseif new == nil then
      lines[#lines + 1] = ("- %s removed, was at %s"):format(name, short(old))
    elseif old ~= new then
      lines[#lines + 1] = M.line(name, old, new)
    end
  end
  return lines
end

local function count(n, one, many)
  return ("%d %s"):format(n, n == 1 and one or many)
end

-- The commit message for an update, from the lock tables before and after it,
-- each { lazy = <lazy-lock.json>, mason = <mason-lock.json> }. Returns the
-- subject and the body, or nil when nothing moved.
function M.message(before, after)
  local plugins = changes(before.lazy, after.lazy, function(entry)
    return entry.commit
  end)
  local mason = changes(before.mason, after.mason, tostring)
  if #plugins + #mason == 0 then
    return nil
  end
  local counted, body = {}, {}
  if #plugins > 0 then
    counted[#counted + 1] = count(#plugins, "plugin", "plugins")
    body[#body + 1] = "Plugins:\n" .. table.concat(plugins, "\n")
  end
  if #mason > 0 then
    counted[#counted + 1] = count(#mason, "Mason package", "Mason packages")
    body[#body + 1] = "Mason packages:\n" .. table.concat(mason, "\n")
  end
  body[#body + 1] = "scripts/check --full passed with these versions."
  return "chore(deps): update " .. table.concat(counted, " and "), table.concat(body, "\n\n")
end

-- What scripts/update --list prints: each plugin that would move, with its
-- GitHub page, and each Mason package behind its newest release.
function M.report(plugins, mason)
  if #plugins + #mason == 0 then
    return { "Every plugin and Mason package is at its latest version." }
  end
  local lines = {}
  if #plugins > 0 then
    lines[#lines + 1] = "Plugins that would move:"
    for _, p in ipairs(plugins) do
      local link = M.compare(p.url, p.from, p.to)
      lines[#lines + 1] = M.line(p.name, p.from, p.to) .. (link and ", " .. link or "")
    end
  end
  if #mason > 0 then
    lines[#lines + 1] = "Mason packages that would move:"
    for _, m in ipairs(mason) do
      lines[#lines + 1] = M.line(m.name, m.from, m.to)
    end
  end
  return lines
end

local function decode(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  local parsed, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  return parsed and type(data) == "table" and data or {}
end

-- Both lock files of the repository at root, as tables.
function M.locks(root)
  return { lazy = decode(root .. "/lazy-lock.json"), mason = decode(root .. "/mason-lock.json") }
end

-- Everything the update, the restore and the list reach, in one table so the
-- tests can pass stand-ins. Only called inside a configured Neovim.
function M.deps()
  return {
    lazy = require("lazy"),
    plugins = function()
      return require("lazy.core.config").plugins
    end,
    parsers = function()
      return require("nvim-treesitter").update(nil, { summary = true })
    end,
    masonlock = require("ach.masonlock"),
    registry = function()
      return require("mason-registry")
    end,
    note = function(text)
      io.stdout:write(text .. "\n")
    end,
  }
end

local function by_name(a, b)
  return a.name < b.name
end

-- Each plugin whose last run left a task with an error, as "name: error",
-- sorted.
local function plugin_errors(plugins)
  local out = {}
  for name, plugin in pairs(plugins) do
    for _, task in ipairs(plugin._ and plugin._.tasks or {}) do
      if task:has_errors() then
        out[#out + 1] = ("%s: %s"):format(name, vim.trim(task:output(vim.log.levels.ERROR)))
        break
      end
    end
  end
  table.sort(out)
  return out
end

-- Starts work that reports through a callback, and waits for it. Returns the
-- callback's arguments as a list, or nil when the wait ran out.
local function await(start)
  local result
  start(function(...)
    result = { ... }
  end)
  if vim.wait(M.TIMEOUT, function()
    return result ~= nil
  end, 100) then
    return result
  end
end

-- Rebuilds every installed parser whose revision differs from the one
-- nvim-treesitter names now. A rebuild already running is waited for, not
-- started twice. Returns a failure line, or nil.
local function parsers(deps)
  deps.note("Rebuilding each tree-sitter parser whose revision moved")
  local ok, built = deps.parsers():pwait(M.TIMEOUT)
  if not ok then
    return ("tree-sitter: the parsers did not finish (%s)"):format(tostring(built))
  elseif not built then
    return "tree-sitter: a parser did not build, and :checkhealth nvim-treesitter names it"
  end
end

-- The update: plugins, then the parsers their new revisions name, then Mason
-- packages and their pins. Returns one line per failure; empty means it worked.
function M.apply(deps)
  deps = deps or M.deps()
  deps.note("Updating every plugin")
  deps.lazy.update({ wait = true, show = false })
  local failures = plugin_errors(deps.plugins())
  failures[#failures + 1] = parsers(deps)
  deps.note("Updating every Mason package and its pin")
  local result = await(function(done)
    deps.masonlock.update(done)
  end)
  if not result then
    failures[#failures + 1] = "Mason: the update did not finish within thirty minutes"
    return failures
  end
  for _, name in ipairs(result[2]) do
    failures[#failures + 1] = ("Mason: %s did not update"):format(name)
  end
  return failures
end

-- The undo, once the lock files are back as committed: every plugin to the
-- commit lazy-lock.json pins, every parser to the revision that names, and
-- every pinned Mason package away from its pin back to it. Returns one line
-- per failure.
function M.restore(deps)
  deps = deps or M.deps()
  deps.note("Returning every plugin to the commit lazy-lock.json pins")
  deps.lazy.restore({ wait = true, show = false })
  local failures = plugin_errors(deps.plugins())
  failures[#failures + 1] = parsers(deps)
  deps.note("Returning every Mason package to the version mason-lock.json pins")
  local registry = deps.registry()
  await(function(done)
    registry.refresh(done)
  end)
  local lock, drifted = deps.masonlock.read(), {}
  for _, p in ipairs(registry.get_installed_packages()) do
    if lock[p.name] and p:get_installed_version() ~= lock[p.name] then
      drifted[#drifted + 1] = p.name
    end
  end
  table.sort(drifted)
  local left = #drifted
  for _, name in ipairs(drifted) do
    deps.masonlock.install(name, function(ok, err)
      if not ok then
        local line = "Mason: %s did not return to %s: %s"
        failures[#failures + 1] = line:format(name, lock[name], err or "no reason given")
      end
      left = left - 1
    end)
  end
  if not vim.wait(M.TIMEOUT, function()
    return left == 0
  end, 100) then
    failures[#failures + 1] = "Mason: returning the packages did not finish within thirty minutes"
  end
  return failures
end

-- What an update would move, without moving it: lazy.nvim's check fetches
-- every plugin and prints the commits it would take, and Mason's registry is
-- refreshed for the newest releases. Returns the plugins and the Mason
-- packages that would move, and any plugin whose fetch failed.
function M.pending(deps)
  deps = deps or M.deps()
  deps.lazy.check({ wait = true, show = false })
  local all, plugins = deps.plugins(), {}
  for name, plugin in pairs(all) do
    local updates = plugin._ and plugin._.updates
    if updates then
      plugins[#plugins + 1] = { name = name, from = updates.from.commit, to = updates.to.commit, url = plugin.url }
    end
  end
  table.sort(plugins, by_name)
  local registry, mason = deps.registry(), {}
  await(function(done)
    registry.refresh(done)
  end)
  for _, p in ipairs(registry.get_installed_packages()) do
    local installed, latest = p:get_installed_version(), p:get_latest_version()
    if installed ~= latest then
      mason[#mason + 1] = { name = p.name, from = installed or "an unknown version", to = latest }
    end
  end
  table.sort(mason, by_name)
  return plugins, mason, plugin_errors(all)
end

local ACTIONS = {
  apply = function()
    return M.apply()
  end,
  restore = function()
    return M.restore()
  end,
  list = function()
    local plugins, mason, errors = M.pending()
    io.stdout:write(table.concat(M.report(plugins, mason), "\n") .. "\n")
    return errors
  end,
}

-- Runs one action inside the headless Neovim that scripts/update starts,
-- prints each failure and quits: exit 0 when nothing failed, 1 otherwise. A
-- headless Neovim keeps running after an error in a -c command, so every path
-- through here ends in a quit.
function M.child(action)
  local ok, result = xpcall(function()
    local work = ACTIONS[action]
    if not work then
      error("scripts/update has no action named " .. tostring(action), 0)
    end
    return work()
  end, debug.traceback)
  local failures = ok and result or { tostring(result) }
  for _, failure in ipairs(failures) do
    io.stderr:write(failure .. "\n")
  end
  vim.cmd(#failures == 0 and "qa!" or "cquit 1")
end

-- Runs argv and waits for it. With capture set, returns its exit code and
-- what it printed to each stream. Otherwise its output goes straight to the
-- terminal, since an update and the full check take minutes and report as
-- they go, and only the exit code returns.
function M.exec(argv, capture)
  if capture then
    local r = vim.system(argv, { text = true }):wait()
    return r.code, r.stdout or "", r.stderr or ""
  end
  local function through(stream)
    return function(_, data)
      if data then
        stream:write(data)
      end
    end
  end
  return vim.system(argv, { stdout = through(io.stdout), stderr = through(io.stderr) }):wait().code
end

-- The headless Neovim, started with this configuration, that runs action.
local function inside(root, action)
  local command = ("lua require('ach.update').child(%q)"):format(action)
  return { vim.v.progpath, "--headless", "-u", root .. "/init.lua", "-c", command }
end

local DIRTY = "These files have changes that are not committed, and undoing a failed update would lose them:\n"
  .. "%s\nCommit or restore them, then run scripts/update again."
local BACK = " The lock files are restored and every plugin and Mason package is back at its pinned version."
  .. " Nothing was committed."
local NOT_BACK = " The lock files are restored, but putting the installed versions back failed as well, as printed"
  .. " above. Once that is fixed, run scripts/update --restore. Nothing was committed."

-- A whole update of the repository at root: refuse over changes that are not
-- committed, update, run the full check, then commit or undo. Returns the
-- exit code. opts.apply, opts.check and opts.restore replace the three slow
-- steps, and opts.say replaces printing.
function M.run(root, opts)
  opts = opts or {}
  local apply = opts.apply or function()
    return M.exec(inside(root, "apply"))
  end
  local check = opts.check or function()
    return M.exec({ root .. "/scripts/check", "--full" })
  end
  local restore = opts.restore or function()
    return M.exec(inside(root, "restore"))
  end
  local say = opts.say or function(text)
    io.stdout:write(text .. "\n")
  end
  local function git(...)
    return M.exec({ "git", "--no-optional-locks", "-C", root, ... }, true)
  end

  local code, dirty, err = git("status", "--porcelain", "--", unpack(M.FILES))
  if code ~= 0 then
    say("git could not read the repository's status: " .. vim.trim(err))
    return 1
  end
  if vim.trim(dirty) ~= "" then
    say(DIRTY:format((dirty:gsub("\n$", ""))))
    return 2
  end
  local before = M.locks(root)

  local function undo(why, status)
    git("checkout", "HEAD", "--", unpack(M.FILES))
    if restore() == 0 then
      say(why .. BACK)
      return status
    end
    say(why .. NOT_BACK)
    return 1
  end

  if apply() ~= 0 then
    return undo("The update failed before the full check ran.", 1)
  end
  if not M.message(before, M.locks(root)) then
    git("checkout", "HEAD", "--", unpack(M.FILES))
    say("Every plugin and Mason package was already at its latest version. Nothing was committed.")
    return 0
  end
  local status = check()
  if status == 2 then
    return undo("The full check needs a person to act, so it has not proven the update.", 2)
  elseif status ~= 0 then
    return undo("The full check failed after the update.", 1)
  end
  local subject, body = M.message(before, M.locks(root))
  local committed, _, why = git("commit", "--quiet", "--only", "-m", subject, "-m", body, "--", unpack(M.FILES))
  if committed ~= 0 then
    say("The full check passed, but git could not commit the lock files: " .. vim.trim(why))
    return 1
  end
  say("Committed: " .. subject)
  return 0
end

if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "update.lua" then
  local ok, status = xpcall(function()
    return M.run(assert(_G.arg[1], "usage: nvim -l lua/ach/update.lua ROOT"))
  end, debug.traceback)
  if not ok then
    io.stderr:write(tostring(status) .. "\n")
    os.exit(1)
  end
  os.exit(status)
end

return M
```

`failures[#failures + 1] = parsers(deps)` adds nothing when `parsers` returns nil, because assigning nil to a table slot leaves the table as it was. The update keeps going after a plugin fails, so a single run names every failure, and the undo puts all of it back regardless.

- [ ] **Write the script**

`scripts/update`:

```bash
#!/usr/bin/env bash
# Update ACH-NEOVIM's plugins and Mason packages, and keep the update only if the full check passes.
#   scripts/update            update, run scripts/check --full, then commit or put everything back
#   scripts/update --list     name what an update would move, with each plugin's commits, installing nothing
#   scripts/update --restore  put every plugin and Mason package back at the version the lock files pin
# Exit 0 on success, 1 on a failure, 2 when a person must act.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
action=update
while [ $# -gt 0 ]; do
    case "$1" in
        --list) action=list ;;
        --restore) action=restore ;;
        -h | --help) sed -n '2,/^# Exit/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

if ! command -v nvim >/dev/null 2>&1; then
    echo "Neovim is not installed. Install it with: brew install neovim" >&2
    exit 2
fi

# An update runs from outside the editor, because it starts one Neovim to
# update, runs the full check, and may start another to undo. The list and
# the restore each run inside a single headless Neovim.
if [ "$action" = update ]; then
    exec nvim -l "$root/lua/ach/update.lua" "$root"
fi
exec nvim --headless -u "$root/init.lua" -c "lua require('ach.update').child('$action')"
```

Run: `chmod +x scripts/update`
Expected: no output, exit 0.

- [ ] **Name the script in the README**

In `README.md`, the paragraph that reads

```markdown
The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite.
```

becomes

```markdown
The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite. `scripts/update --list` names what an update would move, and `scripts/update` moves it, runs `scripts/check --full` and commits the lock files only when that passes, putting every plugin and Mason package back otherwise.
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. `test_update` reports eleven passed.

- [ ] **See what an update would move**

Run: `scripts/update --list`
Expected: lazy.nvim's check output, one block of fetch and log lines per plugin, then either `Every plugin and Mason package is at its latest version.` or the two lists, exit 0. This step reaches GitHub and Mason's registry, to read what is newest, and installs nothing. It is the one run of the list that touches the real lazy.nvim and Mason, which the tests replace. Afterwards `git status --short lazy-lock.json mason-lock.json` prints nothing.

- [ ] **Return everything to its pins**

Run: `scripts/update --restore`
Expected: lazy.nvim's restore output, one block of lines per plugin, and exit 0. Every plugin and Mason package is already at its pin after the earlier tasks, so nothing moves. This is the one run of the restore against the real plugins. Afterwards `git status --short lazy-lock.json mason-lock.json` prints nothing. If either step exits 1, the lines it printed name what failed; fix the cause, not the test.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/update.lua scripts/update tests/test_update.lua
git commit --only lua/ach/update.lua scripts/update tests/test_update.lua README.md -m "feat(update): update plugins and Mason packages, and keep them only when the full check passes"
```

---

### Task: Neovim Upgrade Check

**Files:**
- Create: `lua/ach/upgrade.lua`
- Modify: `lua/ach/init.lua` (replace the whole file; it gains one line), `README.md` (one paragraph gains a sentence)
- Test: `tests/test_upgrade.lua`

**Interfaces:**
- Consumes: the foundation's `vim.g.ach_root`, the repository's real path; `scripts/check`, its exit codes and its last line, `"%d passed, %d failed, %d need a person, %d skipped"`, which the suite writes to standard output; the languages plan's `lua/ach/init.lua`; `tests/run.lua`, which fires VeryLazy in a headless run; the harness's `t.tmpdir()`, `t.eq` and `t.ok`.
- Produces: `require("ach.upgrade")`, a table with `stamp` (the path of the record, `stdpath("state") .. "/ach/checked-nvim"`), `current() -> { version: string, program: string }`, `recorded(stamp) -> string|nil`, `wanted() -> boolean`, `check(root, program, done) -> vim.SystemObj|nil`, where `done(code: integer, summary: string)` is called on the main loop, `start(opts?) -> boolean`, whose `opts` may replace `current`, `stamp`, `root`, `check` and `notify`, and `setup()`, which creates the autocommand group `ach_upgrade`.

The spec says the fast check runs after each `brew upgrade` that moves Neovim. Homebrew updates Neovim on its own schedule, whenever any `brew upgrade` runs, so a new release can arrive without anyone deciding to take it, and a release that breaks one plugin would otherwise go unnoticed until the broken key is pressed. This task makes the first start of each new release run the fast check by itself and say whether the configuration still passes.

The first thing to settle is how the editor knows it is new. Homebrew installs each release into a folder of its own, such as `/opt/homebrew/Cellar/neovim/0.12.6/`, and `/opt/homebrew/bin/nvim` is a link, a small file that points at the program in the current release's folder. Neovim records the path it was started from in `vim.v.progpath`, and `vim.uv.fs_realpath` follows every link to the file it ends at, so the real path of the running program names its release. It also changes when Homebrew rebuilds the same release, which it marks with a suffix such as `0.12.6_1`, and a rebuild can break a plugin as surely as a new release, so the path is a better name for "this Neovim" than the version number is.

The record is a one-line file in Neovim's state folder, `~/.local/state/nvim/ach/checked-nvim`, holding the real path of the last program the check passed on. At start, if that line matches the running program, nothing happens. Otherwise the check runs, and the line is written only when it passes. A failure, a check that needs a person, or quitting the editor before the check ends all leave the record as it was, so the next start runs the check again until it passes. The first start after this task is committed runs it once too, because nothing is recorded yet.

The check waits for VeryLazy, the moment after the first screen has drawn, so it never slows a start. It runs `scripts/check` with `vim.system`, which starts a program without waiting for it and calls a function when the program ends; the fast check takes about a minute and the editor works as usual meanwhile. One notice says the check has started and a second gives its result, using the suite's own last line, such as `120 passed, 0 failed, 0 need a person, 0 skipped`. A failure is shown as an error and names the folder to run `scripts/check` in to see which test failed.

Three details of how the program is started each have a reason. `scripts/check` runs whichever `nvim` comes first on the path, the list of folders the shell searches for a program, so the running program's own folder is put first, and the check tests the Neovim that asked for it even if another `nvim` sits earlier on the path. Neovim sets the variable `NVIM` for every program it starts, to tell a program it runs inside the editor's terminal; the check does not, so the variable is removed and the check runs exactly as it would from a shell. And when a program is ended by a signal, such as the one macOS sends every program when it shuts down, `vim.system` reports the exit code as 0 and the signal on its own, so the module counts any signal as a failure and an interrupted check is never mistaken for a pass.

A Neovim with no screen never runs the check, and neither does the test suite. Neovim started by a script, by `nvim --headless`, by Skim or by `scripts/update` has no screen, which `vim.api.nvim_list_uis()` reports as an empty list. The suite's own Neovim sets `ACH_TEST=1` as well. Either one alone is enough, and both matter here, because the check runs the suite: a suite that ran the check would start itself again, without end. Two editors started together after an upgrade each run a check, which is harmless, since every run of `scripts/check` works in a throwaway folder of its own and writes nothing in the repository. For the same reason, a check still running when its editor quits changes nothing; its result is lost, and the next start runs it again.

- [ ] **Write the failing tests**

`tests/test_upgrade.lua`:

```lua
-- lua/ach/upgrade.lua. The fast check runs once for each Neovim program
-- Homebrew installs, only in a Neovim on a screen outside the suite, and the
-- program is recorded only when the check passes. The check is a stand-in, or
-- a small script in a throwaway folder, so nothing here runs the real suite.

-- Replaces fields for the length of body and puts every one back, even when
-- body fails. Each stub is { table, key, value }.
local function with(stubs, body)
  local saved = {}
  for i, s in ipairs(stubs) do
    saved[i] = s[1][s[2]]
    s[1][s[2]] = s[3]
  end
  local ok, err = pcall(body)
  for i = #stubs, 1, -1 do
    stubs[i][1][stubs[i][2]] = saved[i]
  end
  if not ok then
    error(err, 0)
  end
end

-- A Neovim the check has not seen.
local NEW = { version = "0.12.7", program = "/opt/homebrew/Cellar/neovim/0.12.7/bin/nvim" }

-- Calls start with a stand-in check that answers code and summary at once,
-- and returns what start returned, how many times the check ran, and every
-- notice, as { msg, level }.
local function run(stamp, code, summary)
  local runs, said = 0, {}
  local started = require("ach.upgrade").start({
    current = NEW,
    stamp = stamp,
    root = "/ach",
    check = function(_, _, done)
      runs = runs + 1
      done(code, summary)
    end,
    notify = function(msg, level)
      said[#said + 1] = { msg = msg, level = level }
    end,
  })
  return started, runs, said
end

-- Makes a throwaway folder laid out like the repository, whose scripts/check
-- is a shell script running body, and returns the folder.
local function repo(t, body)
  local root = t.tmpdir()
  vim.fn.mkdir(root .. "/scripts", "p")
  local path = root .. "/scripts/check"
  vim.fn.writefile({ "#!/bin/sh", body }, path)
  vim.fn.setfperm(path, "rwxr-xr-x")
  return root
end

-- Runs the real check on root and waits up to ten seconds for its answer.
local function check(root, program)
  local got
  require("ach.upgrade").check(root, program or vim.v.progpath, function(code, summary)
    got = { code = code, summary = summary }
  end)
  vim.wait(10000, function()
    return got ~= nil
  end, 20)
  assert(got, "the check answered within ten seconds")
  return got
end

return {
  ["the check is wanted only on a screen, outside the suite"] = function(t)
    local U = require("ach.upgrade")
    t.eq(U.wanted(), false, "not in the suite, which has no screen")
    local screen = function()
      return { {} }
    end
    with({ { vim.api, "nvim_list_uis", screen } }, function()
      t.eq(U.wanted(), false, "not in the suite, even with a screen")
      with({ { vim.env, "ACH_TEST", "0" } }, function()
        t.eq(U.wanted(), true, "a Neovim on a screen, outside the suite")
      end)
    end)
    with({ { vim.env, "ACH_TEST", "0" } }, function()
      t.eq(U.wanted(), false, "not without a screen, as under a script or Skim")
    end)
  end,

  ["a Neovim the check already passed on starts nothing"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    vim.fn.writefile({ NEW.program }, stamp)
    local started, runs, said = run(stamp, 0, "unused")
    t.eq(started, false, "no check started")
    t.eq(runs, 0, "the check did not run")
    t.eq(#said, 0, "nothing was said")
  end,

  ["a new Neovim runs the check once, and a pass records it"] = function(t)
    local stamp = t.tmpdir() .. "/ach/checked-nvim"
    local summary = "120 passed, 0 failed, 0 need a person, 0 skipped"
    local started, runs, said = run(stamp, 0, summary)
    t.eq(started, true, "a check started")
    t.eq(runs, 1, "the check ran once")
    t.eq(said, {
      {
        msg = "Neovim 0.12.7 has not been checked yet, so the fast check is running in the background.",
        level = vim.log.levels.INFO,
      },
      { msg = "The fast check passed on Neovim 0.12.7: " .. summary .. ".", level = vim.log.levels.INFO },
    })
    t.eq(vim.fn.readfile(stamp), { NEW.program }, "the program is recorded, in a folder made for it")
    local again, reruns = run(stamp, 0, summary)
    t.eq({ again, reruns }, { false, 0 }, "the next start runs nothing")
  end,

  ["a failed check is an error, records nothing, and runs again at the next start"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    local summary = "119 passed, 1 failed, 0 need a person, 0 skipped"
    local _, _, said = run(stamp, 1, summary)
    t.eq(said[2], {
      msg = "The fast check failed on Neovim 0.12.7: " .. summary .. ". Run scripts/check in /ach to see which test.",
      level = vim.log.levels.ERROR,
    })
    t.eq(vim.uv.fs_stat(stamp), nil, "nothing is recorded")
    local again, reruns = run(stamp, 0, "120 passed, 0 failed, 0 need a person, 0 skipped")
    t.eq({ again, reruns }, { true, 1 }, "the next start runs the check again")
  end,

  ["a check that needs a person is a warning and runs again at the next start"] = function(t)
    local stamp = t.tmpdir() .. "/checked-nvim"
    local summary = "119 passed, 0 failed, 1 need a person, 0 skipped"
    local _, _, said = run(stamp, 2, summary)
    t.eq(said[2], {
      msg = "The fast check on Neovim 0.12.7 needs a person: " .. summary .. ". Run scripts/check in /ach to see what.",
      level = vim.log.levels.WARN,
    })
    t.eq(vim.uv.fs_stat(stamp), nil, "nothing is recorded")
    local again, reruns = run(stamp, 2, summary)
    t.eq({ again, reruns }, { true, 1 }, "the next start runs the check again")
  end,

  ["the check reports the last line the suite printed, and its exit code"] = function(t)
    local got = check(repo(t, "printf 'one\\ntwo\\n12 passed, 1 failed, 0 need a person, 0 skipped\\n\\n'; exit 1"))
    t.eq(got, { code = 1, summary = "12 passed, 1 failed, 0 need a person, 0 skipped" }, "the last line with text")
    got = check(repo(t, "echo 'Neovim is not installed.' >&2; exit 2"))
    t.eq(got, { code = 2, summary = "Neovim is not installed." }, "the error output, when nothing else was printed")
    got = check(repo(t, "exit 0"))
    t.eq(got, { code = 0, summary = "it printed nothing" }, "a check that printed nothing")
  end,

  ["a check ended by a signal, or one that cannot start, is a failure"] = function(t)
    local got = check(repo(t, "echo started; kill -TERM $$"))
    t.eq(got, { code = 1, summary = "started" }, "ended by a signal")
    got = check(t.tmpdir())
    t.eq(got.code, 1, "a folder with no scripts/check")
    t.ok(got.summary:find("scripts/check", 1, true) ~= nil, "naming the script that could not start")
  end,

  ["the check runs the Neovim that asked for it, as from a shell outside the editor"] = function(t)
    local root = repo(t, [[printf '%s %s\n' "${PATH%%:*}" "${NVIM-unset}"]])
    local got = check(root, "/opt/homebrew/Cellar/neovim/0.12.7/bin/nvim")
    t.eq(got.summary, "/opt/homebrew/Cellar/neovim/0.12.7/bin unset", "its folder first on the path, and no NVIM")
  end,

  ["the running Neovim is named by its program's real path and its version"] = function(t)
    local now = require("ach.upgrade").current()
    t.eq(now.program, vim.uv.fs_realpath(vim.v.progpath), "the real path, with every link followed")
    local v = vim.version()
    t.eq(now.version, ("%d.%d.%d"):format(v.major, v.minor, v.patch), "the version")
    t.ok(now.version:match("^%d+%.%d+%.%d+$") ~= nil, "written as x.y.z")
  end,

  ["the check is set up at startup, to run after the first screen when it is wanted"] = function(t)
    local U = require("ach.upgrade")
    t.ok(pcall(vim.api.nvim_get_autocmds, { group = "ach_upgrade" }), "init.lua set it up")
    U.setup()
    local found = vim.api.nvim_get_autocmds({ group = "ach_upgrade", event = "User", pattern = "VeryLazy" })
    t.eq(#found, 1, "one handler, on VeryLazy")
    local starts = 0
    local function count()
      starts = starts + 1
    end
    local function never()
      return false
    end
    local function always()
      return true
    end
    with({ { U, "start", count }, { U, "wanted", never } }, function()
      found[1].callback()
    end)
    t.eq(starts, 0, "not when it is not wanted")
    with({ { U, "start", count }, { U, "wanted", always } }, function()
      found[1].callback()
    end)
    t.eq(starts, 1, "once when it is wanted")
    vim.api.nvim_del_augroup_by_name("ach_upgrade")
  end,
}
```

`t.eq(vim.uv.fs_stat(stamp), nil, ...)` compares only the first of the three values `fs_stat` returns for a missing file, because a call in the middle of an argument list gives up all but its first value. The same rule keeps `t.ok(pcall(...), "init.lua set it up")` to `pcall`'s first value, true when the group exists. The last test deletes the group it set up again, so no handler is left behind for a later VeryLazy.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_upgrade`
Expected: `0 passed, 10 failed, 0 need a person, 0 skipped`, exit 1. Every test loads `ach.upgrade` before it checks anything, so all ten fail on `module 'ach.upgrade' not found`.

- [ ] **Write the upgrade check**

`lua/ach/upgrade.lua`:

```lua
-- Runs the fast check once after Homebrew moves Neovim, so a release that
-- breaks the configuration is found the day it arrives rather than the day a
-- broken key is pressed. The running program's real path names the release,
-- and a one-line record in the state folder holds the last one that passed.
local M = {}

M.stamp = vim.fn.stdpath("state") .. "/ach/checked-nvim"

-- The running Neovim: its version as x.y.z, and its program's real path,
-- which lies in Homebrew's folder for that release, so it changes with every
-- release and every rebuild of one.
function M.current()
  local v = vim.version()
  return {
    version = ("%d.%d.%d"):format(v.major, v.minor, v.patch),
    program = vim.uv.fs_realpath(vim.v.progpath) or vim.v.progpath,
  }
end

-- The program the check last passed on, or nil when it has never passed.
function M.recorded(stamp)
  local file = io.open(stamp, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  return line
end

-- Only a Neovim on a screen, outside the test suite. The suite has no screen
-- and sets ACH_TEST, and either alone keeps the check, which runs the suite,
-- from starting itself again.
function M.wanted()
  return vim.env.ACH_TEST ~= "1" and #vim.api.nvim_list_uis() > 0
end

-- Runs root/scripts/check in the background with program's folder first on
-- the path and NVIM removed, and calls done(code, summary) on the main loop.
-- summary is the last line the check printed, or of its error output when it
-- printed nothing else. A check ended by a signal, or one that cannot start,
-- reports code 1.
function M.check(root, program, done)
  local env = vim.fn.environ()
  env.PATH = vim.fs.dirname(program) .. ":" .. (env.PATH or "")
  env.NVIM = nil
  local cmd = { root .. "/scripts/check" }
  local ok, proc = pcall(vim.system, cmd, { text = true, env = env, clear_env = true }, function(res)
    local text = vim.trim(res.stdout or "")
    if text == "" then
      text = vim.trim(res.stderr or "")
    end
    local lines = vim.split(text, "\n", { trimempty = true })
    local summary = lines[#lines] or "it printed nothing"
    local code = res.signal ~= 0 and 1 or res.code
    vim.schedule(function()
      done(code, summary)
    end)
  end)
  if not ok then
    vim.schedule(function()
      done(1, tostring(proc))
    end)
    return nil
  end
  return proc
end

-- Runs the check when the running Neovim is not the one it last passed on,
-- and says what came of it. Returns true when a check started. opts may
-- replace current, stamp, root, check and notify; the tests use that.
function M.start(opts)
  opts = opts or {}
  local now = opts.current or M.current()
  local stamp = opts.stamp or M.stamp
  local root = opts.root or vim.g.ach_root
  local check = opts.check or M.check
  local notify = opts.notify or vim.notify
  if M.recorded(stamp) == now.program then
    return false
  end
  local levels = vim.log.levels
  notify(
    ("Neovim %s has not been checked yet, so the fast check is running in the background."):format(now.version),
    levels.INFO
  )
  check(root, now.program, function(code, summary)
    if code == 0 then
      vim.fn.mkdir(vim.fs.dirname(stamp), "p")
      vim.fn.writefile({ now.program }, stamp)
      notify(("The fast check passed on Neovim %s: %s."):format(now.version, summary), levels.INFO)
    elseif code == 2 then
      local msg = "The fast check on Neovim %s needs a person: %s. Run scripts/check in %s to see what."
      notify(msg:format(now.version, summary, root), levels.WARN)
    else
      local msg = "The fast check failed on Neovim %s: %s. Run scripts/check in %s to see which test."
      notify(msg:format(now.version, summary, root), levels.ERROR)
    end
  end)
  return true
end

-- Waits for VeryLazy, after the first screen has drawn, so the check never
-- slows a start.
function M.setup()
  local group = vim.api.nvim_create_augroup("ach_upgrade", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "VeryLazy",
    once = true,
    callback = function()
      if M.wanted() then
        M.start()
      end
    end,
  })
end

return M
```

`vim.system` calls its last argument from inside libuv, the library Neovim uses to wait for programs, at a moment when most of Neovim's own functions may not be called. `vim.schedule` hands `done` to the main loop, where showing a notice and writing a file are allowed. When the program cannot start at all, `vim.system` raises an error naming it, such as `ENOENT: no such file or directory (cmd): '/…/scripts/check'`, and `pcall` turns that into a failure with the error as its summary, so a missing script is reported rather than breaking the start.

- [ ] **Run them again**

Run: `scripts/check --only test_upgrade`
Expected: `9 passed, 1 failed, 0 need a person, 0 skipped`, exit 1. The last test fails on its first check, `init.lua set it up`, because nothing calls `setup()` at startup yet.

- [ ] **Set it up at startup**

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. File types are added, Homebrew's Java,
-- Ruby and the toolchain folders put on the path, spelling and Harper's
-- settings put in place, the managed languages' plugins told not to start
-- their own servers, and the installer's hooks created before lazy.nvim
-- starts, so a file named on the command line is recognised, checked, and
-- gets its parsers, tools and server when it opens. Keymaps wait for
-- VeryLazy, after the first screen has drawn, and so does the check that
-- runs once after Homebrew moves Neovim.
require("ach.options")
require("ach.autocmds")
require("ach.filetypes").setup()
require("ach.runtimes").setup()
require("ach.grammar").setup()
require("ach.managed").setup()
require("ach.install").setup()
require("ach.upgrade").setup()
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

Only the last two lines of the header comment and the `require("ach.upgrade").setup()` line are new.

- [ ] **Name the check in the README**

In `README.md`, the paragraph that reads

```markdown
The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite. `scripts/update --list` names what an update would move, and `scripts/update` moves it, runs `scripts/check --full` and commits the lock files only when that passes, putting every plugin and Mason package back otherwise.
```

becomes

```markdown
The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite. `scripts/update --list` names what an update would move, and `scripts/update` moves it, runs `scripts/check --full` and commits the lock files only when that passes, putting every plugin and Mason package back otherwise. The first time Neovim starts on a screen after Homebrew moves it to a new release, it runs `scripts/check` in the background and says whether the configuration still passes.
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. `test_upgrade` reports ten passed. No key, program or plugin is added, so `lua/ach/icons.lua`, `lua/ach/need.lua` and `lazy-lock.json` do not change.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/upgrade.lua tests/test_upgrade.lua
git commit --only lua/ach/upgrade.lua tests/test_upgrade.lua lua/ach/init.lua README.md -m "feat(upgrade): run the fast check once after Homebrew moves Neovim"
```

The first start in Ghostty after this commit shows the check at work: one notice that it is running, and about a minute later one that it passed. That start records the program, and the next start says nothing.

---

### Task: Key Card

**Files:**
- Create: `docs/key-card.md`
- Test: `tests/test_key_card.lua`

**Interfaces:**
- Consumes: `require("ach.testhook").keymaps`, the foundation's record of every `vim.keymap.set` made from a file under `lua/ach/`, each `{ mode, lhs, desc, where }`, where `mode` is a string or a list; `require("ach.lsp").keys`, the language server's keys, each `{ lhs, action, desc = string, has = string }` with an optional `mode`; three functions that set keys on one buffer, `require("ach.git").on_attach(buf)` from the Git task, `require("ach.latex").attach(buf)` from the LaTeX task and `require("ach.preview").attach(buf)` from the Markdown task; the which-key spec, read as `Plugin.values(Config.plugins["which-key.nvim"], "opts", false).spec`; lazy.nvim's own key resolver, `require("lazy.core.handler.keys").resolve`; `ghostty/config.ghostty` and its table of Ghostty's keys from the Ghostty task; and the test helper's `t.root`, `t.tmpdir()` and `t.skip`.
- Produces: `docs/key-card.md`, which the foundation's dashboard names in its tips, and `tests/test_key_card.lua`.

The key card is one page to keep beside the keyboard while the keys are new. It runs in this order: the idea behind the keys, the menus, the keys used every day grouped by the kind of work, the keys outside the menus, Ghostty's own keys, and the few things that catch people out. Every key in it carries a plain sentence saying what it does, because a description such as "Grep (Root Dir)" means nothing to someone who has not met grep.

A card like this goes wrong quietly. A later change renames a key's description or moves a key to another letter, nothing complains, and the card goes on telling its reader to press a key that no longer does what it says. So the card is checked. A test reads `docs/key-card.md` and compares it with the keys the running configuration actually has, and a key renamed, moved or removed fails `scripts/check` until the card is changed to match.

The card is Markdown, and its keys sit in tables. A Markdown table is a set of lines that start and end with `|`, with a `|` between each pair of cells: the first line is the header, the second is a line of `---` cells that marks it as a table, and every line after that is a row. A `|` inside a cell, as in the key `Space |`, is written `\|` so it does not end the cell. The test reads the file line by line, remembers the most recent `## ` heading so it knows which section a table belongs to, and splits each row into its cells.

The card writes keys for a reader: `Space f f` is Space, then f, then f, and `Ctrl-/` is the slash pressed while Ctrl is held. Neovim writes the same keys as `<leader>ff` and `<c-/>`, and a configuration may spell one key several ways, since `<C-/>` and `<c-/>` are the same key and `<leader>` stands for whatever the leader key is. To compare them, the test first turns the card's spelling into Neovim's: each word is one key, a known name such as `Space`, `Tab`, `Esc` or `Down` becomes `<Space>`, `<Tab>`, `<Esc>` or `<Down>`, a word such as `Ctrl-x` becomes `<C-x>` (and `Alt-` becomes `<A-`, `Shift-` becomes `<S-`), and anything else stands for itself. Then both sides pass through the same two Neovim functions. `vim.keycode` turns a written key into the bytes the key actually sends, replacing `<leader>` with the leader key, a space here; `vim.fn.keytrans` turns those bytes back into one canonical spelling. So `Space f f` becomes `<Space>ff`; `<leader>ff` becomes a space followed by ff, which `keytrans` writes as `<Space>ff`; and the two compare equal as plain strings.

Keys live in five places, and the test reads all five, because no one of them holds every key at the moment a test runs. Neovim's own table of keymaps, which `vim.api.nvim_get_keymap(mode)` returns one mode at a time, holds every key set so far. lazy.nvim holds the keys written in plugin specs, and the test reads them from lazy.nvim directly, the same way the foundation's key test does, so a plugin not loaded yet still counts. The foundation's test hook records every key set from a file under `lua/ach/`, whatever mode or buffer it was set on. The language server's keys, such as `g d` and `K`, are set only on a buffer a language server has attached to, which no buffer in the test has, so the test reads the list they are set from, `require("ach.lsp").keys`. The last place is keys set on one buffer at a time: the hunk keys when gitsigns starts tracking a file, `Space c b` when VimTeX takes a LaTeX file, and `Space c p` on a Markdown file. The test makes an empty scratch buffer named `x.md` in a fresh folder, hands it to the three functions that set those keys, reads the keys off it, and wipes it again.

One more step comes first. The two git toggles, `Space u b` among them, are set as gitsigns loads, and gitsigns loads when the first file is read, which may not have happened yet when this test runs. The test asks lazy.nvim to load gitsigns before it reads anything, which does nothing when it is loaded already.

Five tests hold the card to the configuration. The first takes every row of the eight tables with a Description column and checks that some key exists, in any mode, with that key and that description word for word; it also checks that those eight tables are the ones the card has, so a table renamed or dropped is noticed rather than skipped. The second checks the menus table against which-key's groups both ways: every menu on the card is a group which-key shows after Space, with the same name, and every group which-key shows directly after Space is on the card. A group further down, such as `Space g h` for hunks, is a submenu and stays off this table. The third checks that the keys in the table of Neovim's own keys are still Neovim's own: none of them is set in normal mode by a plugin spec, by a file under `lua/ach/` or by the language server's list. The fourth checks that the card names the six Ghostty keys the spec lists, `Command-T`, `Command-D`, `Command-Shift-D`, `Command-=`, `Command-minus` and `Command-0`, and that `ghostty/config.ghostty` has no `keybind` line that gives a Command key a new job. Ghostty calls the Command key `super`, and accepts `cmd` and `command` for it too, so the test looks for all three.

The fifth runs Ghostty's command line, without opening a window. `ghostty +list-keybinds --default --plain` prints the keys Ghostty has before any settings file is read, one to a line, each with the action it runs after an `=`, such as `new_tab` or `new_split:right`. The test checks that each of the six actions appears on a line that also holds `super+`, so a Ghostty release that moved one of them fails here rather than on the reader. Like the Ghostty task's tests, it uses the command inside the app when the path has none, and skips, naming the cask, until Ghostty is installed.

Every test reads the card before anything else, so while the card does not exist all five fail on the same line.

- [ ] **Write the failing tests**

`tests/test_key_card.lua`:

```lua
-- docs/key-card.md, the one-page key card, checked against the keys the
-- running configuration has. A key renamed, moved or removed fails here until
-- the card says the same.

local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")

local CARD = "/docs/key-card.md"

-- The sections whose tables have a Description column, in the card's order.
local SECTIONS = {
  "Files and buffers",
  "Search and moving",
  "Code",
  "Git",
  "Claude Code",
  "Debugging",
  "Windows and toggles",
  "Outside the menus",
}

-- The six Ghostty keys the spec names, each with the action Ghostty's own
-- defaults give it, as +list-keybinds prints the action after an =.
local GHOSTTY = {
  { "Command-T", "=new_tab" },
  { "Command-D", "=new_split:right" },
  { "Command-Shift-D", "=new_split:down" },
  { "Command-=", "=increase_font_size" },
  { "Command-minus", "=decrease_font_size" },
  { "Command-0", "=reset_font_size" },
}

-- The modes a key can be set in, one letter each.
local MODES = { "n", "x", "s", "o", "i", "c", "t" }

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

-- The cask installs the app and puts no ghostty command on the PATH, so the
-- command inside the app is used when the PATH has none.
local APP = "/Applications/Ghostty.app/Contents/MacOS/ghostty"

local function ghostty()
  local bin = vim.fn.exepath("ghostty")
  if bin == "" and vim.fn.executable(APP) == 1 then
    bin = APP
  end
  return bin ~= "" and bin or nil
end

-- Every key a plugin spec declares, one entry per mode, in a stable order.
local function plugin_keys()
  local out = {}
  for name, plugin in pairs(Config.plugins) do
    for _, k in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
      k.plugin = name
      out[#out + 1] = k
    end
  end
  table.sort(out, function(a, b)
    return a.plugin .. a.id < b.plugin .. b.id
  end)
  return out
end

-- The which-key groups, found by walking the nested spec tables.
local function groups(spec, out)
  out = out or {}
  for _, item in ipairs(spec or {}) do
    if type(item) == "table" then
      if type(item[1]) == "string" and item.group then
        out[item[1]] = item.group
      end
      groups(item, out)
    end
  end
  return out
end

-- Runs body, then closes every tab and window it opened and wipes every
-- buffer, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  vim.cmd("silent! tabonly!")
  vim.cmd("silent! only!")
  vim.cmd("silent! %bwipeout!")
  if not ok then
    error(err, 0)
  end
end

-- A key in one canonical spelling: vim.keycode turns it into the bytes the
-- key sends, putting the leader key in for <leader>, and vim.fn.keytrans
-- writes those bytes back, so "<leader>ff" and "<Space>ff" come out the same.
local function norm(lhs)
  return vim.fn.keytrans(vim.keycode(lhs))
end

-- A key as the card writes it, such as "Space f f", "Ctrl-/" or "Alt-Down",
-- in the same canonical spelling. Each word is one key, and a modifier is
-- joined to its key with a hyphen.
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

-- Whether a key set in mode, a letter, a list of letters or nil for normal
-- mode alone, is set in normal mode. "" is normal, visual and operator mode.
local function normal(mode)
  if mode == nil then
    return true
  end
  if type(mode) == "string" then
    mode = { mode }
  end
  return vim.tbl_contains(mode, "n") or vim.tbl_contains(mode, "")
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

-- The card's lines, and its tables, each { section, header, rows }: the
-- ## heading above the table, the cells of its first line, and the cells of
-- each line after the | --- | line.
local function read(t)
  local ok, lines = pcall(vim.fn.readfile, t.root .. CARD)
  t.ok(ok and #lines > 0, "docs/key-card.md exists")
  local tables, section, current = {}, "", nil
  for i, line in ipairs(lines) do
    if line:match("^## ") then
      section = line:sub(4)
    end
    if line:match("^|%s*%-%-%-") and i > 1 and lines[i - 1]:match("^|") then
      current = { section = section, header = cells(lines[i - 1]), rows = {} }
      tables[#tables + 1] = current
    elseif current and line:match("^|") then
      current.rows[#current.rows + 1] = cells(line)
    elseif not line:match("^|") then
      current = nil
    end
  end
  return tables, lines
end

-- The rows of the one table in section, after checking its header.
local function rows_of(t, tables, section, header)
  for _, tbl in ipairs(tables) do
    if tbl.section == section then
      t.eq(tbl.header, header, "the header of the table in " .. section)
      t.ok(#tbl.rows > 0, "the table in " .. section .. " has rows")
      return tbl.rows
    end
  end
  t.ok(false, "the card has a table in a section called " .. section)
  return {}
end

-- Every key set when this runs, each { lhs, desc } with lhs in the canonical
-- spelling: Neovim's keymaps, lazy.nvim's plugin keys, every vim.keymap.set
-- from lua/ach/, the language server's keys, and the keys git, LaTeX and
-- Markdown set on a buffer, read off a scratch buffer named x.md.
local function set_keys(t)
  local out = {}
  local function add(lhs, desc)
    if lhs and desc then
      out[#out + 1] = { lhs = norm(lhs), desc = desc }
    end
  end
  -- gitsigns sets its two toggles as it loads, and it loads on the first file
  -- read, which may not have happened yet.
  require("lazy").load({ plugins = { "gitsigns.nvim" } })
  tidy(function()
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, t.tmpdir() .. "/x.md")
    require("ach.git").on_attach(buf)
    require("ach.latex").attach(buf)
    require("ach.preview").attach(buf)
    for _, mode in ipairs(MODES) do
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
        add(map.lhs, map.desc)
      end
    end
  end)
  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      add(map.lhs, map.desc)
    end
  end
  for _, k in ipairs(plugin_keys()) do
    add(k.lhs, k.desc)
  end
  for _, k in ipairs(require("ach.testhook").keymaps) do
    add(k.lhs, k.desc)
  end
  for _, k in ipairs(require("ach.lsp").keys) do
    add(k[1], k.desc)
  end
  return out
end

return {
  ["every key in a Description table is set, with that description"] = function(t)
    local tables = read(t)
    local sections, rows = {}, {}
    for _, tbl in ipairs(tables) do
      if tbl.header[2] == "Description" then
        t.eq(tbl.header, { "Key", "Description", "What it does" }, "the header of the table in " .. tbl.section)
        sections[#sections + 1] = tbl.section
        for _, row in ipairs(tbl.rows) do
          local key = row[1]:match("^`([^`]+)`$")
          t.ok(key ~= nil and #row == 3, "a row is one key in backticks, then two cells: " .. table.concat(row, " | "))
          rows[#rows + 1] = { key = key, desc = row[2] }
        end
      end
    end
    t.eq(sections, SECTIONS, "the sections with a Description table")
    local have = {}
    for _, k in ipairs(set_keys(t)) do
      have[k.lhs .. "\n" .. k.desc] = true
    end
    local missing = {}
    for _, row in ipairs(rows) do
      if not have[card_key(row.key) .. "\n" .. row.desc] then
        missing[#missing + 1] = row.key .. ": " .. row.desc
      end
    end
    t.eq(missing, {}, "keys on the card that no key matches, with that description")
  end,

  ["the menus table is which-key's Space menus, both ways"] = function(t)
    local card = {}
    for _, row in ipairs(rows_of(t, read(t), "The menus", { "Keys", "Menu", "For" })) do
      local key = row[1]:match("^`([^`]+)`$")
      t.ok(key ~= nil, "a menu row starts with one key in backticks: " .. row[1])
      card[card_key(key)] = row[2]
    end
    local spec = Plugin.values(Config.plugins["which-key.nvim"], "opts", false).spec
    local menus = {}
    for lhs, name in pairs(groups(spec)) do
      local rest = norm(lhs):match("^<Space>(.+)$")
      if rest and (vim.fn.strchars(rest) == 1 or rest:match("^<[^>]+>$")) then
        menus[norm(lhs)] = name
      end
    end
    t.ok(next(menus) ~= nil, "which-key has groups after Space")
    t.eq(card, menus, "the menus on the card, against which-key's groups after Space")
  end,

  ["the keys in Neovim's own table are still Neovim's own"] = function(t)
    local own = {}
    for _, row in ipairs(rows_of(t, read(t), "Neovim's own keys", { "Key", "What it does" })) do
      for key in row[1]:gmatch("`([^`]+)`") do
        own[card_key(key)] = key
      end
    end
    local set = {}
    for _, k in ipairs(plugin_keys()) do
      if normal(k.mode) then
        set[#set + 1] = { k.lhs, "the spec for " .. k.plugin }
      end
    end
    for _, k in ipairs(require("ach.testhook").keymaps) do
      if normal(k.mode) then
        set[#set + 1] = { k.lhs, k.where }
      end
    end
    for _, k in ipairs(require("ach.lsp").keys) do
      if normal(k.mode) then
        set[#set + 1] = { k[1], "ach.lsp.keys" }
      end
    end
    local taken = {}
    for _, s in ipairs(set) do
      local key = own[norm(s[1])]
      if key then
        taken[#taken + 1] = ("%s is set in normal mode by %s"):format(key, s[2])
      end
    end
    table.sort(taken)
    t.eq(taken, {}, "Neovim's own keys this configuration sets")
  end,

  ["the card names Ghostty's keys, and the settings give none a new job"] = function(t)
    local _, lines = read(t)
    local named, inside = {}, false
    for _, line in ipairs(lines) do
      if line:match("^## ") then
        inside = line == "## Ghostty's keys"
      end
      if inside then
        for key in line:gmatch("`([^`]+)`") do
          named[key] = true
        end
      end
    end
    local missing = {}
    for _, pair in ipairs(GHOSTTY) do
      if not named[pair[1]] then
        missing[#missing + 1] = pair[1]
      end
    end
    t.eq(missing, {}, "Ghostty keys the section Ghostty's keys leaves out")
    local ok, conf = pcall(vim.fn.readfile, t.root .. "/ghostty/config.ghostty")
    t.ok(ok and #conf > 0, "ghostty/config.ghostty exists and is not empty")
    local rebound = {}
    for _, line in ipairs(conf) do
      local value = line:match("^%s*keybind%s*=%s*(.-)%s*$")
      if value then
        local v = value:lower()
        if v:find("super+", 1, true) or v:find("cmd+", 1, true) or v:find("command+", 1, true) then
          rebound[#rebound + 1] = line
        end
      end
    end
    t.eq(rebound, {}, "keybind lines in ghostty/config.ghostty that change a Command key")
  end,

  ["Ghostty's defaults still give the Command keys the jobs the card names"] = function(t)
    read(t)
    local bin = ghostty()
    if not bin then
      t.skip("Ghostty is not installed: brew install --cask ghostty")
    end
    local r = vim.system({ bin, "+list-keybinds", "--default", "--plain" }, { text = true }):wait(30000)
    t.eq(r.code, 0, "ghostty +list-keybinds, which printed: " .. (r.stderr or ""))
    local missing = {}
    for _, pair in ipairs(GHOSTTY) do
      local found = false
      for line in (r.stdout or ""):gmatch("[^\n]+") do
        if line:find("super+", 1, true) and line:find(pair[2], 1, true) then
          found = true
          break
        end
      end
      if not found then
        missing[#missing + 1] = pair[1] .. " (" .. pair[2]:sub(2) .. ")"
      end
    end
    t.eq(missing, {}, "keys whose action no Command key has among Ghostty's defaults")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_key_card`
Expected: `0 passed, 5 failed, 0 need a person, 0 skipped`, exit 1. Every test reads the card before anything else, so all five fail on `docs/key-card.md exists`, whether or not Ghostty is installed.

- [ ] **Write the card**

The card is prose and tables, written for someone who has never used Neovim. The Description column holds each key's description exactly as the configuration sets it, since that is the text `Space s k` searches and the test compares; the column after it says in plain words what the key does. Where the configuration has a pair of keys, such as `Shift-h` and `Shift-l`, or a family, such as `Ctrl-h` to `Ctrl-l`, the card gives one key a row and names the others in its sentence, so the page stays one page. The Ghostty table is the Ghostty task's own, with one sentence changed to name the file it opens.

`docs/key-card.md`:

```markdown
# ACH-NEOVIM Key Card

The keys worth having at hand, on one page. `scripts/check` reads this card and checks every key on it against the keys Neovim actually has, so a key renamed or removed fails the check until the card is changed to match.

## The idea

Neovim has modes. It starts in normal mode, where every letter is a command rather than text: `j` moves down a line and `d d` deletes one. Press `i` and you are in insert mode, where letters type as in any other editor, and `Esc` brings you back. Almost every key on this card is pressed in normal mode, so when in doubt, press `Esc` first.

Thirteen menus hang off the Space bar, one per kind of work. Press `Space`, pause, and which-key draws every key that can follow, each with an icon and a description. You do not memorise keys: you pick a menu, then read the list.

`Space f f` means Space, then f, then f, one after another. `Ctrl-h` means holding Ctrl while pressing h, and `Shift-h` is a capital H. `Alt` is the left Option key, which Ghostty sends as Alt, while the right Option key still types accents. `Backslash` is the `\` key.

The Description column is each key's description word for word, the text `Space s k` searches and which-key shows. One exception: which-key shows a key whose description begins with Toggle as Enable or Disable instead, naming what a press will do now.

## Neovim's own keys

These belong to Neovim, and this configuration leaves every one of them as it is. They are the core of every Vim tutorial, and `nvim --clean +Tutor`, which opens Neovim's own lessons without this configuration, teaches them in about half an hour.

| Key | What it does |
| --- | --- |
| `i` | Starts typing before the cursor |
| `a` | Starts typing after the cursor |
| `o` | Opens a new line below and starts typing on it |
| `v` `V` | Starts selecting characters, or whole lines |
| `u` | Undoes the last change |
| `Ctrl-r` | Redoes what `u` undid |
| `x` | Deletes the character under the cursor |
| `d d` | Cuts the line |
| `y y` | Copies the line |
| `p` | Pastes after the cursor |
| `.` | Repeats the last change |
| `c i w` | Deletes the word under the cursor and starts typing in its place |
| `w` `b` | Moves to the next word, or back to the one before |
| `0` `$` | Moves to the start of the line, or to its end |
| `g g` `G` | Moves to the top of the file, or to the bottom |
| `/` | Searches forward: type the text and press Enter, then `n` for the next match and `N` for the one before |
| `Ctrl-o` | Goes back to where the cursor was before the last jump |

Commands start with a colon and end with Enter: `:w` saves, `:q` closes the window, and `:wq` does both.

## The menus

| Keys | Menu | For |
| --- | --- | --- |
| `Space Tab` | tabs | a new tab, the next one, closing them |
| `Space a` | claude | Claude Code beside the file |
| `Space b` | buffer | the open files: switching, closing |
| `Space c` | code | the language server, formatting, Mason, building a document |
| `Space d` | debug | breakpoints, stepping, the debugger's panes |
| `Space f` | file/find | opening, recent files, new files, the file tree, a terminal |
| `Space g` | git | Lazygit, Neogit, changes, history, GitHub |
| `Space m` | multicursor | a cursor at each match, to edit them all at once |
| `Space q` | quit/session | quitting, and bringing back the last session |
| `Space s` | search | text, help, keys, symbols, replacing |
| `Space u` | toggles | switching a setting off and on |
| `Space w` | windows | splitting, moving, closing |
| `Space x` | diagnostics/quickfix | errors and warnings, lists, TODO comments |

Four more prefixes work the same way without Space. `[` and `]` move to the previous and the next of something, a diagnostic after `d`, a changed block after `h`, an open file after `b`; `g` goes to things, and `z` folds. `Space ?` lists the keys that belong to the file in front of you.

## Files and buffers

| Key | Description | What it does |
| --- | --- | --- |
| `Space Space` | Find Files (Root Dir) | Finds a file in this project by typing part of its name |
| `Space f r` | Recent | Lists the files opened lately |
| `Space f n` | New File | Opens an empty file with no name yet; `:w notes.md` saves it as notes.md |
| `Space e` | File Tree (project) | Shows the project's files as a tree beside the text |
| `Space f o` | Open Folder as Text (oil) | Opens this file's folder as a page of text, where changing a name and saving renames the file |
| `Space ,` | Buffers | Lists the open files, to switch to one |
| `Shift-h` | Prev Buffer | Moves to the open file before this one |
| `Shift-l` | Next Buffer | Moves to the open file after this one |
| `Space b d` | Delete Buffer | Closes this file and keeps the window |
| `Ctrl-s` | Save File | Saves the file, in insert mode as well |
| `Space q s` | Restore Session for This Folder | Reopens the files that were open when Neovim last closed in this folder |
| `Space q q` | Quit All | Quits Neovim |

A buffer is a file Neovim has open, and a window is a view onto one, so closing a window leaves the file open and `Space ,` still finds it. Root Dir is the project's top folder, the nearest one above the file that holds `.git`, or else the folder Neovim was started in. A key marked cwd uses the folder Neovim was started in, whatever the file.

In any list these keys open, type to narrow it, `Ctrl-j` and `Ctrl-k` move down and up, and Enter opens the choice. `Esc` once stops typing, and a second `Esc` closes the list.

## Search and moving

| Key | Description | What it does |
| --- | --- | --- |
| `Space /` | Grep (Root Dir) | Searches the text of every file in the project |
| `Space s b` | Buffer Lines | Searches the lines of this file |
| `Space s r` | Search and Replace | Finds text across the project and replaces it, showing each change first |
| `Space s h` | Help Pages | Searches Neovim's own help |
| `Space s k` | Keymaps | Searches every key by its description |
| `Space s R` | Resume | Reopens the last search where it was left |
| `s` | Flash Jump | Type a character or two from where you want to go, then the letter that appears there |
| `S` | Flash Select by Syntax | Selects a whole piece of code, such as a function, by the letter shown on it |

## Code

These work once a language server is running for the file, which happens on its own for every language the configuration knows, except the last three, which belong to particular files.

| Key | Description | What it does |
| --- | --- | --- |
| `g d` | Goto Definition | Jumps to where the name under the cursor is defined; `Ctrl-o` comes back |
| `g r r` | References | Lists every place the name under the cursor is used |
| `K` | Hover | Shows the documentation for the name under the cursor |
| `Space c a` | Code Action | Lists the fixes the language server offers here |
| `Space c r` | Rename | Renames the name under the cursor everywhere it is used |
| `Space c f` | Format | Formats the file, or the selected lines |
| `Space c d` | Line Diagnostics | Shows the whole error or warning on this line |
| `] d` | Next Diagnostic | Moves to the next error or warning |
| `Space x x` | Problems (Trouble) | Lists the errors and warnings in a panel at the bottom |
| `Space c m` | Mason | Shows the language tools Mason has installed |
| `Space c x` | x86 Manual | Opens Intel's manual at the instruction under the cursor |
| `Space c b` | Build Document | In a LaTeX file, builds the PDF |
| `Space c p` | Markdown Preview | In a Markdown file, shows it in the browser, kept in step as you type; pressed again, stops |

In a LaTeX file, `Space ?` also lists VimTeX's own keys, which all begin with Backslash then l.

## Git

| Key | Description | What it does |
| --- | --- | --- |
| `Space g g` | Lazygit (Root Dir) | Opens Lazygit, a whole git program in a window, on this project |
| `Space g n` | Neogit (Root Dir) | Opens Neogit, git's status page inside Neovim, where changes are staged and committed |
| `] h` | Next Hunk | Moves to the next changed block in this file |
| `Space g h p` | Preview Hunk Inline | Shows the block under the cursor as it was before the change |
| `Space g h s` | Stage or Unstage Hunk | Stages the changed block under the cursor, or unstages it |
| `Space g h r` | Reset Hunk | Throws away the change in the block under the cursor |
| `Space g D` | Diff View (Root Dir) | Shows every uncommitted change, file by file |
| `Space u b` | Toggle Git Blame Line | Shows who last changed the line under the cursor, and when, at its end |
| `Space g B` | Git Browse (open) | Opens this file on GitHub in the browser |
| `Space g p` | GitHub Pull Requests | Lists the repository's pull requests |

A hunk is one block of lines changed together, and the bars in the left margin mark each one.

## Claude Code

| Key | Description | What it does |
| --- | --- | --- |
| `Space a c` | Toggle Claude | Opens Claude Code in a panel beside the file, or hides it |
| `Space a b` | Add Buffer to Claude | Hands this file to Claude |
| `Space a s` | Send to Claude | With lines selected, hands Claude just those lines |
| `Space a a` | Accept Diff | Takes the change Claude proposed |
| `Space a d` | Deny Diff | Turns that change down |
| `Space a r` | Resume Claude | Picks an earlier conversation to carry on |

## Debugging

| Key | Description | What it does |
| --- | --- | --- |
| `Space d b` | Toggle Breakpoint | Sets a stop on this line, or clears it |
| `Space d c` | Start or Continue | Starts the program under the debugger, or runs on to the next stop |
| `Space d O` | Step Over | Runs this line and stops on the next |
| `Space d i` | Step Into | Goes into the function this line calls |
| `Space d o` | Step Out | Runs to the end of this function and stops in the one that called it |
| `Space d t` | Stop Debugging | Ends the run |
| `Space d u` | Debug Interface | Shows or hides the panes of variables, calls and breakpoints |

## Windows and toggles

| Key | Description | What it does |
| --- | --- | --- |
| `Ctrl-h` | Go to Left Window | Moves to the window on the left; `Ctrl-j`, `Ctrl-k` and `Ctrl-l` go down, up and right |
| `Space -` | Split Window Below | Splits the window, with the new one below |
| `Space \|` | Split Window Right | Splits the window, with the new one to the right |
| `Space w d` | Delete Window | Closes this window |
| `Space u f` | Toggle Format on Save (all buffers) | Stops formatting files as they are saved, or starts again |
| `Space u F` | Toggle Format on Save (this buffer) | Does the same for this file alone |
| `Space u w` | Toggle Wrap | Wraps long lines at the window's edge, or stops |
| `Space u s` | Toggle Spelling | Underlines misspelt words, or stops |
| `Space u z` | Toggle Zen Mode | Hides everything but the text, or brings it back |
| `Space u u` | Undo Tree | Shows every earlier state of the file, to return to any of them |

## Outside the menus

| Key | Description | What it does |
| --- | --- | --- |
| `Esc` | Escape and Clear hlsearch | Leaves insert mode, and clears the highlight a search leaves behind |
| `Ctrl-/` | Terminal (Root Dir) | Opens a terminal at the project's top folder; pressed in the terminal, hides it |
| `Alt-j` | Move Down | Moves the line, or the selected lines, down one; `Alt-k` moves them up |
| `Ctrl-Space` | Grow Selection by Syntax | Selects the code under the cursor, a larger piece at each press |
| `Alt-Down` | Add Cursor Below | Adds a cursor on the line below, so typing goes to both; `Esc` removes the extra ones |
| `Space n` | Notification History | Shows the messages that flashed past |
| `Space N` | News | Opens the news reader |
| `Space l` | Lazy | Opens Lazy, which lists the plugins |
| `Space ?` | Buffer Keymaps (which-key) | Lists the keys that belong to this file |

## Ghostty's keys

Ghostty, the terminal Neovim runs in, keeps its own keys, and none of them reaches Neovim. Command is the ⌘ key.

| Key | What it does |
| --- | --- |
| `Command-T` | Opens a new tab |
| `Command-N` | Opens a new window |
| `Command-D` | Splits the current pane, with the new one to the right |
| `Command-Shift-D` | Splits the current pane, with the new one below |
| `Command-[` and `Command-]` | Moves to the previous or the next split |
| `Command-Option` with an arrow | Moves to the split in that direction |
| `Command-Shift-Enter` | Zooms the current split to fill the window, and back |
| `Command-Shift-[` and `Command-Shift-]` | Moves to the previous or the next tab |
| `Command-1` to `Command-8` | Moves to that tab; `Command-9` moves to the last |
| `Command-W` | Closes the current split, or the tab when it holds one pane, asking first while a program such as Neovim is running in it |
| `Command-=` and `Command-minus` | Makes the text bigger or smaller; `Command-0` returns it to 15 points |
| `Command-,` | Opens Ghostty's settings file for editing |
| `Command-Shift-,` | Reads the settings file again, so a change shows without restarting |

## What catches people out

Typing in normal mode runs commands. If text vanishes or jumps about as you type, you were in normal mode: press `Esc`, then `u` until the file is as it was, then `i` and type again.

`s` is Flash Jump here. Older Vim tutorials teach it as deleting a character and typing in its place, which `c l` still does.

Some keys belong to a file rather than to Neovim. The language server's keys, `g d`, `K` and the rest of the Code table, appear once the file's server is running; `] h` and the `Space g h` keys appear once git tracks the file; `Space c b` is there only in LaTeX files and `Space c p` only in Markdown. `Space ?` lists what the file in front of you has.

Files are formatted as they are saved. If a save rearranges more than you wanted, `u` takes the formatting back, and `Space u F` stops it for that file alone.

A running Neovim keeps the configuration it started with. After changing a file under `lua/`, quit with `Space q q` and start Neovim again, and `Space q s` brings the files back.

After Homebrew updates Neovim, the first start says the fast check is running in the background, and about a minute later says whether the configuration still passes. The editor works as usual meanwhile. A failure names the folder to run `scripts/check` in, which shows the test that failed, and the check runs again at every start until it passes.

## What still needs a person

Run `gh auth login` once, so `Space g p` and the other GitHub keys can reach GitHub. `Space c x` needs Intel's manual, which the Mac's setup downloads once you say yes. Anything else `scripts/check --full` reports as needing a person comes with the line that does it.
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: every test passes, exit 0. Once the Mac's setup has installed Ghostty, `test_key_card` reports five passed. Before that, it reports four passed and one skipped, the one that runs Ghostty's command line, naming `brew install --cask ghostty`. No key, program or plugin is added, so `lua/ach/icons.lua`, `lua/ach/need.lua` and `lazy-lock.json` do not change.

- [ ] **Format the Lua**

Run: `stylua lua tests`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add docs/key-card.md tests/test_key_card.lua
git commit --only docs/key-card.md tests/test_key_card.lua -m "docs(keys): add the one-page key card, checked against the keys Neovim has"
```

---

### Task: The Documentation Post

**Files:**
- Create: `lua/ach/docs.lua`
- Create: `scripts/docs`, `scripts/docs.lua`
- Create: `tests/helpers/keymaps.lua`
- Create: `docs/site/getting-started.md`, `docs/site/installation.md`, `docs/site/news.md`, `docs/site/configuration.md`
- Create: `docs/site/keymaps.json`, written by `scripts/check --keymaps`
- Modify: `scripts/check`
- Test: `tests/test_docs.lua`

**Interfaces:**
- Consumes: `lazy-lock.json`, which maps each plugin's name to `{ branch, commit }`; the spec files `lua/ach/plugins/*.lua`, read as text and never run; `lua/ach/languages.lua`, whose `M.languages` maps a language's name to an entry, of which this task reads `ft`, `ts`, `lsp`, `fmt`, `lint`, `harper`, `manual` and `managed` and nothing else; `M.settings` in `lua/ach/servers.lua`, read as text; the eight tables with a Description column in `docs/key-card.md`; `tests/helpers/child.lua`'s `run(t, body, opts)`; the five places the key card test reads keys from, which are `vim.api.nvim_get_keymap`, lazy.nvim's `require("lazy.core.config").plugins` with `require("lazy.core.plugin").values` and `require("lazy.core.handler.keys").resolve`, `require("ach.testhook").keymaps`, `require("ach.lsp").keys`, and the keys `require("ach.git").on_attach(buf)`, `require("ach.latex").attach(buf)` and `require("ach.preview").attach(buf)` set on one buffer; in the tests, `require("ach.dap")` (`lldb_filetypes`, `js_filetypes`); and the Lua parser that ships inside Neovim, through `vim.treesitter.get_string_parser`.
- Produces:
  - `scripts/docs --out <file> [--date YYYY-MM-DD]`, run from anywhere: it changes to the repository root, writes one complete MDX post to `<file>`, prints `Wrote <file>: <n> lines.` and exits 0. A relative `<file>` is taken from the repository root, and its folder must already exist. It exits 1, writing nothing, on a usage error, a `--date` not written `YYYY-MM-DD`, a plugin in `lazy-lock.json` with no entry in `lua/ach/docs.lua` or the other way round, or any other error, which it prints; and 2 when Neovim is not installed. Without `--date`, the date is HEAD's commit date, `git log -1 --format=%cs`.
  - `require("ach.docs")`: `post: { title: string, summary: string, tags: string[] }`; `intro: { note: string[], keymaps: string[], plugins: string[], languages: string[] }`, each a list of Markdown lines; `categories: string[]`; `plugins: table<string, { category: string, desc: string }>`, keyed by the name in `lazy-lock.json`; `debuggers: table<string, string>`, keyed by language; `key_sections: { [1]: string, [2]: string }[]`, each a key's start as the card spells it and the card section it falls in.
  - `scripts/docs.lua`, loaded with `dofile` as a module: `escape(text: string): string`, `cell(text: string): string`, `code(text: string): string`, `fence(text: string): string`, `tabs(tabs: { [1]: string, [2]: string }[]): string[]`, `snippet(lines: string[], node: TSNode, comments: boolean): string`, `specs(root: string, lock: table<string, table>): table<string, { repo: string, fragments: { file: string, spec: string, opts: string? }[], parents: { file: string, parent: string, text: string }[] }>`, `spell(lhs: string): string`, `card(root: string): table<string, { spelling: string, section: string, rank: integer }>, string[]`, `section(card, lhs: string, spelling: string, docs): string`, `keymaps_section(root: string, docs): string[]`, `plugins_section(root: string, docs): string[]`, `languages_section(root: string, docs): string[]`, `front_matter(post, date: string): string[]`, `render(root: string, date: string): string` and `main(args: string[]): integer`.
  - `tests/helpers/keymaps.lua`: `FILE: string`, `MODES: string[]`, `collect(): { [1]: string, [2]: string, [3]: string }[]`, each key's canonical spelling, its mode letters and its description, `write(path: string, keys)`, `read(root: string)` and `snapshot(t)`; run as `nvim -l tests/helpers/keymaps.lua ROOT OUT`, it writes `OUT`.
  - `scripts/check --keymaps`, which runs no tests and rewrites `docs/site/keymaps.json`, exiting 0 when it is written and 1 when it is not.

The documentation post is one long page on the owner's website, at `/blog/ach-neovim`, that documents ACH-NEOVIM the way lazyvim.org documents LazyVim: how to install it, every key, every plugin with the code that sets it up, and every language. It is not written by hand. `scripts/docs` writes it from the configuration's own source each time it runs, so a plugin added, a key renamed or a language dropped shows in the post the next time the website is built, and the post cannot drift from the configuration. The website runs `scripts/docs --out` with the path of its own file for that page, and nothing in this repository changes when it does.

The post has seven sections, each under a `##` heading, in this order: Getting Started, Installation, What's New, Keymaps, Configuration, Plugins and Languages. Four of them are prose. They are written by hand, in the first person, as the owner talking to the reader, in four Markdown files in `docs/site/`, and the generator copies each one in under its heading. Those pages tell the reader plainly what to do and what not to do, with a tip box for each thing to do and a warning box for each thing not to do. The other three sections are made from the source.

The website builds its posts from MDX. MDX is Markdown that may also hold components, pieces of the website's page written as tags in angle brackets, such as `<Tabs>`. That power has a cost: MDX reads a `<` in ordinary text as the start of a tag and a `{` as the start of a piece of JavaScript, so a plugin description that says "turns {a} into <b>" stops the website's build with an error. So the post uses Markdown and exactly two components, `<Tabs>` with `<Tab label="...">` inside it and `<Callout type="note">`, `"tip"` or `"warning"`, each tag on a line of its own, and everything else is escaped. A backslash before a character tells MDX to show that character as typed, so `{` is written `\{` and `<` is written `\<`. Text between backticks, a code span, is already shown exactly as typed, so `escape` leaves code spans alone. It also escapes `*`, `_`, `[`, `]` and the backslash itself, which mark emphasis, links and escapes in Markdown, so a description shows as typed. And it escapes `$`, because the website runs remark-math, which reads the text between two `$` signs as a mathematical formula: a sentence such as "set $HOME and $PATH" would come out with "HOME and" set as maths, so every `$` outside code is written `\$`. A table cell has one more character to escape, `|`, which would otherwise end the cell, and `cell` escapes it even inside a code span, which is how a Markdown table writes the key `Space |`.

A tab holds one fenced code block, code between two lines of backticks, with a blank line on each side, because MDX reads Markdown inside a component only when blank lines set it apart. The fence is one backtick longer than the longest run of backticks in the code, and at least three, so a backtick inside a comment cannot end the block early.

A plugin spec is the Lua table lazy.nvim reads to install and load a plugin: its repository first, such as `"folke/flash.nvim"`, then fields such as `opts`, the settings handed to the plugin's setup function, `keys`, and `event`, which says when it loads. The Plugins section shows each spec as it is written, comments included, so the generator needs the spec's text, not its value. Running a spec file would give values, and it would also need the plugins themselves, since the files start by requiring modules such as `ach.icons`. So the generator reads them with Tree-sitter instead. Tree-sitter is the parser Neovim uses for highlighting. It reads source text into a syntax tree, a nested structure of nodes, each covering a stretch of the text and labelled with what it is, such as `table_constructor` for a `{ ... }` table or `field` for one entry in it. Neovim carries a Lua parser of its own, so this works under `nvim --clean`, which starts Neovim with none of this configuration.

A query is a small pattern matched against a syntax tree. `(field !name value: (string) @repo)` matches every table entry that has no name and holds nothing but a string, and a string shaped `owner/name` whose name is in `lazy-lock.json` is a plugin. When that entry is the first in its table, the table is a spec: the generator copies the spec's text, and the text of its `opts` field, each with the comment lines directly above it. When the table is a `dependencies` list, the plugin is installed for the sake of another, and the generator copies that `dependencies` line. snacks.nvim is set up in pieces, one in each file that needs a part of it, so it is shown as several specs, each under the file it lives in. A plugin without `opts` has nothing for an Options tab, so its `<Tabs>` holds the Full Spec tab alone.

The source does not say what a plugin is for, so `lua/ach/docs.lua` does: a category and one sentence for every plugin in the lock. The categories are LazyVim's nine, Coding, Colorscheme, Editor, Formatting, Linting, LSP, TreeSitter, UI and Util, followed by six of this configuration's own: Debugging, Language Plugins, Git, Claude Code, LaTeX and Markdown. Within a category, plugins are sorted by name without regard to case. The generator refuses to write a post when a plugin in the lock has no entry or an entry names a plugin the lock does not have, and it lists every such plugin at once, so a plugin can never be added without its sentence.

`lua/ach/languages.lua` is plain data, so the generator loads it to read each entry's fields, and also parses it to copy each entry's text into the Entry tab. Each language gets a `###` heading and a table naming its file types, parsers, servers, formatters, linters, debugger and whether Harper, the grammar checker, reads it, with "none" where a language has nothing. A language marked `manual` is never formatted on save, and its Formatters row says so. Server settings come from `M.settings` in `lua/ach/servers.lua`, which is parsed and never run, since it asks Neovim for its data folder as it loads; a language whose servers have settings gets an Options tab beside its Entry tab, and one without gets the Entry tab alone. Which debugger serves a language is not in the language table: it is spread over nvim-dap's setup and the plugins that bring their own. So `lua/ach/docs.lua` names it, and a test checks the names against the language table and against the file types `require("ach.dap")` debugs.

Keys are different. A key exists only once the configuration has run: the plugin specs declare some, files under `lua/ach/` set others as they load, and a few are set on each buffer as it opens. The generator never starts the configuration, so it reads keys from a file, `docs/site/keymaps.json`, which `scripts/check --keymaps` writes. That starts a second Neovim with the configuration, reads every key from the same places the key card test reads them, and writes each key once, in Neovim's canonical spelling, with its description and the letters of the modes it works in. Neovim's own table of keymaps also holds the keys Neovim sets for itself, so from that table only keys that start with Space are taken; every other key this configuration sets is in one of the other four places. A test reads the keys again the same way and fails when they differ from the file, saying to run `scripts/check --keymaps`, so the file is never stale on a commit that passes.

The Keymaps section groups the keys as the key card does. A key the card lists goes under the card's section for it, before the rest and in the card's order, and is spelled as the card spells it. Any other key is spelled by `spell`, `Alt-j` for `<M-j>` and `Space g g` for `<Space>gg`, and goes where `M.key_sections` sends it by the longest start of its spelling that matches, so a key under `Space g` lands under Git; a key no rule matches goes under "Outside the menus". Each row gives the key, its description and its modes. The icons which-key shows beside each key are left out, because they come from the JetBrains Mono Nerd Font, which the website does not load, so each would draw as an empty box, and the section's introduction says so.

Running the generator twice on the same commit with the same date writes the same bytes. Every list is sorted before it is written, since Lua visits a table's keys in no fixed order, and the date in the front matter comes from `--date` or, without it, from HEAD's commit date, never from the day the generator runs. The front matter is the block between two `---` lines at the top of the post, with the keys every post on the website uses: `title`, `date`, `summary`, `tags` and `draft: false`.

Fifteen tests hold the generator to all of this. The first eight read the post written for this repository: the seven sections in order; every plugin in the lock with an entry in `lua/ach/docs.lua`, both ways, and every plugin the post lists sitting under a category; every language with its subsection; every debugger belonging to a language; the key file matching the keys the configuration sets now; no bare `<`, `>`, `{`, `}` or `$` outside code but the components' own tags, which also holds the four hand-written pages to the rule, since they are copied in as written; the front matter; and a short list of words kept out of the post. Those words are stored in ROT13, which shifts each letter thirteen places along the alphabet, so the test file does not spell them out either. The last seven run the generator on a fixture, a small repository built in a temporary folder with three plugins, one language, two keys, a description holding `{`, `<` and `|` and another holding two bare `$` and one inside a code span, where the exact MDX for each input is known: the escaping, the `$` escaping, the tabs, a plugin that is only a dependency together with a language's table and tabs, two runs giving the same bytes, the default date and `--date`, and a plugin with no entry stopping the post.

- [ ] **Write the failing tests**

`tests/test_docs.lua`:

```lua
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

local function lines_of(text)
  return vim.split(text, "\n", { plain = true })
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
      out[#out + 1] = (h3:gsub("\\(.)", "%1"))
    end
  end
  return out
end

-- A repository in a temporary folder with this repository's scripts/docs and
-- the files above, committed once on 4 March 2026.
local function fixture(t, lock)
  local dir = t.tmpdir() .. "/repo"
  for path, text in pairs(FILES) do
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
      under = inside and p[2]:match("^### (.+)$") or under
      local name = inside and p[2]:match("^#### %[(.-)%]%(")
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
    local alpha = find(lines, "#### [alpha.nvim](https://github.com/someone/alpha.nvim)")
    local beta = find(lines, "#### [beta.nvim](https://github.com/someone/beta.nvim)")
    local gamma = find(lines, "#### [gamma.nvim](https://github.com/someone/gamma.nvim)")
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

  ["a dependency shows the line that brings it in, and a language its table and tabs"] = function(t)
    local lines = lines_of(generate(t, fixture(t)))
    local gamma = find(lines, "#### [gamma.nvim](https://github.com/someone/gamma.nvim)")
    t.ok(gamma ~= nil, "gamma is in the post")
    t.eq(vim.list_slice(lines, gamma + 4, gamma + 11), {
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
}
```

`prose` drops the front matter and every fenced block, then takes code spans out of what is left, so the escaping test and the heading tests see exactly the text MDX parses as Markdown. The fixture's `scripts/docs` is a copy of this repository's, so it changes into the fixture's folder and reads the fixture's files; `nvim --clean` keeps `~/.config/nvim` off Neovim's search path, so the fixture's `lua/ach/docs.lua` is the only one it can load.

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_docs`
Expected: `0 passed, 15 failed, 0 need a person, 0 skipped`, exit 1. The tests on the real post fail on `scripts/docs`, `module 'ach.docs' not found` or the missing `tests/helpers/keymaps.lua`, and the seven on the fixture fail copying `scripts/docs` into it.

- [ ] **Write the post's data**

`lua/ach/docs.lua`:

```lua
-- What the documentation post says that the source cannot: its title and
-- summary, the short introductions above the generated sections, the category
-- and one-sentence description of every plugin in lazy-lock.json, each
-- language's debugger, and which key card section a key the card does not
-- name falls in. scripts/docs reads it, and tests/test_docs.lua fails while a
-- plugin in lazy-lock.json has no entry here. It is plain data, so it loads
-- without the configuration.
local M = {}

M.post = {
  title = "ACH-NEOVIM: My Neovim Configuration for macOS",
  summary = "How I set up Neovim on my Mac: installing it, every key, every plugin with its code, and every language,"
    .. " written from the configuration's own source.",
  tags = { "neovim", "lua", "editor", "macos" },
}

-- Markdown lines, copied into the post as they are. They hold no < > { },
-- which MDX would read as code.
M.intro = {
  note = {
    "I generate this page with `scripts/docs`, from the configuration's own source: the plugin specs, the language"
      .. " table, the keys the configuration sets, and four pages I write by hand in `docs/site/`. Edit the source,"
      .. " not this page.",
  },
  keymaps = {
    "Every key this configuration sets, with the description the menus show for it and the modes it works in,"
      .. " grouped the way the key card in `docs/key-card.md` groups them. A key is written the way it is pressed:"
      .. " `Space f f` is Space, then f, then f, and `Ctrl-h` is h pressed while Ctrl is held.",
    "",
    "The Mode column uses Neovim's one-letter names. n is normal mode, where keys move and edit. x is visual mode,"
      .. " after selecting text with `v`. s is select mode, which snippets use for the parts to fill in. o is"
      .. " operator-pending mode, after an operator such as `d` and before the motion that says what it acts on."
      .. " i is insert mode, for typing. c is the command line, after `:`. t is a terminal window.",
    "",
    "Inside Neovim each key also shows an icon. This page leaves the icons out, because they come from the"
      .. " JetBrains Mono Nerd Font and this website does not load that font, so each would draw as an empty box."
      .. " Keys a plugin sets only inside its own window, and text objects such as `i (` in `d i (`, are not listed"
      .. " here. Inside Neovim, `Space s k` searches every key, those included.",
  },
  plugins = {
    "Every plugin in `lazy-lock.json`, grouped by what it does. Each name links to the plugin's repository. The"
      .. " Options tab shows `opts`, the settings lazy.nvim hands to the plugin, and the Full Spec tab shows the"
      .. " whole spec: where the plugin comes from, when it loads, its keys and its options. Either one can be"
      .. " copied into a file in `lua/ach/plugins/`.",
    "",
    "Some plugins are set up in pieces, one in each file that needs a part of them, and each piece is shown with"
      .. " the file it lives in. A plugin that only comes in for another plugin's sake shows the line that brings it"
      .. " in.",
  },
  languages = {
    "One subsection for each entry in `lua/ach/languages.lua`. Nothing here is installed until a file of that"
      .. " language is opened. Then its Tree-sitter parser, its language servers, its formatters and its linters"
      .. " install in the background, without asking, and switch on when they are ready. A compiler or runtime"
      .. " that only Homebrew provides is asked about first, once, in one line that names it and its rough size.",
    "",
    "Each table names the parts: the file types the entry covers, the parsers that read its syntax, the language"
      .. " servers that check the code as it is typed, the formatters that tidy it on save, the linters that report"
      .. " problems, the debugger, and whether Harper, a grammar checker, reads it. The Entry tab is the language's"
      .. " entry in `lua/ach/languages.lua`. The Options tab, where there is one, holds its servers' settings from"
      .. " `lua/ach/servers.lua`.",
  },
}

-- LazyVim's nine categories, then this configuration's own.
M.categories = {
  "Coding",
  "Colorscheme",
  "Editor",
  "Formatting",
  "Linting",
  "LSP",
  "TreeSitter",
  "UI",
  "Util",
  "Debugging",
  "Language Plugins",
  "Git",
  "Claude Code",
  "LaTeX",
  "Markdown",
}

-- Every plugin in lazy-lock.json, by the name the lock gives it.
M.plugins = {
  ["snacks.nvim"] = {
    category = "Util",
    desc = "Many small tools in one plugin. Here it gives the file picker, the dashboard, notifications, toggles,"
      .. " the terminal, the file tree, indent guides, the git keys and the image previews.",
  },
  ["lazy.nvim"] = {
    category = "Util",
    desc = "The plugin manager. It installs each plugin at the commit `lazy-lock.json` names, and loads each one"
      .. " when it is first needed.",
  },
  ["plenary.nvim"] = {
    category = "Util",
    desc = "A library of Lua functions other plugins build on; octo.nvim needs it.",
  },
  ["persistence.nvim"] = {
    category = "Util",
    desc = "Saves which files were open in each folder, so `Space q s` brings them back.",
  },
  ["lazydev.nvim"] = {
    category = "Coding",
    desc = "Tells the Lua language server about Neovim's own Lua functions and the installed plugins, for"
      .. " completion and checking in these configuration files.",
  },
  ["blink.cmp"] = {
    category = "Coding",
    desc = "The completion menu, offering words from the language server, snippets, file paths and the open buffer.",
  },
  ["friendly-snippets"] = { category = "Coding", desc = "A collection of snippets for many languages." },
  ["mini.pairs"] = { category = "Coding", desc = "Types the closing bracket or quote when the opening one is typed." },
  ["mini.ai"] = {
    category = "Coding",
    desc = "Extends the `a` and `i` text objects, so `d i (` and its kind reach further, such as into the next pair.",
  },
  ["ts-comments.nvim"] = {
    category = "Coding",
    desc = "Makes `g c` use the right comment marker in a file that mixes languages.",
  },
  ["which-key.nvim"] = {
    category = "Editor",
    desc = "Shows the keys that can follow the ones already pressed, each with a description and an icon.",
  },
  ["flash.nvim"] = {
    category = "Editor",
    desc = "Jumps anywhere on the screen: `s`, then the first letters of the place, then the label shown there.",
  },
  ["grug-far.nvim"] = { category = "Editor", desc = "Search and replace across files, with a preview; `Space s r`." },
  ["trouble.nvim"] = {
    category = "Editor",
    desc = "Lists of problems, references and symbols to move through; `Space x x`.",
  },
  ["todo-comments.nvim"] = {
    category = "Editor",
    desc = "Highlights TODO, FIX, HACK and NOTE comments, and finds them all in a picker.",
  },
  ["oil.nvim"] = {
    category = "Editor",
    desc = "Shows a folder as a text buffer, where renaming a line renames the file; `Space f o`.",
  },
  ["multicursor.nvim"] = {
    category = "Editor",
    desc = "Several cursors that edit together; `Alt-Down` adds one on the line below.",
  },
  ["lualine.nvim"] = { category = "UI", desc = "The status bar along the bottom of the screen." },
  ["mini.icons"] = { category = "UI", desc = "An icon for each file type, folder and plugin." },
  ["edgy.nvim"] = {
    category = "UI",
    desc = "Keeps the side panels, such as the file tree, the problem list and the Claude Code panel, at fixed"
      .. " places and sizes.",
  },
  ["rainbow-delimiters.nvim"] = {
    category = "UI",
    desc = "Colours each level of nested brackets differently.",
  },
  ["mini.hipatterns"] = {
    category = "UI",
    desc = "Shows a colour code such as `#1a1b26` in the colour it names.",
  },
  ["tokyonight.nvim"] = {
    category = "Colorscheme",
    desc = "Tokyo Night, in its night style, with the navy background.",
  },
  ["conform.nvim"] = { category = "Formatting", desc = "Runs each language's formatters on save and on `Space c f`." },
  ["nvim-lint"] = { category = "Linting", desc = "Runs each language's linters and shows what they find." },
  ["nvim-lspconfig"] = {
    category = "LSP",
    desc = "Starting settings for each language server, added to from `lua/ach/servers.lua`.",
  },
  ["mason.nvim"] = {
    category = "LSP",
    desc = "Downloads language servers, formatters, linters and debuggers into Neovim's own folder, at the versions"
      .. " `mason-lock.json` names; `Space c m`.",
  },
  ["SchemaStore.nvim"] = {
    category = "LSP",
    desc = "The schemas that tell the JSON and YAML servers what a file such as `package.json` may hold.",
  },
  ["nvim-treesitter"] = {
    category = "TreeSitter",
    desc = "Installs the Tree-sitter parsers, which read each language's syntax for highlighting, indenting and"
      .. " selecting.",
  },
  ["nvim-treesitter-textobjects"] = {
    category = "TreeSitter",
    desc = "Text objects and moves by syntax: functions, classes and parameters.",
  },
  ["nvim-dap"] = { category = "Debugging", desc = "The debugger client: breakpoints, stepping and inspecting." },
  ["nvim-dap-ui"] = { category = "Debugging", desc = "The debugger's panels; `Space d u`." },
  ["nvim-nio"] = { category = "Debugging", desc = "A library for running Lua side by side, which nvim-dap-ui needs." },
  ["nvim-dap-virtual-text"] = {
    category = "Debugging",
    desc = "Shows each variable's value beside the code while the program is paused.",
  },
  ["mason-nvim-dap.nvim"] = {
    category = "Debugging",
    desc = "Reads which debug packages Mason has installed and sets up an adapter and launch choices for each.",
  },
  ["nvim-dap-python"] = { category = "Debugging", desc = "Debugs Python through debugpy." },
  ["rustaceanvim"] = {
    category = "Language Plugins",
    desc = "Starts rust-analyzer for Rust, adds Cargo's commands, and debugs through codelldb.",
  },
  ["haskell-tools.nvim"] = {
    category = "Language Plugins",
    desc = "Starts the Haskell language server, evaluates a module's examples, and debugs through hdb.",
  },
  ["nvim-jdtls"] = {
    category = "Language Plugins",
    desc = "Starts jdtls for Java, imports the project, and runs the debugger and the tests.",
  },
  ["nvim-metals"] = {
    category = "Language Plugins",
    desc = "Starts Metals for Scala, with its own debug server.",
  },
  ["lean.nvim"] = {
    category = "Language Plugins",
    desc = "Starts the Lean server and shows the proof state beside the file.",
  },
  ["gitsigns.nvim"] = {
    category = "Git",
    desc = "Change bars in the margin, and keys to move between changes and stage them; `] h` moves to the next.",
  },
  ["neogit"] = {
    category = "Git",
    desc = "git's status page inside Neovim, where changes are staged and committed; `Space g n`.",
  },
  ["diffview.nvim"] = {
    category = "Git",
    desc = "Every uncommitted change side by side, and a file's history; `Space g D`.",
  },
  ["octo.nvim"] = {
    category = "Git",
    desc = "GitHub's issues and pull requests, through `gh`; `Space g i` and `Space g p`.",
  },
  ["claudecode.nvim"] = {
    category = "Claude Code",
    desc = "Claude Code in a panel beside the code. It sees the open file and the selection, and shows each change"
      .. " it proposes side by side; `Space a c`.",
  },
  ["vimtex"] = {
    category = "LaTeX",
    desc = "Builds the PDF on `Space c b`, shows it in Skim, and jumps from the source to the PDF and back.",
  },
  ["render-markdown.nvim"] = {
    category = "Markdown",
    desc = "Draws headings, lists, tables and code blocks in place while a Markdown file is open.",
  },
  ["live-preview.nvim"] = {
    category = "Markdown",
    desc = "A preview in the browser that keeps up with the file as it changes; `Space c p`.",
  },
}

-- Which debugger serves each language, by its name in lua/ach/languages.lua.
M.debuggers = {
  c = "lldb-dap",
  swift = "lldb-dap",
  zig = "lldb-dap",
  rust = "codelldb",
  python = "debugpy",
  typescript = "js-debug",
  java = "java-debug and java-test",
  scala = "Metals' own debug server",
  haskell = "hdb",
  go = "delve",
  kotlin = "kotlin-debug-adapter",
  dotnet = "netcoredbg",
  php = "php-debug-adapter",
  elixir = "elixir-ls's debugger",
}

-- The key card section for a key the card does not name, by the start of the
-- key as the card spells it. The longest start that matches wins, and a key
-- no start matches goes under "Outside the menus".
M.key_sections = {
  { "Space Tab", "Windows and toggles" },
  { "Space u", "Windows and toggles" },
  { "Space w", "Windows and toggles" },
  { "Space a", "Claude Code" },
  { "Space b", "Files and buffers" },
  { "Space f", "Files and buffers" },
  { "Space q", "Files and buffers" },
  { "Space e", "Files and buffers" },
  { "Space E", "Files and buffers" },
  { "Space c", "Code" },
  { "Space x", "Code" },
  { "Space d", "Debugging" },
  { "Space g", "Git" },
  { "Space s", "Search and moving" },
  { "Space :", "Search and moving" },
  { "[", "Search and moving" },
  { "]", "Search and moving" },
  { "[ d", "Code" },
  { "] d", "Code" },
  { "[ e", "Code" },
  { "] e", "Code" },
  { "[ w", "Code" },
  { "] w", "Code" },
  { "[ q", "Code" },
  { "] q", "Code" },
  { "[ [", "Code" },
  { "] ]", "Code" },
  { "[ h", "Git" },
  { "] h", "Git" },
  { "g d", "Code" },
  { "g D", "Code" },
  { "g r", "Code" },
  { "g a", "Code" },
  { "g I", "Code" },
  { "g y", "Code" },
  { "K", "Code" },
  { "Ctrl-h", "Windows and toggles" },
  { "Ctrl-j", "Windows and toggles" },
  { "Ctrl-k", "Windows and toggles" },
  { "Ctrl-l", "Windows and toggles" },
}

return M
```

The plugin names are the last part of each repository, as `lazy-lock.json` writes them, because no spec in this configuration renames a plugin with `name =`. `M.debuggers` follows the debugger table in the languages plan's debugging task, one line per language entry that table covers.

- [ ] **Write the key recorder**

`tests/helpers/keymaps.lua`:

```lua
-- The keys this configuration sets, recorded in docs/site/keymaps.json for
-- scripts/docs, which writes the post's Keymaps section without starting the
-- configuration. Keys exist only once the configuration runs, so they are read
-- in a child Neovim and kept as a file, and tests/test_docs.lua fails when the
-- file and the configuration disagree.
--   nvim -l tests/helpers/keymaps.lua ROOT OUT   writes OUT; scripts/check --keymaps runs this
local M = {}

M.FILE = "/docs/site/keymaps.json"

-- The modes a key can be set in, one letter each, in the order the file
-- writes them.
M.MODES = { "n", "x", "s", "o", "i", "c", "t" }

-- The letters each of Neovim's combined modes stands for.
local SHORT = { [""] = { "n", "x", "s", "o" }, v = { "x", "s" }, ["!"] = { "i", "c" }, l = { "i", "c" } }

-- A key in one canonical spelling: vim.keycode turns it into the bytes the
-- key sends, putting the leader key in for <leader>, and vim.fn.keytrans
-- writes those bytes back, so "<leader>ff" and "<Space>ff" come out the same.
local function norm(lhs)
  return vim.fn.keytrans(vim.keycode(lhs))
end

-- The mode letters a key set in mode works in: mode is a letter, a list of
-- letters, or nil for normal mode alone.
local function letters(mode)
  if mode == nil then
    return { "n" }
  end
  if type(mode) == "string" then
    mode = { mode }
  end
  local out = {}
  for _, m in ipairs(mode) do
    vim.list_extend(out, SHORT[m] or { m })
  end
  return out
end

-- Every key a plugin spec declares, one entry per mode.
local function plugin_keys()
  local Config = require("lazy.core.config")
  local Plugin = require("lazy.core.plugin")
  local Keys = require("lazy.core.handler.keys")
  local out = {}
  for _, plugin in pairs(Config.plugins) do
    for _, k in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
      out[#out + 1] = k
    end
  end
  return out
end

-- Every key set when this runs, each { lhs, modes, desc }, sorted by key and
-- then description. A key set twice with one description, in different modes
-- or from different places, is one entry with the modes merged. Runs inside a
-- Neovim with the configuration loaded.
function M.collect()
  local found = {}
  local function add(lhs, desc, mode)
    -- which-key sets keys of its own to open its menus, and <Plug> keys are
    -- names for other keys to call, never pressed.
    if type(lhs) ~= "string" or type(desc) ~= "string" or desc == "" then
      return
    end
    if desc:match("^which[-_]key") or lhs:match("^<Plug>") then
      return
    end
    local key = norm(lhs)
    local id = key .. "\n" .. desc
    found[id] = found[id] or { key, {}, desc }
    for _, letter in ipairs(letters(mode)) do
      found[id][2][letter] = true
    end
  end

  -- gitsigns sets its two toggles as it loads, and it loads on the first file
  -- read, which may not have happened yet.
  require("lazy").load({ plugins = { "gitsigns.nvim" } })
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, dir .. "/x.md")
  local ok, err = pcall(function()
    require("ach.git").on_attach(buf)
    require("ach.latex").attach(buf)
    require("ach.preview").attach(buf)
    for _, mode in ipairs(M.MODES) do
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
        add(map.lhs, map.desc, mode)
      end
    end
  end)
  vim.api.nvim_buf_delete(buf, { force = true })
  if not ok then
    error(err, 0)
  end

  -- Neovim's own table also holds the keys Neovim sets for itself, so only
  -- the keys under Space are taken from it. Every other key this
  -- configuration sets is in one of the three lists below.
  for _, mode in ipairs(M.MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if type(map.lhs) == "string" and norm(map.lhs):match("^<Space>") then
        add(map.lhs, map.desc, mode)
      end
    end
  end
  for _, k in ipairs(plugin_keys()) do
    add(k.lhs, k.desc, k.mode)
  end
  for _, k in ipairs(require("ach.testhook").keymaps) do
    add(k.lhs, k.desc, k.mode)
  end
  for _, k in ipairs(require("ach.lsp").keys) do
    add(k[1], k.desc, k.mode)
  end

  local out = {}
  for _, entry in pairs(found) do
    local modes = {}
    for _, letter in ipairs(M.MODES) do
      if entry[2][letter] then
        modes[#modes + 1] = letter
      end
    end
    if #modes > 0 then
      out[#out + 1] = { entry[1], table.concat(modes), entry[3] }
    end
  end
  table.sort(out, function(a, b)
    if a[1] ~= b[1] then
      return a[1] < b[1]
    end
    return a[3] < b[3]
  end)
  return out
end

-- Writes keys as a JSON list, one key to a line, so a change shows in git as
-- the lines of the keys that changed.
function M.write(path, keys)
  local lines = {}
  for i, k in ipairs(keys) do
    lines[i] = "  " .. vim.json.encode(k) .. (i < #keys and "," or "")
  end
  local f = assert(io.open(path, "wb"))
  f:write("[\n" .. table.concat(lines, "\n") .. (#lines > 0 and "\n" or "") .. "]\n")
  f:close()
end

-- The keys docs/site/keymaps.json holds.
function M.read(root)
  local f = assert(io.open(root .. M.FILE, "rb"))
  local text = f:read("*a")
  f:close()
  return vim.json.decode(text)
end

-- The keys set now, read in a child Neovim with the configuration loaded.
function M.snapshot(t)
  local child = dofile(t.root .. "/tests/helpers/child.lua")
  return child.run(t, ("report(dofile(%q).collect())"):format(t.root .. "/tests/helpers/keymaps.lua"))
end

if _G.arg and _G.arg[0] and vim.fs.basename(_G.arg[0]) == "keymaps.lua" then
  local root, out = _G.arg[1], _G.arg[2]
  local t = {
    root = root,
    tmpdir = function()
      local dir = vim.fn.tempname()
      vim.fn.mkdir(dir, "p")
      return dir
    end,
  }
  local ok, err = pcall(function()
    local keys = M.snapshot(t)
    M.write(out, keys)
    io.stdout:write(("Wrote %s: %d keys.\n"):format(vim.fs.basename(out), #keys))
  end)
  if not ok then
    io.stderr:write(tostring(err) .. "\n")
    os.exit(1)
  end
end

return M
```

`_G.arg` exists only when Neovim runs the file with `-l`, so the test suite's `dofile`, and the child that runs `collect`, get the table back and record nothing. The child is the same one every other test uses: `tests/helpers/child.lua` needs only `t.root` and `t.tmpdir()`, so run from `-l` the file builds a `t` with just those two.

- [ ] **Add `--keymaps` to `scripts/check`**

In `scripts/check`, replace:

```bash
#   scripts/check --baseline   time this configuration against stock LazyVim and write tests/baseline.json
```

with:

```bash
#   scripts/check --baseline   time this configuration against stock LazyVim and write tests/baseline.json
#   scripts/check --keymaps    record every key this configuration sets in docs/site/keymaps.json
```

Then replace:

```bash
baseline=0
while [ $# -gt 0 ]; do
    case "$1" in
        --full) full=1 ;;
        --only) shift; only=${1:-} ;;
        --baseline) baseline=1 ;;
```

with:

```bash
baseline=0
keymaps=0
while [ $# -gt 0 ]; do
    case "$1" in
        --full) full=1 ;;
        --only) shift; only=${1:-} ;;
        --baseline) baseline=1 ;;
        --keymaps) keymaps=1 ;;
```

Then replace:

```bash
if [ "$baseline" = 1 ]; then
    status=0
    nvim -l "$root/tests/helpers/startup.lua" "$root" "$scratch/bench" || status=$?
    exit "$status"
fi
```

with:

```bash
if [ "$baseline" = 1 ]; then
    status=0
    nvim -l "$root/tests/helpers/startup.lua" "$root" "$scratch/bench" || status=$?
    exit "$status"
fi

# --keymaps runs no tests either. It reads every key the configuration sets in
# a child Neovim and writes docs/site/keymaps.json, which scripts/docs turns
# into the documentation post's Keymaps section.
if [ "$keymaps" = 1 ]; then
    status=0
    nvim -l "$root/tests/helpers/keymaps.lua" "$root" "$root/docs/site/keymaps.json" || status=$?
    exit "$status"
fi
```

The new branch sits after the exports, so the child Neovim gets the same throwaway state folder and `ACH_TEST` the regular suite does, and the same plugins, which live in Neovim's real data folder. The help line falls between line 2 and `# Exit`, so `scripts/check -h` shows it with no other change.

- [ ] **Write the generator**

`scripts/docs`:

```bash
#!/usr/bin/env bash
# Writes the documentation post, one MDX file for the website, from this
# repository's own source. It never starts the configuration.
#   scripts/docs --out <file> [--date YYYY-MM-DD]
# A relative <file> is taken from the repository root. Exit 0 when the post is
# written, 1 on any error, 2 when Neovim is not installed.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
if ! command -v nvim >/dev/null 2>&1; then
    echo "Neovim is not installed. Install it with: brew install neovim" >&2
    exit 2
fi
cd "$root"
exec nvim --clean --headless -l scripts/docs.lua "$@"
```

Run: `chmod +x scripts/docs`
Expected: no output, exit 0.

`scripts/docs.lua`:

```lua
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
  local function plain(s)
    return (s:gsub("[\\{}<>*_%[%]%$]", "\\%0"))
  end
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
function M.cell(text)
  return (M.escape(text):gsub("|", "\\|"):gsub("\n", " "))
end

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
function M.fence(text)
  return ("`"):rep(math.max(3, longest_run(text) + 1))
end

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
local function norm(lhs)
  return vim.fn.keytrans(vim.keycode(lhs))
end

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

local function quote(text)
  return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

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
```

`package.path` is set inside `main`, never as the file loads, so a test can `dofile` the file without changing where `require` looks. It puts the repository's `lua/` folder first, which is how `require("ach.docs")` finds this repository's file: `nvim --clean` leaves `~/.config/nvim` off Neovim's own search path. The post is built whole in memory and written only once nothing has failed, so a failed run never leaves half a post behind.

- [ ] **Write the four pages**

The pages are the owner's own words, in the first person. Each do and don't rests on something the three plans build, and every command in them is one the plans define. The post gives each page its `##` heading, so a page's own headings start at `###`. A box is a `<Callout>` with a blank line inside each tag, which is what lets MDX read the Markdown in it.

`docs/site/getting-started.md`:

````markdown
ACH-NEOVIM is my Neovim configuration for macOS. Neovim is a text editor that runs inside a terminal and is driven from the keyboard, and a configuration is the set of files that tells it which plugins to load, what each key does and how each language is handled. I wrote this one from scratch on lazy.nvim, the plugin manager, and it lives at [github.com/anirbanchakraborty-dev/ACH-NEOVIM](https://github.com/anirbanchakraborty-dev/ACH-NEOVIM) under the MIT licence.

**Why I built it.** I wanted one editor that already knows every language I work in: C and C++, Python, Rust, SystemVerilog and Verilog, VHDL, LaTeX and Markdown, with the rest of about ninety languages there when I need them. I did not want it to fill my disk with tools for languages I never open, so nothing for a language installs until I open a file in it. I wanted it to start fast, too. It starts no slower than stock LazyVim, and its own test suite fails any change that makes it take more than one and a half times as long to start as it did when I first timed it. LazyVim showed me what a well-made Neovim setup looks like. I took its ideas and built my own, small enough that I can read every line of it and keep it working, and the few files that adapt a LazyVim function say so in their first lines and name LazyVim's Apache-2.0 licence.

**Who it is for.** It is for someone on a Mac who writes code and technical documents in many languages, works from the keyboard, and would rather set things up properly once than tinker forever.

<Callout type="warning">

It is not for someone learning Vim for the first time. Run `nvim --clean +Tutor` first, which opens Neovim's own lessons without this configuration, and come back when the motions feel natural. ACH-NEOVIM switches the tutor off, with a few other built-in plugins, so it starts faster.

</Callout>

<Callout type="warning">

It is not for Linux or Windows. I run it on macOS in Ghostty, and that is the only place I test it.

</Callout>

**My favourite part.** I never install a language's tools by hand. I open a file in a language I have not touched in months, and while I read the first screen, its highlighting, completion and formatter install in the background and switch on. A close second is having Claude Code right inside the editor, on `Space a c`, looking at the same file I am.

<Callout type="tip">

Keep the key card beside you while the keys are new. It is `docs/key-card.md` in the repository, the dashboard points to it, and every key on it has a one-line description and a sentence saying what it does. The Keymaps section below lists every key the configuration sets.

</Callout>
````

`docs/site/installation.md`:

````markdown
Installing takes one Homebrew session, one clone and one first start. Every command below is typed in a terminal, in the order given.

**Install Homebrew.** Homebrew is the Mac's package manager, and everything else comes from it. If `brew --version` prints nothing, follow the one command on [brew.sh](https://brew.sh).

**Install the programs.** Neovim itself, git, ripgrep and fd for searching, lazygit for git, the tree-sitter command-line program, ImageMagick for pictures, Ghostty, and the font:

```bash
brew install neovim git ripgrep fd lazygit tree-sitter-cli imagemagick
brew install --cask ghostty font-jetbrains-mono-nerd-font
xcode-select --install
```

ACH-NEOVIM needs Neovim 0.12.4 or later, and `nvim --version` prints the version on its first line. The tree-sitter program builds each language's parser, the part that reads its syntax, with the compiler from Apple's Command Line Tools, which is what the last line installs.

<Callout type="tip">

Install Ghostty and the JetBrains Mono Nerd Font before anything else. Every icon in the editor comes from that font, and without it each one shows as an empty box.

</Callout>

**Back up what you have.** The clone goes exactly where a Neovim configuration lives, so move yours aside first, with the folders Neovim keeps its data, its state and its cache in:

```bash
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

A line whose folder does not exist only prints an error, so run all four.

<Callout type="warning">

Do not skip the backup. ACH-NEOVIM keeps its plugins, its language tools, its history and its sessions in those same folders, so starting it on top of another setup's folders leaves the two mixed together.

</Callout>

**Clone the configuration.**

```bash
git clone https://github.com/anirbanchakraborty-dev/ACH-NEOVIM ~/.config/nvim
```

**Link Ghostty's settings.** The repository carries Ghostty's settings in `ghostty/config.ghostty`: the font at 15 points, the navy background, the left Option key working as Alt, and the sixteen colours Neovim's own terminal uses. Link the file to where Ghostty reads it:

```bash
mkdir -p ~/.config/ghostty
ln -s ~/.config/nvim/ghostty/config.ghostty ~/.config/ghostty/config.ghostty
```

<Callout type="warning">

Do not keep an old `~/.config/ghostty/config` beside the link. Ghostty reads both files and warns about it. Move any setting you want to keep out of `~/Library/Application Support/com.mitchellh.ghostty/config` too, because Ghostty reads that file last and a setting there wins.

</Callout>

**Start Neovim.**

```bash
nvim
```

The first start installs every plugin at the commit pinned in `lazy-lock.json`, so you get the versions I test. Let it finish before you open anything.

**Check what is missing.** Inside Neovim, type this and press Enter:

```text
:checkhealth ach
```

Read what it says. It lists each program the configuration uses, installed or not, and gives each missing one the single command that installs it.

**Open a file.** The first time you open a file in a language, its parser, its language server, its formatter and its linter install by themselves in the background, without asking, and switch on when they are ready. A language that needs a compiler or runtime only Homebrew provides, such as Haskell's GHC or Julia, asks first, once, in one line that names it and its rough size. Say yes, and Homebrew installs it in the background while you keep editing. Say no, and it does not ask again until you next start Neovim.

<Callout type="warning">

Do not say yes to a compiler on a slow or metered connection. Haskell's runs to about 3 GB and Julia's to about 1.5 GB.

</Callout>

**Add the programs some keys use.** A key whose program is missing prints the line that installs it instead of running, and `:checkhealth ach` lists the same programs:

| Program | What it is for | Install |
| --- | --- | --- |
| `lazygit` | Lazygit on `Space g g` and `Space g G` | `brew install lazygit` |
| `gh` | GitHub issues and pull requests on `Space g i` and `Space g p` | `brew install gh`, then `gh auth login` |
| `claude` | the Claude Code panel on `Space a` | `brew install --cask claude-code` |
| `latexmk` | building LaTeX documents on `Space c b` | `brew install --cask mactex` |
| `displayline` | showing LaTeX PDFs in Skim and jumping between them and the source | `brew install --cask skim` |
| `magick` | turning pictures and formulas into images the terminal can show | `brew install imagemagick` |
| `pdflatex` | typesetting the formulas in Markdown files | `brew install --cask mactex` |
| `gs` | letting ImageMagick read the PDF a formula is typeset into | `brew install ghostscript` |
| `pdftotext` | reading Intel's manual to find each instruction's page | `brew install poppler` |
| `newsboat` | the feed reader on `Space N` | `brew install newsboat` |

<Callout type="warning">

Do not `brew install` language servers, formatters or linters yourself. Mason, the package manager inside Neovim, installs each one into Neovim's own folder at the version pinned in `mason-lock.json`, and puts that folder on the path Neovim searches. A second copy from Homebrew is one more version that can differ from the pinned one, and you are left guessing which one runs.

</Callout>
````

`docs/site/news.md`:

````markdown
Here is what ACH-NEOVIM does beyond editing text, area by area. Each area's keys are in the Keymaps section below.

**Git.** Change bars in the margin show what changed since the last commit, and `] h` and `[ h` move between the changes. Lazygit opens on `Space g g`. Neogit, git's status page inside Neovim, opens on `Space g n`, and diffview shows every uncommitted change side by side on `Space g D`. GitHub's issues and pull requests are on `Space g i` and `Space g p`, through `gh`. A git key pressed on a file outside every repository says so and opens nothing, and a link copied to the current line never carries a user name or a token from the remote's address.

**Claude Code.** `Space a c` opens Claude Code in a panel on the right, 40 percent of the screen wide. It sees the file and the selection I am on, and a change it proposes opens side by side, to accept with `Space a a` or reject with `Space a d`. Its server listens only on this Mac, refuses a connection without the token in its lock file, and never starts when Neovim has no window.

**LaTeX.** VimTeX builds the document on `Space c b`, with latexmk or with a command the project sets, and shows the PDF in Skim, and I can jump from a line of the source to its place in the PDF and back. The build's own files are kept outside the repository.

**Markdown.** Headings, lists and tables are drawn in place while I write, formulas and pictures are drawn as images inside the editor, and `Space c p` opens a preview in the browser that keeps up with the file as it changes. The preview's server listens only on this Mac and serves nothing outside the folder it was started for.

**Intel's manual.** `Space c x` opens Intel's x86 manual in Skim at the page for the instruction under the cursor, and on any other word lists every instruction to pick one. The manual is Intel's to publish, so it is not in the repository.

**News.** `Space N` opens newsboat, a feed reader, in a window floating over the editor.

**Ghostty.** The repository carries Ghostty's settings: JetBrains Mono at 15 points, the same navy background as the editor, the left Option key working as Alt, and the sixteen colours Neovim's own terminal uses.

**Startup.** It starts no slower than stock LazyVim, and the test suite fails any change that makes it take more than one and a half times as long to start as it did when first timed.

**Updates.** `scripts/update` updates every plugin and Mason package, runs the full test suite, and commits both lock files when it passes, or puts everything back when it does not.

**Upgrade check.** The first time a new Neovim release starts on a screen, the fast test suite runs in the background, and the release is recorded once it passes.

**Key card.** `docs/key-card.md` is one page of keys to keep beside the keyboard, and a test fails whenever it disagrees with the keys the configuration sets.

**This page.** `scripts/docs` writes this page from the configuration's own source, so a plugin, a key or a language added to the configuration shows here the next time it runs.
````

`docs/site/configuration.md`:

````markdown
Everything that makes ACH-NEOVIM what it is lives in plain Lua files in the repository. These are the places I change most, and how I change them.

### The layout

```text
~/.config/nvim
├── init.lua           checks the Neovim version, then loads lua/ach
├── lazy-lock.json     the commit of every plugin
├── mason-lock.json    the version of every Mason package
├── lua/ach/           options, keys, autocommands, the language table, and the logic behind each feature
│   └── plugins/       the plugin specs, one file per area
├── snippets/          my own snippets
├── ghostty/           Ghostty's settings
├── docs/              the key card, the list of languages, and the hand-written parts of this page
├── scripts/           check, update and docs
└── tests/             the test suite
```

### Options, keymaps and autocommands

Editor options live in `lua/ach/options.lua`, keys that belong to no plugin in `lua/ach/keymaps.lua`, and autocommands, the small actions Neovim runs when something happens, such as opening a file or saving one, in `lua/ach/autocmds.lua`. Keys that belong to a plugin live in that plugin's spec, under `keys`.

### Adding a plugin

A plugin is a file in `lua/ach/plugins/` that returns its spec, because lazy.nvim imports every file in that folder. The Full Spec tabs in the Plugins section below are real specs to copy from. Then:

- Give every key a `desc`, and give that description a line in `M.keys` in `lua/ach/icons.lua`. The test suite fails a key without one, since that line is what draws its icon in the menus.
- Give the plugin an entry in `lua/ach/docs.lua`, with its category and one sentence saying what it does. The test suite fails a plugin in `lazy-lock.json` without one.
- Start Neovim once, so lazy.nvim installs the plugin and records its commit in `lazy-lock.json`.
- If the plugin adds keys, run `scripts/check --keymaps`. Then run `scripts/check`, and commit the new file, `lazy-lock.json`, `lua/ach/icons.lua`, `lua/ach/docs.lua` and `docs/site/keymaps.json` together.

### Adding a language

Every language is one entry in `M.languages` in `lua/ach/languages.lua`, under its name. The entry lists the file types it covers in `ft`, the Tree-sitter parsers in `ts`, the language servers in `lsp`, the formatters in `fmt`, the linters in `lint`, any other Mason packages it needs in `mason`, and `harper = true` when Harper should check its grammar. The Entry tab of each language in the Languages section below is that language's real entry, and CMake's uses every one of these fields. Settings for a server go in `M.settings` in `lua/ach/servers.lua`, under the server's name, and show in the language's Options tab.

Then run `scripts/check`, and `scripts/check --full`, which installs the new language's tools, tests them, adds their versions to `mason-lock.json` and rewrites the list of languages in `docs/languages.md`. Commit all of it together.

### Settings for one project

Neovim reads a file called `.nvim.lua` in the folder it starts in, because ACH-NEOVIM turns on Neovim's `exrc` option. Neovim asks before it runs such a file the first time, and again whenever the file changes, so a repository you clone cannot run code on you just by shipping one. A LaTeX project can use it to give `Space c b` its own build command:

```lua
require("ach.latex").build_with(function(main)
  return { "make", "pdf" }, vim.fs.dirname(main)
end)
```

The function receives the main file's path and returns the command and the folder to run it in. Returning nothing falls back to latexmk.

<Callout type="warning">

Do not edit the configuration's own files for one project's needs. Put them in that project's `.nvim.lua`, where they stay with the project and never get in the way of an update.

</Callout>

### Updates and the lock files

`lazy-lock.json` holds the commit of every plugin and `mason-lock.json` the version of every Mason package, so two Macs on the same commit of this repository run the same code.

- `scripts/update --list` shows what an update would move: the new commits of each plugin and the newer release of each Mason package. It changes nothing.
- `scripts/update` updates every plugin and Mason package, runs `scripts/check --full`, and commits both lock files when it passes. When it fails, it puts the lock files back and makes what is installed match them again.
- `scripts/update --restore` does only that second part. Run it on a second Mac after a `git pull` brings new lock files.
- Inside Neovim, `:AchMasonUpdate` updates every installed Mason package and moves its pin, and `:AchMasonLock` pins a package installed by hand from the `:Mason` window.

<Callout type="warning">

Do not edit `lazy-lock.json` or `mason-lock.json` by hand. Update through `scripts/update` and the two commands above, so the lock files always describe what is really installed.

</Callout>
````

- [ ] **Record the keys**

Run: `scripts/check --keymaps`
Expected: `Wrote keymaps.json: <n> keys.`, exit 0, and `docs/site/keymaps.json` holding one key to a line, such as `["<Space>ff","n","Find Files (Root Dir)"]`. If a later change adds, renames or removes a key, this step runs again in that change's commit.

- [ ] **Run the tests and see them pass**

Run: `scripts/check --only test_docs`
Expected: `15 passed, 0 failed, 0 need a person, 0 skipped`, exit 0. If the lock test lists a plugin, the lock names a plugin `lua/ach/docs.lua` does not have, or the other way round: give it an entry, with one of the fifteen categories and one sentence, and run this again.

- [ ] **Run the suite**

Run: `scripts/check`
Expected: every test passes, exit 0, with the same skips as before this task. No key, program or plugin is added, so `lua/ach/icons.lua`, `lua/ach/need.lua` and `lazy-lock.json` do not change.

- [ ] **Write the post once**

Run: `scripts/docs --out "$TMPDIR/ach-neovim.mdx" && /usr/bin/grep -c '^#### ' "$TMPDIR/ach-neovim.mdx"`
Expected: `Wrote <path>/ach-neovim.mdx: <n> lines.`, then the number of plugins in `lazy-lock.json`, exit 0. Its first seven lines are the front matter, with HEAD's commit date.

- [ ] **Format the Lua**

Run: `stylua lua tests scripts/docs.lua`
Expected: no output, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/docs.lua scripts/docs scripts/docs.lua tests/helpers/keymaps.lua tests/test_docs.lua docs/site/getting-started.md docs/site/installation.md docs/site/news.md docs/site/configuration.md docs/site/keymaps.json
git commit --only lua/ach/docs.lua scripts/docs scripts/docs.lua tests/helpers/keymaps.lua tests/test_docs.lua docs/site/getting-started.md docs/site/installation.md docs/site/news.md docs/site/configuration.md docs/site/keymaps.json scripts/check -m "docs(post): generate the documentation post from the source"
```

---
