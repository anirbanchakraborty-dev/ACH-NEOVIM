# ACH-NEOVIM Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Neovim configuration that starts, draws the navy theme, the tiled status bar and the ACH NEOVIM dashboard, teaches every key through which-key, edits with the chosen editor plugins and completes with blink.cmp, all under a headless test suite.

**Architecture:** A standalone distribution on lazy.nvim. `init.lua` finds the repository from its own path, so the same checkout works through the `~/.config/nvim` link, through `nvim -u`, and from the tests. Plugin specs live in `lua/ach/plugins/`, and the logic worth testing lives in small modules under `lua/ach/` that the specs call. `scripts/check` runs Neovim headless against the real configuration and runs every `tests/test_*.lua`.

**Tech Stack:** Neovim 0.12, LuaJIT, lazy.nvim, tokyonight.nvim, lualine.nvim, snacks.nvim, mini.icons, which-key.nvim, flash.nvim, grug-far.nvim, trouble.nvim, todo-comments.nvim, oil.nvim, persistence.nvim, multicursor.nvim, rainbow-delimiters.nvim, mini.hipatterns, edgy.nvim, blink.cmp, friendly-snippets, mini.pairs, mini.ai, ts-comments.nvim, bash.

**Spec:** `docs/specs/2026-10-10-ach-neovim-design.md`

This is the first of three plans, run in this order: foundation, languages, integrations. Each leaves a working configuration behind it. The owner's private repository keeps a short wiring plan of its own, which installs the Homebrew packages before this plan starts and links `~/.config/nvim` after the integrations plan ends. Nothing in this repository refers to it.

## Global Constraints

- Neovim 0.12 or later. `init.lua` refuses to load on anything older, with the message `ACH-NEOVIM needs Neovim 0.12 or later: brew upgrade neovim`.
- Every command in this plan runs from the repository root, the folder that holds `init.lua`.
- LazyVim is a reference, never a dependency. Nothing requires or imports a `lazyvim` module. A file that adapts a LazyVim function says so in its header comment, as `-- Adapted from LazyVim (Apache-2.0), <path in LazyVim>.`
- Nothing writes into the repository while the editor runs, except `lazy-lock.json` and `mason-lock.json` during an update made on purpose. Plugins live under `~/.local/share/nvim`, and history, undo files, sessions and logs under `~/.local/state/nvim`.
- Colours are exactly those in `lua/ach/palette.lua`, which copies the spec's tables. No other hex value appears in a theme or status-bar file.
- No character in the status bar is an angle bracket, chevron, arrowhead or triangle, as defined by `lua/ach/glyphs_forbidden.lua`. The rule covers the status bar only.
- Every key this configuration defines carries a `desc`.
- Every icon a key, which-key group, toggle, file type, dashboard button, completion item or status-bar tile shows comes from `lua/ach/icons.lua`, named there by its Nerd Fonts 3.5.1 name. The one other glyph in the configuration is `glyphs.fallback`, the plain file icon the status bar shows in place of a forbidden one.
- This repository names no folder of the owner's private repository. Anything specific to it arrives through the hook functions this plan defines, called from that repository's own `.nvim.lua`.
- Lua is formatted by `stylua.toml`: two-space indent, 120 columns, double quotes.
- Markdown in this repository keeps one paragraph per line, with no hard wrap and no numbered headings or numbered lists.
- Commits are made inside this repository, with `git commit --only <paths>` and a Conventional Commit subject that carries a scope, such as `feat(theme): …`. Nothing is pushed without the owner's yes.

## Review Focus

- **A file type whose own icon is forbidden.** Opening an XML file must show the plain file icon in the status bar, not the angle-bracket icon mini.icons gives XML. The test lives in the status bar task.
- **A file outside any git repository.** The status bar must drop the branch block and its gap entirely, and the project block must fall back to the working folder's name. The test lives in the status bar task.
- **A window narrower than the banner.** At 60 columns the dashboard must show the words `ACH NEOVIM` instead of a wrapped, broken banner. The test lives in the dashboard task.
- **Neovim missing from the PATH.** `scripts/check` must exit 2 and print `brew install neovim`, not a shell error. The test lives in the harness task.
- **Starting through the `~/.config/nvim` symbolic link.** The configuration must resolve its root to the real checkout, so the lock files and snippets are found. The test lives in the harness task.

## File Structure

| Path | Responsibility |
| --- | --- |
| `init.lua` | Version gate, finds the repository root, installs the test hook under `ACH_TEST=1`, loads `ach` |
| `lua/ach/init.lua` | Loads options, autocommands, the plugin manager, and the keymaps at VeryLazy |
| `lua/ach/options.lua` | Editor options and leader keys |
| `lua/ach/autocmds.lua` | Autocommands that are not owned by a plugin |
| `lua/ach/keymaps.lua` | Core keys, each with a description |
| `lua/ach/lazy.lua` | Installs lazy.nvim on first start and calls `require("lazy").setup` |
| `lua/ach/testhook.lua` | Test-only recording of warnings, of every key a file under `lua/ach/` sets, and of keys set without a description |
| `lua/ach/util.lua` | Project root and git root of a buffer |
| `lua/ach/palette.lua` | Every colour the theme and status bar use |
| `lua/ach/contrast.lua` | The WCAG 2 contrast formula |
| `lua/ach/glyphs_forbidden.lua` | Generated set of forbidden status-bar codepoints |
| `lua/ach/glyphs_known.lua` | Generated ranges of every codepoint Nerd Fonts 3.5.1 draws |
| `lua/ach/glyphs.lua` | Checks a string against the forbidden set, swaps a forbidden icon for a plain one, and says whether the font draws a codepoint |
| `lua/ach/icons.lua` | The icon database: every glyph by its Nerd Font name, the icon for each key, group, toggle and file type, and helpers that hand each plugin the shape it expects |
| `lua/ach/statusline.lua` | The status bar's theme, components and lualine options |
| `lua/ach/banner.lua` | The block-letter rule and the dashboard banner |
| `lua/ach/dashboard.lua` | Dashboard sections, buttons and tips, with hooks for a private `.nvim.lua` |
| `lua/ach/plugins/core.lua` | lazy.nvim managing itself |
| `lua/ach/plugins/colorscheme.lua` | tokyonight with the navy overrides |
| `lua/ach/plugins/statusline.lua` | lualine and mini.icons |
| `lua/ach/plugins/dashboard.lua` | snacks core: the notifier and the dashboard |
| `lua/ach/plugins/keys.lua` | which-key with the Space menus, and the snacks picker with its keys |
| `lua/ach/plugins/editor.lua` | flash, grug-far, trouble, todo-comments, oil, persistence, multicursor, and the snacks explorer, bigfile and quickfile (the terminal keys live in `keymaps.lua`) |
| `lua/ach/plugins/ui.lua` | edgy, rainbow-delimiters, mini.hipatterns, and the snacks indent guides, scope, word highlights, status column and input box |
| `lua/ach/plugins/coding.lua` | blink.cmp, friendly-snippets, mini.pairs, mini.ai, ts-comments |
| `snippets/` | VS Code format snippets: `package.json`, `all.json`, `tex.json`, `lua.json` |
| `assets/banner.txt` | The banner as the spec prints it, which the test compares with the rule's output |
| `scripts/check` | Runs the headless suite, exit 0, 1 or 2 |
| `scripts/fetch-matcher` | Waits for blink.cmp's compiled matcher to download, exit 0 once it is in use |
| `scripts/gen-glyphs`, `scripts/gen_glyphs.lua` | Download Nerd Fonts 3.5.1 glyph names and regenerate the forbidden set and the known ranges |
| `tests/run.lua` | Discovers and runs tests, prints results, sets the exit code |
| `tests/test_*.lua` | One file per area, each returning a table of named tests |
| `README.md`, `LICENSE`, `.gitignore`, `stylua.toml` | Repository basics |

---

### Task: Repository scaffold and test harness

**Files:**
- Create: `README.md`, `LICENSE`, `.gitignore`, `stylua.toml`
- Create: `init.lua`, `lua/ach/init.lua`, `lua/ach/testhook.lua`
- Create: `scripts/check`, `tests/run.lua`
- Test: `tests/test_harness.lua`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `vim.g.ach_root: string`, the repository's real path, symbolic links resolved.
  - `require("ach.testhook")` with `install()`, `notifications: {msg: string, level: integer|string}[]`, `keymaps: {mode, lhs, desc, where}[]` (every key a file under `lua/ach/` sets with a description), `keymaps_without_desc: {mode, lhs, where}[]`, and `warnings(): {msg, level}[]`, which merges its own record with snacks.notifier's history.
  - The test helper `t` passed to every test: `t.eq(got, want, what?)`, `t.ok(value, what?)`, `t.human(why)` (exit 2), `t.skip(why)`, `t.tmpdir(): string`, `t.root: string`, `t.full: boolean`, `t.startup: { errmsg: string, warnings: {msg, level}[] }`.
  - Test files are `tests/test_<area>.lua`, each returning `{ ["test name"] = function(t) end }`. Files named `tests/test_full*.lua` run only under `--full`.
  - `scripts/check [--full] [--only TEXT]`, exit 0 when all pass, 1 on a failure, 2 when a person must act.

- [ ] **Create the repository basics**

Run `git init -b main` in the repository root, which already holds `docs/specs/` and `docs/plans/`. Both go into the first commit, so the design and the plans that built the configuration are published with it.

`README.md`:

```markdown
# ACH-NEOVIM

A Neovim distribution for one person's Mac, written from scratch on lazy.nvim. It carries a deep-navy tokyonight theme, a tiled status bar, the ACH NEOVIM start screen, every language the owner might open with highlighting, intellisense, completion, formatting, linting and grammar checking, and Claude Code inside the editor.

It needs Neovim 0.12 or later. To try it, clone it into `~/.config/nvim` and start `nvim`. The first start installs the plugins.

The design is in `docs/specs/2026-10-10-ach-neovim-design.md`. `scripts/check` runs the headless test suite.

LazyVim, by Folke Lemaitre, is the reference this configuration learned from. Nothing here imports it, and files that adapt one of its functions say so. LazyVim is Apache-2.0 licensed.

ACH-NEOVIM is MIT licensed.
```

`LICENSE`:

```text
MIT License

Copyright (c) 2026 Anirban Chakraborty

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

`.gitignore`:

```gitignore
.DS_Store
*.bak
*~
```

`stylua.toml`:

```toml
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
collapse_simple_statement = "FunctionOnly"
```

- [ ] **Write the entry point and the test hook**

`init.lua`:

```lua
-- ACH-NEOVIM entry point. The repository is the configuration, so every path
-- is derived from where this file really sits: through the ~/.config/nvim
-- link, through `nvim -u`, and from scripts/check alike.
if vim.fn.has("nvim-0.12") == 0 then
  vim.api.nvim_echo({ { "ACH-NEOVIM needs Neovim 0.12 or later: brew upgrade neovim", "ErrorMsg" } }, true, {})
  return
end

local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local root = vim.uv.fs_realpath(here) or here
vim.g.ach_root = root
if not vim.tbl_contains(vim.opt.rtp:get(), root) then
  vim.opt.rtp:prepend(root)
end

if vim.env.ACH_TEST == "1" then
  require("ach.testhook").install()
end

require("ach")
```

`lua/ach/init.lua` (this task's version, extended by the next task):

```lua
-- Loads the configuration in order. Keymaps wait for VeryLazy, after the first
-- screen has drawn.
```

`lua/ach/testhook.lua`:

```lua
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
  local ok, history = pcall(function()
    return Snacks.notifier.get_history()
  end)
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
```

- [ ] **Write the check script and the runner**

`scripts/check` (make it executable with `chmod +x scripts/check`):

```bash
#!/usr/bin/env bash
# Run ACH-NEOVIM's headless test suite against the real configuration.
#   scripts/check              fast mode, about a minute
#   scripts/check --full       also installs every language's tools and tests them
#   scripts/check --only TEXT  run only tests whose "file :: name" label contains TEXT
# Exit 0 when everything passes, 1 on a failure, 2 when a person must act.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
full=0
only=""
while [ $# -gt 0 ]; do
    case "$1" in
        --full) full=1 ;;
        --only) shift; only=${1:-} ;;
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

status=0
nvim --headless -u "$root/init.lua" "+luafile $root/tests/run.lua" || status=$?
exit "$status"
```

`tests/run.lua`:

```lua
-- Headless test runner. scripts/check starts Neovim with the real configuration
-- and then this file. Each tests/test_*.lua returns a table of named tests, and
-- each test receives the helper table t defined below.
local root = vim.g.ach_root
local full = vim.env.ACH_FULL == "1"
local only = vim.env.ACH_ONLY or ""
local out = io.stdout

-- lazy.nvim fires VeryLazy after UIEnter, which a headless Neovim never sees,
-- so the runner fires it by hand and waits for lazy.nvim to finish.
vim.api.nvim_exec_autocmds("UIEnter", { modeline = false })
if not vim.wait(10000, function() return vim.g.did_very_lazy == true end, 20) then
  out:write("FAIL startup: VeryLazy never fired\n")
  vim.cmd("cquit 1")
end
vim.wait(300) -- lets notifications scheduled during startup arrive

local hook = require("ach.testhook")
local t = {
  root = root,
  full = full,
  startup = { errmsg = vim.v.errmsg, warnings = hook.warnings() },
}

function t.eq(got, want, what)
  if not vim.deep_equal(got, want) then
    error(("%s: expected %s, got %s"):format(what or "value", vim.inspect(want), vim.inspect(got)), 2)
  end
end

function t.ok(value, what)
  if not value then
    error(what or "expected a true value", 2)
  end
end

function t.human(why)
  error({ human = why }, 0)
end

function t.skip(why)
  error({ skip = why }, 0)
end

function t.tmpdir()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir)
end

local counts = { pass = 0, fail = 0, human = 0, skip = 0 }

local function report(kind, label, detail)
  counts[kind] = counts[kind] + 1
  local word = ({ pass = "PASS", fail = "FAIL", human = "HUMAN", skip = "SKIP" })[kind]
  out:write(word .. " " .. label .. (detail and (": " .. detail) or "") .. "\n")
end

local function run_test(label, fn)
  if only ~= "" and not label:find(only, 1, true) then
    return
  end
  local ok, err = xpcall(fn, function(e)
    return type(e) == "table" and e or debug.traceback(tostring(e), 2)
  end, t)
  if ok then
    report("pass", label)
  elseif type(err) == "table" and err.skip then
    report("skip", label, err.skip)
  elseif type(err) == "table" and err.human then
    report("human", label, err.human)
  else
    report("fail", label, tostring(err))
  end
end

local function run_file(file)
  local base = vim.fs.basename(file):gsub("%.lua$", "")
  if base:find("^test_full") and not full then
    return
  end
  local ok, suite = pcall(dofile, file)
  if not ok then
    report("fail", base, suite)
    return
  end
  local names = vim.tbl_keys(suite)
  table.sort(names)
  for _, name in ipairs(names) do
    run_test(base .. " :: " .. name, suite[name])
  end
end

local files = vim.fn.glob(root .. "/tests/test_*.lua", false, true)
table.sort(files)
for _, file in ipairs(files) do
  run_file(file)
end

-- A filter that matches nothing would otherwise pass with nothing run.
if only ~= "" and counts.pass + counts.fail + counts.human + counts.skip == 0 then
  report("fail", "--only " .. only, "no test matches")
end

out:write(("\n%d passed, %d failed, %d need a person, %d skipped\n"):format(
  counts.pass, counts.fail, counts.human, counts.skip))
out:flush()
if counts.fail > 0 then
  vim.cmd("cquit 1")
elseif counts.human > 0 then
  vim.cmd("cquit 2")
else
  vim.cmd("qall!")
end
```

- [ ] **Write the failing test**

`tests/test_harness.lua`:

```lua
return {
  ["finds the repository root"] = function(t)
    t.ok(vim.uv.fs_stat(t.root .. "/init.lua"), "init.lua should sit at " .. t.root)
    t.eq(vim.g.ach_root, vim.uv.fs_realpath(t.root))
  end,

  ["resolves the root through a symbolic link"] = function(t)
    local link = t.tmpdir() .. "/nvim"
    assert(vim.uv.fs_symlink(t.root, link))
    local r = vim.system({ vim.v.progpath, "--headless", "-u", link .. "/init.lua",
      "+lua io.stdout:write(vim.g.ach_root)", "+qall!" }, { text = true }):wait()
    vim.uv.fs_unlink(link)
    t.eq(r.stdout, t.root, "root seen through " .. link)
  end,

  ["exits 2 with the install command when Neovim is missing"] = function(t)
    local r = vim.system({ t.root .. "/scripts/check" }, { env = { PATH = "/usr/bin:/bin" }, text = true }):wait()
    t.eq(r.code, 2, "exit code")
    t.ok(r.stderr:find("brew install neovim", 1, true), "message should name the install command, got: " .. r.stderr)
  end,

  ["fails when --only matches no test"] = function(t)
    local r = vim.system({ t.root .. "/scripts/check", "--only", "no test is named this" }, { text = true }):wait()
    t.eq(r.code, 1, "exit code")
    t.ok(r.stdout:find("no test matches", 1, true), "the report should say why, got: " .. r.stdout)
  end,

  ["keeps test state out of the real state folder"] = function(t)
    t.ok(vim.env.XDG_STATE_HOME, "XDG_STATE_HOME should be set by scripts/check")
    t.eq(vim.fn.stdpath("state"):find(vim.env.XDG_STATE_HOME, 1, true), 1)
  end,

  ["records warnings raised through vim.notify"] = function(t)
    local hook = require("ach.testhook")
    local before = #hook.warnings()
    vim.notify("harness probe", vim.log.levels.WARN)
    vim.notify("harness info", vim.log.levels.INFO)
    vim.wait(100)
    t.eq(#hook.warnings() - before, 1, "only the warning is recorded")
  end,
}
```

The last test reads `hook.warnings()` rather than the hook's own list, so it keeps passing once a later task loads snacks.notifier, which replaces `vim.notify` and keeps its own history.

- [ ] **Run the suite and see it fail**

Run: `scripts/check`
Expected: FAIL. `lua/ach/init.lua` loads nothing yet, and `require("ach")` succeeds, so the run reaches the runner, but `FAIL startup: VeryLazy never fired` appears and the exit code is 1, because there is no lazy.nvim to fire VeryLazy.

- [ ] **Make VeryLazy fire without lazy.nvim for now**

Temporary until the next task installs lazy.nvim. Append to `lua/ach/init.lua`:

```lua
if not package.loaded["lazy"] then
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      vim.g.did_very_lazy = true
    end,
  })
end
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: PASS for all six `test_harness` tests, then `6 passed, 0 failed, 0 need a person, 0 skipped`, exit 0.

- [ ] **Commit**

```bash
git add README.md LICENSE .gitignore stylua.toml init.lua lua/ach/init.lua lua/ach/testhook.lua scripts/check tests/run.lua tests/test_harness.lua docs/specs docs/plans
git commit --only README.md LICENSE .gitignore stylua.toml init.lua lua/ach/init.lua lua/ach/testhook.lua scripts/check tests/run.lua tests/test_harness.lua docs/specs docs/plans -m "feat(harness): add the entry point and the headless test runner"
```

Run `git add` on those paths first, since `--only` commits paths git already tracks or has been told about.

---

### Task: Options, plugin manager and lock file

**Files:**
- Create: `lua/ach/options.lua`, `lua/ach/autocmds.lua`, `lua/ach/lazy.lua`, `lua/ach/plugins/core.lua`
- Modify: `lua/ach/init.lua` (replace the whole file)
- Create on first install: `lazy-lock.json`
- Test: `tests/test_startup.lua`, `tests/test_lock.lua`

**Interfaces:**
- Consumes: `vim.g.ach_root`, `require("ach.testhook")`.
- Produces:
  - `vim.g.mapleader == " "`, `vim.g.maplocalleader == "\\"`, `vim.g.autoformat == true`.
  - lazy.nvim set up with spec `{ { import = "ach.plugins" } }`, `defaults.lazy = true`, and `lockfile = vim.g.ach_root .. "/lazy-lock.json"`. Every later task adds plugins by adding a file under `lua/ach/plugins/` that returns a list of lazy.nvim specs.
  - Mason's `bin` folder, `stdpath("data") .. "/mason/bin"`, on `PATH` from the first line of options, so a tool Mason installed is executable before mason.nvim itself loads.
  - The augroup helper `require("ach.autocmds").group(name)`, returning an augroup named `ach_<name>` created with `clear = true`.

- [ ] **Write the failing tests**

`tests/test_startup.lua`:

```lua
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
```

`tests/test_lock.lua`:

```lua
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
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_startup`
Expected: FAIL on `sets the editor options` (mapleader is nil) and on `writes the lock file into the repository` (module `lazy.core.config` not found).

- [ ] **Write the options, autocommands and plugin manager**

`lua/ach/options.lua`:

```lua
-- Editor options. Leader keys are set here, before lazy.nvim loads, so every
-- plugin's keys see them.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/options.lua.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = true
vim.g.markdown_recommended_style = 0

-- Tools Mason installs are runnable before mason.nvim itself loads.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

local o = vim.opt
o.termguicolors = true
o.background = "dark"
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 4
o.sidescrolloff = 8
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.undofile = true
o.undolevels = 10000
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.shiftround = true
o.smartindent = true
o.wrap = false
o.linebreak = true
o.mouse = "a"
o.confirm = true
o.exrc = true
o.spelllang = { "en_us" }
o.laststatus = 3
o.showmode = false
o.pumheight = 10
o.inccommand = "nosplit"
o.jumpoptions = "view"
o.timeoutlen = 300
o.updatetime = 200
o.virtualedit = "block"
o.winborder = "rounded"
o.smoothscroll = true
o.conceallevel = 2
o.grepprg = "rg --vimgrep"
o.grepformat = "%f:%l:%c:%m"
o.formatoptions = "jcroqlnt"
o.completeopt = "menu,menuone,noselect"
o.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
o.shortmess:append({ W = true, I = true, c = true, C = true })
o.fillchars = { foldopen = "", foldclose = "", fold = " ", foldsep = " ", diff = "╱", eob = " " }
o.foldlevel = 99
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldtext = ""

-- The system clipboard, except over SSH, where it would need OSC 52.
vim.schedule(function()
  if not vim.env.SSH_CONNECTION then
    o.clipboard = "unnamedplus"
  end
end)
```

`lua/ach/autocmds.lua`:

```lua
-- Autocommands that no plugin owns. Each lives in its own ach_* group so a
-- reload replaces rather than duplicates it.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/autocmds.lua.
local M = {}

function M.group(name)
  return vim.api.nvim_create_augroup("ach_" .. name, { clear = true })
end

-- Briefly highlight what was just yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = M.group("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Keep splits equal when the terminal window is resized.
vim.api.nvim_create_autocmd("VimResized", {
  group = M.group("resize_splits"),
  callback = function()
    local current = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current)
  end,
})

-- Return to the last place edited in a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = M.group("last_place"),
  callback = function(event)
    local exclude = { gitcommit = true }
    local buf = event.buf
    if exclude[vim.bo[buf].filetype] or vim.b[buf].ach_last_place then
      return
    end
    vim.b[buf].ach_last_place = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close throwaway windows with q.
vim.api.nvim_create_autocmd("FileType", {
  group = M.group("close_with_q"),
  pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth", "grug-far", "dap-float" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true, desc = "Close Window" })
  end,
})

-- Create missing parent folders when a file is first saved.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = M.group("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

return M
```

`lua/ach/lazy.lua`:

```lua
-- Installs lazy.nvim on first start, then hands it the plugin specs in
-- lua/ach/plugins/. The bootstrap is lazy.nvim's own documented snippet.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

local testing = vim.env.ACH_TEST == "1"

require("lazy").setup({
  spec = { { import = "ach.plugins" } },
  lockfile = vim.g.ach_root .. "/lazy-lock.json",
  defaults = { lazy = true, version = false },
  -- Under test a missing plugin must fail the lock test, not install itself.
  install = { missing = not testing, colorscheme = { "tokyonight-night" } },
  checker = { enabled = not testing, notify = false, frequency = 86400 },
  change_detection = { notify = false },
  rocks = { enabled = false },
  performance = {
    rtp = {
      -- lazy.nvim resets the runtime path, and under `nvim -u` the repository
      -- is not the config folder, so it is kept explicitly.
      paths = { vim.g.ach_root },
      disabled_plugins = { "gzip", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
```

`lua/ach/plugins/core.lua`:

```lua
return {
  { "folke/lazy.nvim", version = false },
}
```

`lua/ach/init.lua` (replace the whole file):

```lua
-- Loads the configuration in order. Keymaps wait for VeryLazy, after the first
-- screen has drawn.
require("ach.options")
require("ach.autocmds")
require("ach.lazy")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("ach.keymaps")
  end,
})
```

`lua/ach/keymaps.lua` is created in the keys task. Until then, create it with only its header so the require succeeds:

```lua
-- Core keys. Every key carries a description, which which-key shows and
-- tests/test_keys.lua checks.
```

- [ ] **Install the plugins and write the lock file**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: lazy.nvim clones itself, then `lazy-lock.json` appears in the repository root with one entry, `lazy.nvim`.

- [ ] **Run the tests and see them pass**

Run: `scripts/check`
Expected: every `test_harness`, `test_startup` and `test_lock` test passes, exit 0.

- [ ] **Commit**

```bash
git add lua/ach/options.lua lua/ach/autocmds.lua lua/ach/lazy.lua lua/ach/keymaps.lua lua/ach/plugins/core.lua lazy-lock.json tests/test_startup.lua tests/test_lock.lua
git commit --only lua/ach/init.lua lua/ach/options.lua lua/ach/autocmds.lua lua/ach/lazy.lua lua/ach/keymaps.lua lua/ach/plugins/core.lua lazy-lock.json tests/test_startup.lua tests/test_lock.lua -m "feat(core): add options and the lazy.nvim bootstrap with a repository lock file"
```

---

### Task: Palette and theme

**Files:**
- Create: `lua/ach/palette.lua`, `lua/ach/contrast.lua`, `lua/ach/plugins/colorscheme.lua`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Test: `tests/test_theme.lua`

**Interfaces:**
- Consumes: the lazy.nvim setup from the options task, which imports every file under `lua/ach/plugins/`.
- Produces:
  - `require("ach.palette")`, a table of `"#rrggbb"` strings: `bg`, `bg_dark`, `bg_highlight`, `bg_search`, `bg_visual`, `border`, `fg`, `fg_dark`, `fg_gutter`, `comment`, `dark3`, `banner`, and `line = { blue, green, violet, yellow, red, fg, bg, inactive_bg, semilightgray }`.
  - `require("ach.contrast")`: `luminance(hex): number` and `ratio(hex_a, hex_b): number`, the WCAG 2 contrast ratio, larger luminance over smaller.
  - The colour scheme `tokyonight-night`, loaded at startup, with the highlight groups `AchBanner`, `AchBannerShadow` and `AchBannerCaption` for the dashboard and `SnacksImageMath` for math drawn in the editor.

- [ ] **Write the failing test**

`tests/test_theme.lua`:

```lua
local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function hex(n)
  return n and ("#%06X"):format(n) or "unset"
end

local function round(x)
  return math.floor(x * 100 + 0.5) / 100
end

return {
  ["uses tokyonight night"] = function(t)
    t.eq(vim.g.colors_name, "tokyonight-night")
  end,

  ["sets the colours in the spec's tables"] = function(t)
    local p = require("ach.palette")
    local want = {
      { "Normal", "bg", p.bg },
      { "Normal", "fg", p.fg },
      { "NormalFloat", "bg", p.bg_dark },
      { "NormalFloat", "fg", p.fg },
      { "CursorLine", "bg", p.bg_highlight },
      { "Search", "bg", p.bg_search },
      { "Visual", "bg", p.bg_visual },
      { "WinSeparator", "fg", p.border },
      { "LineNr", "fg", p.fg_gutter },
      { "Comment", "fg", p.comment },
      { "LspInlayHint", "fg", p.dark3 },
      { "AchBanner", "fg", p.banner },
      { "AchBannerShadow", "fg", p.border },
      { "AchBannerCaption", "fg", p.fg_dark },
      { "SnacksImageMath", "fg", p.fg },
    }
    local wrong = {}
    for _, w in ipairs(want) do
      local got = hl(w[1])[w[2]]
      if got ~= tonumber(w[3]:sub(2), 16) then
        table.insert(wrong, ("%s %s is %s, want %s"):format(w[1], w[2], hex(got), w[3]:upper()))
      end
    end
    t.eq(wrong, {}, "highlight colours")
  end,

  ["computes WCAG 2 contrast"] = function(t)
    local ratio = require("ach.contrast").ratio
    -- The spec's "before" figures, for the colours tokyonight ships.
    t.eq(round(ratio("#565f89", "#011628")), 2.96, "old comment colour on the background")
    t.eq(round(ratio("#565f89", "#143652")), 2.02, "old comment colour on the cursor line")
    t.eq(round(ratio("#545c7e", "#011628")), 2.80, "old dark3 on the background")
    t.eq(round(ratio("#011628", "#CBE0F0")), round(ratio("#CBE0F0", "#011628")), "order does not matter")
  end,

  ["meets the spec's contrast figures, recomputed from the live colours"] = function(t)
    local ratio = require("ach.contrast").ratio
    local p = require("ach.palette")
    local function c(fg_group, bg_group)
      return round(ratio(hex(hl(fg_group).fg), hex(hl(bg_group).bg)))
    end
    t.eq(c("Comment", "Normal"), 5.00, "comments on the background")
    t.eq(c("Comment", "CursorLine"), 3.42, "comments on the cursor line")
    t.eq(c("LspInlayHint", "Normal"), 4.07, "inlay hints")
    t.eq(c("Normal", "Normal"), 13.48, "body text")
    t.eq(c("LineNr", "Normal"), 4.32, "line numbers")
    t.eq(c("Normal", "Visual"), 5.96, "text over a selection")
    t.eq(c("Normal", "Search"), 4.51, "text over a search match")
    t.eq(c("AchBanner", "Normal"), 7.27, "banner letters")
    t.eq(round(ratio(p.line.semilightgray, p.line.inactive_bg)), 6.17, "inactive status line text")
  end,
}
```

- [ ] **Run it and see it fail**

Run: `scripts/check --only test_theme`
Expected: FAIL on every test. `uses tokyonight night` reports `expected "tokyonight-night", got nil`, and the others fail with `module 'ach.palette' not found` or `module 'ach.contrast' not found`.

- [ ] **Write the palette, the contrast formula and the theme**

`lua/ach/palette.lua`:

```lua
-- Every colour the theme and the status bar use, copied from the spec's
-- tables. No other file in the theme or the status bar names a colour.
return {
  bg = "#011628",
  bg_dark = "#011423", -- floating windows, popups, sidebar, status line
  bg_highlight = "#143652", -- cursor line
  bg_search = "#0A64AC",
  bg_visual = "#275378",
  border = "#547998",
  fg = "#CBE0F0",
  fg_dark = "#B4D0E9", -- secondary and sidebar text
  fg_gutter = "#627E97", -- line numbers
  comment = "#7b84ac", -- tokyonight's #565f89, raised to 5.00:1
  dark3 = "#6c759d", -- inlay hints and quiet text, raised to 4.07:1
  banner = "#7aa2f7", -- tokyonight blue, the dashboard letters

  -- The status line palette from Josean Martinez's post.
  line = {
    blue = "#65D1FF",
    green = "#3EFFDC",
    violet = "#FF61EF",
    yellow = "#FFDA7B",
    red = "#FF4A4A",
    fg = "#c3ccdc",
    bg = "#112638",
    inactive_bg = "#2c3043",
    semilightgray = "#a9b1d6",
  },
}
```

`lua/ach/contrast.lua`:

```lua
-- WCAG 2 relative luminance and contrast ratio for "#rrggbb" colours.
local M = {}

local function channel(value)
  local c = value / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

function M.luminance(hex)
  local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

function M.ratio(a, b)
  local la, lb = M.luminance(a), M.luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

return M
```

`lua/ach/plugins/colorscheme.lua`:

```lua
-- tokyonight in its night style with the deep-navy overrides. on_colors runs
-- after tokyonight derives its panel colours, so each override below sticks.
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local p = require("ach.palette")
      return {
        style = "night",
        on_colors = function(c)
          c.bg = p.bg
          c.bg_dark = p.bg_dark
          c.bg_float = p.bg_dark
          c.bg_popup = p.bg_dark
          c.bg_sidebar = p.bg_dark
          c.bg_statusline = p.bg_dark
          c.bg_highlight = p.bg_highlight
          c.bg_search = p.bg_search
          c.bg_visual = p.bg_visual
          c.border = p.border
          c.fg = p.fg
          c.fg_dark = p.fg_dark
          c.fg_float = p.fg
          c.fg_gutter = p.fg_gutter
          c.fg_sidebar = p.fg_dark
          c.comment = p.comment
          c.dark3 = p.dark3
        end,
        on_highlights = function(hl)
          hl.AchBanner = { fg = p.banner }
          hl.AchBannerShadow = { fg = p.border }
          hl.AchBannerCaption = { fg = p.fg_dark }
          -- Math drawn by snacks.image takes the text colour, so a formula
          -- reads as part of the page.
          hl.SnacksImageMath = { fg = p.fg }
        end,
      }
    end,
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
}
```

- [ ] **Install tokyonight**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains a `tokyonight.nvim` entry.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all four `test_theme` tests pass, and every earlier test still passes. Exit 0.

- [ ] **Commit**

```bash
git add lua/ach/palette.lua lua/ach/contrast.lua lua/ach/plugins/colorscheme.lua tests/test_theme.lua
git commit --only lua/ach/palette.lua lua/ach/contrast.lua lua/ach/plugins/colorscheme.lua tests/test_theme.lua lazy-lock.json -m "feat(theme): add the navy palette over tokyonight night, with contrast checks"
```

---

### Task: Glyph sets

**Files:**
- Create: `scripts/gen-glyphs`, `scripts/gen_glyphs.lua`, `lua/ach/glyphs.lua`
- Create by running the script: `lua/ach/glyphs_forbidden.lua`, `lua/ach/glyphs_known.lua`
- Test: `tests/test_glyphs.lua`

**Interfaces:**
- Consumes: nothing beyond the harness.
- Produces:
  - `require("ach.glyphs_forbidden")`, a table from codepoint (integer) to the Nerd Font name that forbade it, or `"range"`.
  - `require("ach.glyphs_known")`, a sorted list of `{ first, last }` codepoint ranges that together hold every Nerd Font 3.5.1 glyph.
  - `require("ach.glyphs")`: `fallback: string` (U+F15B, the plain file icon), `forbidden(cp: integer): boolean`, `known(cp: integer): boolean` (a Nerd Font glyph, or plain text in U+0020 to U+00FF, or a symbol in U+2000 to U+2BFF), `offending(s: string): integer[]` (the forbidden codepoints of `s`, in order), `safe_icon(icon: string): string` (the icon, or `fallback` when any of its codepoints is forbidden).

The rule, which `scripts/gen_glyphs.lua` encodes: a glyph is forbidden when its Nerd Font name says it draws an arrow, chevron, angle bracket, caret, triangle or a play, skip or divider mark, or when its codepoint falls in a Unicode or Powerline block of such shapes, including the plain `<` and `>`. A name that says warning, exclamation or alert is exempt, because the warning sign is a triangle that points nowhere and carries meaning of its own. Run over Nerd Fonts 3.5.1, the rule forbids 1,123 codepoints.

The same script writes a second file, the known set. Nerd Fonts 3.5.1 names 10,995 glyphs on 10,617 distinct codepoints, and those codepoints sit in 27 unbroken runs, so the file is 27 ranges rather than ten thousand entries. The icon database in the next task checks every glyph it holds against this set, which is what catches a codepoint typed wrongly by one digit: such a codepoint usually lands in an unassigned gap of the private-use area and would draw as an empty box.

- [ ] **Write the failing test**

`tests/test_glyphs.lua`:

```lua
return {
  ["forbids the 1,123 codepoints from Nerd Fonts 3.5.1"] = function(t)
    t.eq(vim.tbl_count(require("ach.glyphs_forbidden")), 1123)
  end,

  ["forbids chevrons, separators, the XML icon, code brackets and arrows"] = function(t)
    local glyphs = require("ach.glyphs")
    for _, cp in ipairs({ 0xF054, 0xE0B0, 0xF05C0, 0xF121, 0x3C, 0x3E, 0x2192 }) do
      t.ok(glyphs.forbidden(cp), ("U+%04X should be forbidden"):format(cp))
    end
  end,

  ["allows the warning sign and the open folder"] = function(t)
    local glyphs = require("ach.glyphs")
    t.ok(not glyphs.forbidden(0xF071), "U+F071, the warning sign, is allowed")
    t.ok(not glyphs.forbidden(0xF07C), "U+F07C, the open folder, is allowed")
  end,

  ["lists the forbidden characters of a string"] = function(t)
    t.eq(require("ach.glyphs").offending("a > b \u{F054} \u{F07C}"), { 0x3E, 0xF054 })
  end,

  ["swaps a forbidden icon for the plain file icon"] = function(t)
    local glyphs = require("ach.glyphs")
    t.eq(glyphs.fallback, "\u{F15B}")
    t.eq(glyphs.safe_icon("\u{F05C0}"), "\u{F15B}", "the XML icon")
    t.eq(glyphs.safe_icon("\u{F07C}"), "\u{F07C}", "an allowed icon passes through")
  end,

  ["knows the 10,617 Nerd Font codepoints in 27 ranges"] = function(t)
    local ranges = require("ach.glyphs_known")
    local total = 0
    for _, range in ipairs(ranges) do
      total = total + range[2] - range[1] + 1
    end
    t.eq(#ranges, 27, "ranges")
    t.eq(total, 10617, "codepoints")
  end,

  ["knows text and symbols but not the gaps between Nerd Font ranges"] = function(t)
    local glyphs = require("ach.glyphs")
    for _, cp in ipairs({ 0x41, 0xB7, 0x2726, 0x258E, 0xF015, 0xE62B, 0xF0001, 0xF1AF0 }) do
      t.ok(glyphs.known(cp), ("U+%04X should be known"):format(cp))
    end
    for _, cp in ipairs({ 0x1F600, 0xE0C9, 0xE6BC, 0xF386, 0xF1AF1 }) do
      t.ok(not glyphs.known(cp), ("U+%04X should not be known"):format(cp))
    end
  end,
}
```

- [ ] **Run it and see it fail**

Run: `scripts/check --only test_glyphs`
Expected: FAIL on all seven, with `module 'ach.glyphs_forbidden' not found`, `module 'ach.glyphs_known' not found` or `module 'ach.glyphs' not found`.

- [ ] **Write the generator**

`scripts/gen-glyphs` (then `chmod +x scripts/gen-glyphs`):

```bash
#!/usr/bin/env bash
# Regenerate lua/ach/glyphs_forbidden.lua and lua/ach/glyphs_known.lua from the
# Nerd Fonts glyph names. Change the version below only together with the font,
# and rerun the tests, since the counts in tests/test_glyphs.lua belong to it.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
version=v3.5.1
work=$(mktemp -d "${TMPDIR:-/tmp}/ach-glyphs.XXXXXX")
trap 'rm -rf "$work"' EXIT

curl -fsSL "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/$version/glyphnames.json" -o "$work/glyphnames.json"
nvim -l "$root/scripts/gen_glyphs.lua" "$work/glyphnames.json" "$root/lua/ach/glyphs_forbidden.lua" \
  "$root/lua/ach/glyphs_known.lua"
```

`scripts/gen_glyphs.lua`:

```lua
-- Writes the set of codepoints the status bar may not show, and the ranges that
-- hold every Nerd Font codepoint.
-- Usage: nvim -l scripts/gen_glyphs.lua glyphnames.json lua/ach/glyphs_forbidden.lua lua/ach/glyphs_known.lua
local input, output, known_output = arg[1], arg[2], arg[3]
local glyphs = vim.json.decode(table.concat(vim.fn.readfile(input), "\n"))
glyphs.METADATA = nil

-- A name is forbidden when any of its words, split on - and _, is one of these.
local WORDS = {}
for word in ([[arrow arrows chevron chevrons angle angles caret triangle triangles play forward
  backward rewind greater less terminal console xml tags divider next previous]]):gmatch("%S+") do
  WORDS[word] = true
end
-- Or when it is one of these names, contains one of these, or starts with one of these.
local EXACT = { ["fa-code"] = true, ["cod-code"] = true, ["oct-code"] = true }
local CONTAINS = { "code_tags", "code_greater", "code_less", "menu_left", "menu_right", "menu_up", "menu_down",
  "skip_next", "skip_previous", "arrow", "chevron", "triangle" }
local PREFIXES = { "md-chevron_", "md-menu_", "pl-", "ple-" }
-- Unless it says one of these: the warning sign is a triangle that points nowhere.
local EXEMPT = { "exclamation", "warning", "alert" }
-- Whole blocks of arrows, angle brackets, guillemets, triangles and Powerline separators.
local RANGES = {
  { 0x2190, 0x21FF }, { 0x2794, 0x27BF }, { 0x2B00, 0x2BFF }, { 0x25B2, 0x25C5 }, { 0x276E, 0x2771 },
  { 0x27E8, 0x27EB }, { 0x2039, 0x203A }, { 0x00AB, 0x00AB }, { 0x00BB, 0x00BB }, { 0x3008, 0x3009 },
  { 0x2329, 0x232A }, { 0xE0B0, 0xE0D7 }, { 0x003C, 0x003C }, { 0x003E, 0x003E },
}

local function contains_any(name, list)
  for _, s in ipairs(list) do
    if name:find(s, 1, true) then
      return true
    end
  end
  return false
end

local function starts_any(name, list)
  for _, s in ipairs(list) do
    if vim.startswith(name, s) then
      return true
    end
  end
  return false
end

local function forbidden(name)
  if contains_any(name, EXEMPT) then
    return false
  end
  if EXACT[name] or contains_any(name, CONTAINS) or starts_any(name, PREFIXES) then
    return true
  end
  for word in name:gmatch("[^%-_]+") do
    if WORDS[word] then
      return true
    end
  end
  return false
end

local bad = {}
local names = vim.tbl_keys(glyphs)
table.sort(names)
for _, name in ipairs(names) do
  local cp = tonumber(glyphs[name].code, 16)
  if not bad[cp] and forbidden(name) then
    bad[cp] = name
  end
end
for _, range in ipairs(RANGES) do
  for cp = range[1], range[2] do
    bad[cp] = bad[cp] or "range"
  end
end

local codepoints = vim.tbl_keys(bad)
table.sort(codepoints)
local lines = {
  "-- Generated by scripts/gen-glyphs from Nerd Fonts 3.5.1 glyphnames.json. Do not edit by hand.",
  "return {",
}
for _, cp in ipairs(codepoints) do
  table.insert(lines, ("  [0x%04X] = %q,"):format(cp, bad[cp]))
end
table.insert(lines, "}")
vim.fn.writefile(lines, output)
print(("%d forbidden codepoints written to %s"):format(#codepoints, output))

-- The known set: every distinct codepoint, folded into unbroken runs.
local seen = {}
for _, glyph in pairs(glyphs) do
  seen[tonumber(glyph.code, 16)] = true
end
local all = vim.tbl_keys(seen)
table.sort(all)
local ranges = {}
for _, cp in ipairs(all) do
  local last = ranges[#ranges]
  if last and cp == last[2] + 1 then
    last[2] = cp
  else
    table.insert(ranges, { cp, cp })
  end
end
local known = {
  "-- Generated by scripts/gen-glyphs from Nerd Fonts 3.5.1 glyphnames.json. Do not edit by hand.",
  "-- Every Nerd Font codepoint, as { first, last } ranges.",
  "return {",
}
for _, range in ipairs(ranges) do
  table.insert(known, ("  { 0x%04X, 0x%04X },"):format(range[1], range[2]))
end
table.insert(known, "}")
vim.fn.writefile(known, known_output)
print(("%d known codepoints in %d ranges written to %s"):format(#all, #ranges, known_output))
```

- [ ] **Generate the set**

Run: `scripts/gen-glyphs`
Expected: two lines, `1123 forbidden codepoints written to <repository>/lua/ach/glyphs_forbidden.lua` and `10617 known codepoints in 27 ranges written to <repository>/lua/ach/glyphs_known.lua`. If either count differs, stop: the download is not version 3.5.1, or the rule above was copied wrongly.

- [ ] **Write the checker**

`lua/ach/glyphs.lua`:

```lua
-- The status bar's glyph rule. lua/ach/glyphs_forbidden.lua, generated by
-- scripts/gen-glyphs, lists every codepoint that draws an angle bracket,
-- chevron, arrowhead or triangle. Nothing in that list may reach the bar.
local forbidden = require("ach.glyphs_forbidden")
local known = require("ach.glyphs_known")

local M = {}

-- The plain file icon, nf-fa-file, shown when a file type's own icon is forbidden.
M.fallback = "\u{F15B}"

function M.forbidden(cp)
  return forbidden[cp] ~= nil
end

-- True for a codepoint the font draws: a Nerd Font glyph, plain Latin text, or
-- the punctuation, block and symbol ranges every monospace font carries.
function M.known(cp)
  if (cp >= 0x20 and cp <= 0xFF) or (cp >= 0x2000 and cp <= 0x2BFF) then
    return true
  end
  for _, range in ipairs(known) do
    if cp >= range[1] and cp <= range[2] then
      return true
    end
  end
  return false
end

function M.offending(s)
  local out = {}
  for _, cp in ipairs(vim.fn.str2list(s, true)) do
    if forbidden[cp] then
      table.insert(out, cp)
    end
  end
  return out
end

function M.safe_icon(icon)
  return #M.offending(icon) == 0 and icon or M.fallback
end

return M
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all seven `test_glyphs` tests pass, along with every earlier test. Exit 0.

- [ ] **Commit**

```bash
git add scripts/gen-glyphs scripts/gen_glyphs.lua lua/ach/glyphs.lua lua/ach/glyphs_forbidden.lua lua/ach/glyphs_known.lua tests/test_glyphs.lua
git commit --only scripts/gen-glyphs scripts/gen_glyphs.lua lua/ach/glyphs.lua lua/ach/glyphs_forbidden.lua lua/ach/glyphs_known.lua tests/test_glyphs.lua -m "feat(statusline): add the forbidden and known glyph sets generated from Nerd Fonts 3.5.1"
```

---

### Task: Icon database

**Files:**
- Create: `lua/ach/icons.lua`
- Modify: `lua/ach/lazy.lua` (one `ui` line)
- Test: `tests/test_icons.lua`

**Interfaces:**
- Consumes: `require("ach.glyphs")` with `known(cp)` and `offending(s)` from the glyph task; `lua/ach/lazy.lua` from the options task.
- Produces:
  - `require("ach.icons")`, which requires nothing, so any file may load it at any moment, `lazy.lua` included.
  - Thirty named glyph tables, `M.actions` through `M.status`, listed in order in `M.vocabulary: string[]`, each mapping a name to one glyph. A reference is the string `"category.name"`, such as `"git.branch"`.
  - `M.colors: string[]`, the nine colours which-key and mini.icons share: azure, blue, cyan, green, grey, orange, purple, red and yellow.
  - `M.keys: table<desc, {ref, colour}>`, `M.groups: table<name, {ref, colour}>`, `M.toggles: table<id, ref>`, `M.keywords: {pattern, ref, colour}[]`, and `M.filetypes`, `M.extensions` and `M.filenames`, each `table<name, {ref, colour}>`.
  - `M.lazy_list: string[]`, lazy.nvim's four list bullets.
  - `M.get(ref): string|nil`; `M.key(desc)` and `M.group(name)`, each `{icon: string, color: string}|nil`; `M.which_key_rules(): {pattern, icon, color}[]`; `M.toggle(toggle): toggle`; `M.mini(): {filetype, extension, file}`; `M.spaced(t): t`; `M.lazy_ui(): table`; `M.todo_keywords(): table`.
  - The rule every later task follows. A key it sets gets a line in `M.keys`, a which-key group a line in `M.groups`, and a Snacks toggle its id in `M.toggles`, each written above that table's marker line, such as `-- Keys added by later tasks go above this line.` The Keys task's tests fail on any key, group or toggle without one, so the rule enforces itself.

LazyVim keeps its icons in one table in its configuration, and which-key guesses each key's icon from words in its description. This task does the same thing, larger and stricter. The file names 849 glyphs in 30 tables, so every icon the configuration draws is chosen once and reused by name. It also lists every description a key can carry in this plan, 347 of them: the keys this plan sets, the keys Neovim sets by itself, and the motions, operators and window commands which-key describes on its own. Each has an icon picked for it and a colour. Guessing survives only as a safety net, for a key some plugin adds after an update, through 84 keyword patterns tried in order, with no catch-all at the end.

Here is how which-key uses the file. To draw a key, which-key lower-cases its description and tries the `icons.rules` it was given, in order, before its own built-in rules; the first rule whose pattern matches wins. `M.which_key_rules()` puts one exact rule per listed description first, anchored at both ends, so a listed key always gets its own icon, and the keyword patterns after them. Because the match is made in lower case, two descriptions that differ only in case must share an icon and colour, and a test checks that they do.

Every glyph is written as an escape such as `\u{F0415}`, with its Nerd Font name in a comment beside it, or is a plain Unicode character where one already looks right, such as the bullet at U+25CF. Escapes keep the file readable in any editor, and they turn each icon into a number a test can check against the known set from the glyph task. That check is what catches a codepoint mistyped by one digit, which would otherwise draw as an empty box.

- [ ] **Write the failing test**

`tests/test_icons.lua`:

```lua
local I = require("ach.icons")
local glyphs = require("ach.glyphs")

-- Every reference the database holds, with the colour beside it and where it sits.
local function references()
  local out = {}
  local function add(where, ref, colour)
    out[#out + 1] = { where = where, ref = ref, colour = colour }
  end
  for desc, e in pairs(I.keys) do
    add("keys[" .. desc .. "]", e[1], e[2])
  end
  for name, e in pairs(I.groups) do
    add("groups[" .. name .. "]", e[1], e[2])
  end
  for id, ref in pairs(I.toggles) do
    add("toggles[" .. id .. "]", ref, "green")
  end
  for i, e in ipairs(I.keywords) do
    add("keywords[" .. i .. "]", e[2], e[3])
  end
  for _, kind in ipairs({ "filetypes", "extensions", "filenames" }) do
    for name, e in pairs(I[kind]) do
      add(kind .. "[" .. name .. "]", e[1], e[2])
    end
  end
  return out
end

-- The first rule whose pattern finds the lower-cased description: which-key's own test.
local function first_rule(rules, desc)
  local lower = desc:lower()
  for _, rule in ipairs(rules) do
    if lower:find(rule.pattern) then
      return rule
    end
  end
end

-- The reference of the first keyword pattern that finds the description, or false.
local function keyword(desc)
  for _, rule in ipairs(I.keywords) do
    if desc:lower():find(rule[1]) then
      return rule[2]
    end
  end
  return false
end

return {
  ["every glyph is one character the font draws"] = function(t)
    local bad = {}
    local function check(where, glyph)
      local cps = type(glyph) == "string" and vim.fn.str2list(glyph, true) or {}
      if #cps ~= 1 or not glyphs.known(cps[1]) then
        bad[#bad + 1] = where
      end
    end
    for _, category in ipairs(I.vocabulary) do
      for name, glyph in pairs(I[category]) do
        check(category .. "." .. name, glyph)
      end
    end
    for i, glyph in ipairs(I.lazy_list) do
      check("lazy_list[" .. i .. "]", glyph)
    end
    table.sort(bad)
    t.eq(bad, {}, "glyphs the font does not draw")
  end,

  ["holds at least the foundation's 849 glyphs, 347 keys and 84 keywords"] = function(t)
    local total = 0
    for _, category in ipairs(I.vocabulary) do
      t.eq(type(I[category]), "table", "the table M." .. category)
      total = total + vim.tbl_count(I[category])
    end
    t.ok(#I.vocabulary >= 30, ("%d tables, at least 30 expected"):format(#I.vocabulary))
    t.ok(total >= 849, ("%d glyphs, at least 849 expected"):format(total))
    t.ok(vim.tbl_count(I.keys) >= 347, ("%d keys, at least 347 expected"):format(vim.tbl_count(I.keys)))
    t.ok(vim.tbl_count(I.groups) >= 18, ("%d groups, at least 18 expected"):format(vim.tbl_count(I.groups)))
    t.ok(vim.tbl_count(I.toggles) >= 19, ("%d toggles, at least 19 expected"):format(vim.tbl_count(I.toggles)))
    t.ok(#I.keywords >= 84, ("%d keywords, at least 84 expected"):format(#I.keywords))
  end,

  ["every reference names a glyph and every colour is one which-key draws"] = function(t)
    local colours, bad = {}, {}
    for _, c in ipairs(I.colors) do
      colours[c] = true
    end
    for _, r in ipairs(references()) do
      if not I.get(r.ref) then
        bad[#bad + 1] = r.where .. " names " .. tostring(r.ref)
      elseif not colours[r.colour] then
        bad[#bad + 1] = r.where .. " has the colour " .. tostring(r.colour)
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "broken references")
  end,

  ["descriptions that differ only in case share an icon and colour"] = function(t)
    local seen, bad = {}, {}
    local descs = vim.tbl_keys(I.keys)
    table.sort(descs)
    for _, desc in ipairs(descs) do
      local lower, icon = desc:lower(), I.key(desc)
      local other = seen[lower]
      if other and (other.icon ~= icon.icon or other.color ~= icon.color) then
        bad[#bad + 1] = desc
      end
      seen[lower] = other or icon
    end
    t.eq(bad, {}, "descriptions which-key cannot tell apart")
  end,

  ["which-key's first matching rule gives each listed key its own icon"] = function(t)
    local rules, bad = I.which_key_rules(), {}
    for desc in pairs(I.keys) do
      local want, got = I.key(desc), first_rule(rules, desc)
      if not got or got.icon ~= want.icon or got.color ~= want.color then
        bad[#bad + 1] = desc
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "keys that would draw another icon")
  end,

  ["every keyword is a valid pattern and routes the probe descriptions"] = function(t)
    for i, rule in ipairs(I.keywords) do
      t.ok(pcall(string.find, "", rule[1]), ("keywords[%d] %q is a valid Lua pattern"):format(i, rule[1]))
    end
    local probes = {
      ["Git Blame Line"] = "git.blame",
      ["Lazygit (Root Dir)"] = "git.lazygit",
      ["Format Injected Langs"] = "code.format",
      ["Run Nearest Test"] = "code.test",
      ["Toggle Breakpoint"] = "dap.Breakpoint",
      ["Mason"] = "mason.mason",
      ["Rename File"] = "code.rename",
      ["Goto Definition"] = "code.definition",
      ["Next Hunk"] = "git.hunk",
      ["Claude Code: Send Selection"] = "claude.claude",
      ["Markdown Preview"] = "ui.preview",
      ["Open Tab"] = "tabs.tab",
      ["Table of Contents"] = false,
      ["Run Last"] = "actions.run",
      ["Toggle AI"] = "claude.ai",
    }
    local wrong = {}
    for desc, want in pairs(probes) do
      local got = keyword(desc)
      if got ~= want then
        wrong[#wrong + 1] = ("%s gave %s, wanted %s"):format(desc, tostring(got), tostring(want))
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "keyword routing")
  end,

  ["the status icons contain no forbidden glyph"] = function(t)
    local bad = {}
    for name, glyph in pairs(I.status) do
      if #glyphs.offending(glyph) > 0 then
        bad[#bad + 1] = name
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "status icons the bar may not show")
  end,

  ["lazy.nvim draws the database's icons"] = function(t)
    local icons = require("lazy.core.config").options.ui.icons
    t.eq(icons.plugin, I.lazy.plugin .. " ", "the plugin icon")
    t.eq(icons.loaded, I.lazy.loaded, "the loaded marker")
    t.eq(icons.list, I.lazy_list, "the list bullets")
  end,

  ["a toggle takes its icon from the database, green when on and grey when off"] = function(t)
    local toggle = I.toggle({ opts = { id = "spell" } })
    t.eq(toggle.opts.icon, I.spell.spell, "the icon")
    t.eq(toggle.opts.color, { enabled = "green", disabled = "grey" }, "the colours")
    local other = I.toggle({ opts = { id = "not_in_the_database" } })
    t.eq(other.opts.icon, nil, "a toggle the database does not list keeps its own icon")
  end,

  ["the helpers return the shapes their plugins expect"] = function(t)
    t.eq(I.spaced({ a = "x" }), { a = "x " }, "spaced")
    t.eq(I.todo_keywords().TODO, { icon = I.todo.TODO .. " " }, "todo-comments")
    local mini = I.mini()
    t.eq(mini.filetype.verilog, { glyph = I.hardware.gate_and, hl = "MiniIconsGreen" }, "mini.icons by file type")
    t.eq(mini.extension.sv, { glyph = I.hardware.ic, hl = "MiniIconsGreen" }, "mini.icons by extension")
    t.eq(mini.file["lazy-lock.json"], { glyph = I.lazy.lazy, hl = "MiniIconsBlue" }, "mini.icons by file name")
  end,
}
```

- [ ] **Run it and see it fail**

Run: `scripts/check --only test_icons`
Expected: FAIL, `test_icons` does not load, with `module 'ach.icons' not found`.

- [ ] **Write the database**

`lua/ach/icons.lua` is long because it is a list. Copy it whole: the counting test fails on a dropped line, and the reference test on a dropped table.

```lua
-- The icon database: every glyph ACH-NEOVIM draws, by name, and the tables that
-- give each key, which-key group, toggle and file type its icon. A glyph is a
-- Nerd Fonts 3.5.1 glyph, named in the comment beside it, or a plain Unicode
-- character where one already looks right. tests/test_icons.lua checks every
-- entry, so an icon added by hand is held to the same rules as these.
local M = {}

-- The nine colours which-key and mini.icons both draw in.
M.colors = { "azure", "blue", "cyan", "green", "grey", "orange", "purple", "red", "yellow" }

-- The named glyph tables, in the order this file defines them. A reference
-- such as "git.branch" names one glyph in one of them.
M.vocabulary = {
  "actions", "files", "buffers", "nav", "windows", "tabs", "edit", "code", "search",
  "lists", "diagnostics", "git", "gitsigns", "fold", "spell", "textobj", "session",
  "multicursor", "terminal", "ui", "claude", "lazy", "mason", "todo", "dap",
  "hardware", "lang", "kinds", "dashboard", "status",
}

-- Verbs: what a key does.
M.actions = {
  add = "\u{F0415}", -- md-plus
  add_box = "\u{F0416}", -- md-plus_box
  add_circle = "\u{F0417}", -- md-plus_circle
  remove = "\u{F0374}", -- md-minus
  remove_box = "\u{F0375}", -- md-minus_box
  remove_circle = "\u{F0376}", -- md-minus_circle
  save = "\u{F0193}", -- md-content_save
  save_all = "\u{F0194}", -- md-content_save_all
  save_edit = "\u{F0CFB}", -- md-content_save_edit
  save_off = "\u{F1643}", -- md-content_save_off
  open = "\u{F03CB}", -- md-open_in_app
  open_external = "\u{F03CC}", -- md-open_in_new
  close = "\u{F0156}", -- md-close
  close_box = "\u{F0157}", -- md-close_box
  close_all = "\u{F0C5D}", -- md-close_box_multiple
  delete = "\u{F01B4}", -- md-delete
  delete_forever = "\u{F05E8}", -- md-delete_forever
  delete_sweep = "\u{F05E9}", -- md-delete_sweep
  eraser = "\u{F01FE}", -- md-eraser
  copy = "\u{F018F}", -- md-content_copy
  paste = "\u{F0192}", -- md-content_paste
  cut = "\u{F0190}", -- md-content_cut
  duplicate = "\u{F0191}", -- md-content_duplicate
  undo = "\u{F054C}", -- md-undo
  redo = "\u{F044E}", -- md-redo
  undo_variant = "\u{F054D}", -- md-undo_variant
  edit = "\u{F03EB}", -- md-pencil
  edit_box = "\u{F03EC}", -- md-pencil_box
  edit_outline = "\u{F0CB6}", -- md-pencil_outline
  rename = "\u{F0455}", -- md-rename_box
  refresh = "\u{F0450}", -- md-refresh
  reload = "\u{F0453}", -- md-reload
  sync = "\u{F04E6}", -- md-sync
  run = "\u{F040A}", -- md-play
  run_circle = "\u{F040C}", -- md-play_circle
  stop = "\u{F04DB}", -- md-stop
  stop_circle = "\u{F0666}", -- md-stop_circle
  pause = "\u{F03E4}", -- md-pause
  pause_circle = "\u{F03E5}", -- md-pause_circle
  restart = "\u{F0709}", -- md-restart
  build = "\u{F08EA}", -- md-hammer
  wrench = "\u{F05B7}", -- md-wrench
  tools = "\u{F1064}", -- md-tools
  install = "\u{F03D4}", -- md-package_down
  update = "\u{F06B0}", -- md-update
  upgrade = "\u{F005F}", -- md-arrow_up_bold_circle
  clean = "\u{F00E2}", -- md-broom
  sort = "\u{F04BA}", -- md-sort
  sort_ascending = "\u{F04BC}", -- md-sort_ascending
  sort_descending = "\u{F04BD}", -- md-sort_descending
  sort_alphabetical = "\u{F05BD}", -- md-sort_alphabetical_ascending
  filter = "\u{F0232}", -- md-filter
  filter_off = "\u{F14EF}", -- md-filter_off
  swap = "\u{F04E1}", -- md-swap_horizontal
  swap_vertical = "\u{F04E2}", -- md-swap_vertical
  move = "\u{F01BE}", -- md-cursor_move
  drag = "\u{F01DB}", -- md-drag
  split = "\u{F00FB}", -- md-call_split
  merge = "\u{F00F8}", -- md-call_merge
  expand = "\u{F004C}", -- md-arrow_expand_all
  collapse = "\u{F0044}", -- md-arrow_collapse_all
  pin = "\u{F0403}", -- md-pin
  pin_outline = "\u{F0931}", -- md-pin_outline
  unpin = "\u{F0404}", -- md-pin_off
  star = "\u{F04CE}", -- md-star
  star_outline = "\u{F04D2}", -- md-star_outline
  bookmark = "\u{F00C0}", -- md-bookmark
  bookmark_add = "\u{F00C5}", -- md-bookmark_plus
  link = "\u{F0337}", -- md-link
  unlink = "\u{F0338}", -- md-link_off
  share = "\u{F0497}", -- md-share_variant
  download = "\u{F01DA}", -- md-download
  upload = "\u{F0552}", -- md-upload
  export = "\u{F0207}", -- md-export
  import = "\u{F02FA}", -- md-import
  lock = "\u{F033E}", -- md-lock
  unlock = "\u{F033F}", -- md-lock_open
  check = "\u{F012C}", -- md-check
  check_all = "\u{F012D}", -- md-check_all
  check_bold = "\u{F0E1E}", -- md-check_bold
  check_circle = "\u{F05E0}", -- md-check_circle
  check_circle_outline = "\u{F05E1}", -- md-check_circle_outline
  cancel = "\u{F0159}", -- md-close_circle
  cancel_outline = "\u{F015A}", -- md-close_circle_outline
  replay = "\u{F0459}", -- md-replay
  history = "\u{F02DA}", -- md-history
  select = "\u{F0485}", -- md-select
  select_all = "\u{F0486}", -- md-select_all
  select_drag = "\u{F0A6C}", -- md-select_drag
  wrap = "\u{F05B6}", -- md-wrap
  wrap_off = "\u{F0BDF}", -- md-wrap_disabled
  align_justify = "\u{F0261}", -- md-format_align_justify
  align_left = "\u{F0262}", -- md-format_align_left
  align_right = "\u{F0263}", -- md-format_align_right
  align_center = "\u{F0260}", -- md-format_align_center
  zoom_in = "\u{F034B}", -- md-magnify_plus
  zoom_out = "\u{F034A}", -- md-magnify_minus
  fullscreen = "\u{F0293}", -- md-fullscreen
  fullscreen_exit = "\u{F0294}", -- md-fullscreen_exit
  maximize = "\u{F05AF}", -- md-window_maximize
  minimize = "\u{F05B0}", -- md-window_minimize
  restore = "\u{F05B2}", -- md-window_restore
  hide = "\u{F0209}", -- md-eye_off
  show = "\u{F0208}", -- md-eye
  quit = "\u{F0A48}", -- md-exit_run
  exit = "\u{F0206}", -- md-exit_to_app
  power = "\u{F0425}", -- md-power
  login = "\u{F0342}", -- md-login
  logout = "\u{F0343}", -- md-logout
  settings = "\u{F0493}", -- md-cog
  settings_box = "\u{F0494}", -- md-cog_box
  tune = "\u{F062E}", -- md-tune
  inspect = "\u{F1276}", -- md-magnify_scan
  measure = "\u{F046D}", -- md-ruler
  calculate = "\u{F00EC}", -- md-calculator
  translate = "\u{F05CA}", -- md-translate
  transfer = "\u{F1065}", -- md-transfer
  fix = "\u{F0068}", -- md-auto_fix
  magic = "\u{F1844}", -- md-magic_staff
  test = "\u{F0668}", -- md-test_tube
  flask = "\u{F0093}", -- md-flask
  profile = "\u{F04C5}", -- md-speedometer
  benchmark = "\u{F051B}", -- md-timer_outline
  deploy = "\u{F14DE}", -- md-rocket_launch
  publish = "\u{F06A7}", -- md-publish
  record = "\u{F044B}", -- md-record_rec
  ["repeat"] = "\u{F0456}", -- md-repeat
  repeat_once = "\u{F0458}", -- md-repeat_once
  shuffle = "\u{F049D}", -- md-shuffle
  send = "\u{F048A}", -- md-send
  print = "\u{F042A}", -- md-printer
  attach = "\u{F03E2}", -- md-paperclip
  archive = "\u{F003C}", -- md-archive
  recycle = "\u{F044C}", -- md-recycle
  trash = "\u{F0A79}", -- md-trash_can
  backup = "\u{F006F}", -- md-backup_restore
  apply = "\u{F0791}", -- md-check_decagram
  increase = "\u{F0419}", -- md-plus_circle_outline
  decrease = "\u{F0377}", -- md-minus_circle_outline
  hand = "\u{F0E47}", -- md-hand_back_right
  gesture = "\u{F0741}", -- md-gesture_tap
}

-- Files, folders and the places they live.
M.files = {
  file = "\u{F0214}", -- md-file
  file_outline = "\u{F0224}", -- md-file_outline
  document = "\u{F0219}", -- md-file_document
  document_outline = "\u{F09EE}", -- md-file_document_outline
  code = "\u{F022E}", -- md-file_code
  find = "\u{F021E}", -- md-file_find
  search = "\u{F0C7C}", -- md-file_search
  tree = "\u{F0645}", -- md-file_tree
  tree_outline = "\u{F13D2}", -- md-file_tree_outline
  new = "\u{F0752}", -- md-file_plus
  move = "\u{F0AB9}", -- md-file_move
  replace = "\u{F0B32}", -- md-file_replace
  compare = "\u{F08AA}", -- md-file_compare
  restore = "\u{F0670}", -- md-file_restore
  lock = "\u{F0221}", -- md-file_lock
  hidden = "\u{F0613}", -- md-file_hidden
  file_link = "\u{F1177}", -- md-file_link
  cog = "\u{F107B}", -- md-file_cog
  check = "\u{F0216}", -- md-file_check
  edit = "\u{F11E7}", -- md-file_edit
  star = "\u{F103A}", -- md-file_star
  eye = "\u{F0DCA}", -- md-file_eye
  recent = "\u{F12E1}", -- md-file_clock
  export = "\u{F021D}", -- md-file_export
  import = "\u{F0220}", -- md-file_import
  remove = "\u{F0B98}", -- md-file_remove
  question = "\u{F086F}", -- md-file_question
  chart = "\u{F0215}", -- md-file_chart
  table = "\u{F0C7E}", -- md-file_table
  image = "\u{F021F}", -- md-file_image
  pdf = "\u{F0226}", -- md-file_pdf_box
  music = "\u{F0223}", -- md-file_music
  video = "\u{F022B}", -- md-file_video
  word = "\u{F022D}", -- md-file_word_box
  excel = "\u{F021C}", -- md-file_excel_box
  powerpoint = "\u{F0228}", -- md-file_powerpoint_box
  cad = "\u{F0EEB}", -- md-file_cad
  certificate = "\u{F1186}", -- md-file_certificate
  key = "\u{F1184}", -- md-file_key
  download = "\u{F0965}", -- md-file_download
  upload = "\u{F0A4D}", -- md-file_upload
  multiple = "\u{F0222}", -- md-file_multiple
  undo = "\u{F08DC}", -- md-file_undo
  sync = "\u{F1216}", -- md-file_sync
  alert = "\u{F0A4B}", -- md-file_alert
  copy_path = "\u{F1265}", -- md-clipboard_file
  folder = "\u{F024B}", -- md-folder
  folder_open = "\u{F0770}", -- md-folder_open
  folder_outline = "\u{F0256}", -- md-folder_outline
  folder_open_outline = "\u{F0DCF}", -- md-folder_open_outline
  folder_search = "\u{F0968}", -- md-folder_search
  folder_star = "\u{F069D}", -- md-folder_star
  folder_cog = "\u{F107F}", -- md-folder_cog
  folder_home = "\u{F10B5}", -- md-folder_home
  folder_clock = "\u{F0ABA}", -- md-folder_clock
  folder_lock = "\u{F0250}", -- md-folder_lock
  folder_network = "\u{F0870}", -- md-folder_network
  folder_sync = "\u{F0D0B}", -- md-folder_sync
  folder_zip = "\u{F06EB}", -- md-folder_zip
  folder_text = "\u{F0C82}", -- md-folder_text
  folder_wrench = "\u{F19FC}", -- md-folder_wrench
  folder_account = "\u{F024C}", -- md-folder_account
  folder_multiple = "\u{F0253}", -- md-folder_multiple
  folder_move = "\u{F0252}", -- md-folder_move
  folder_remove = "\u{F0258}", -- md-folder_remove
  folder_edit = "\u{F08DE}", -- md-folder_edit
  folder_plus = "\u{F0257}", -- md-folder_plus
  home = "\u{F02DC}", -- md-home
  database = "\u{F01BC}", -- md-database
  zip = "\u{F05C4}", -- md-zip_box
  package = "\u{F03D3}", -- md-package
  cloud = "\u{F015F}", -- md-cloud
  cloud_upload = "\u{F0167}", -- md-cloud_upload
  cloud_download = "\u{F0162}", -- md-cloud_download
  harddisk = "\u{F02CA}", -- md-harddisk
  server = "\u{F048B}", -- md-server
  library = "\u{F0331}", -- md-library
  book = "\u{F00BA}", -- md-book
  book_open = "\u{F05DA}", -- md-book_open_page_variant
  notebook = "\u{F082E}", -- md-notebook
  note = "\u{F039A}", -- md-note
  note_text = "\u{F039E}", -- md-note_text
  note_edit = "\u{F1781}", -- md-note_edit
  clipboard = "\u{F0147}", -- md-clipboard
  clipboard_text = "\u{F014D}", -- md-clipboard_text
  clipboard_list = "\u{F10D4}", -- md-clipboard_list
  clipboard_check = "\u{F014E}", -- md-clipboard_check
  clipboard_multiple = "\u{F1267}", -- md-clipboard_multiple
  scratch = "\u{F14E7}", -- md-notebook_edit
}

-- Open buffers.
M.buffers = {
  buffer = "\u{F09EE}", -- md-file_document_outline
  list = "\u{F1517}", -- md-file_document_multiple
  alternate = "\u{F0FB4}", -- md-file_swap
  delete = "\u{F0B98}", -- md-file_remove
  delete_others = "\u{F1037}", -- md-file_remove_outline
  delete_window = "\u{F0158}", -- md-close_box_outline
  new = "\u{F1A9D}", -- md-file_document_plus
  edit = "\u{F0DC8}", -- md-file_document_edit
  alert = "\u{F1A97}", -- md-file_document_alert
  check = "\u{F1A99}", -- md-file_document_check
}

-- Cursor motions, jumps and scrolling.
M.nav = {
  left = "\u{F004D}", -- md-arrow_left
  right = "\u{F0054}", -- md-arrow_right
  up = "\u{F005D}", -- md-arrow_up
  down = "\u{F0045}", -- md-arrow_down
  left_bold = "\u{F0731}", -- md-arrow_left_bold
  right_bold = "\u{F0734}", -- md-arrow_right_bold
  up_bold = "\u{F0737}", -- md-arrow_up_bold
  down_bold = "\u{F072E}", -- md-arrow_down_bold
  next = "\u{F0057}", -- md-arrow_right_bold_circle_outline
  prev = "\u{F0050}", -- md-arrow_left_bold_circle_outline
  first_line = "\u{F0795}", -- md-arrow_collapse_up
  last_line = "\u{F0792}", -- md-arrow_collapse_down
  line_start = "\u{F061F}", -- md-format_horizontal_align_left
  line_end = "\u{F0620}", -- md-format_horizontal_align_right
  line_first_char = "\u{F0262}", -- md-format_align_left
  window_top = "\u{F0755}", -- md-format_align_top
  window_middle = "\u{F0754}", -- md-format_align_middle
  window_bottom = "\u{F0753}", -- md-format_align_bottom
  view_top = "\u{F0623}", -- md-format_vertical_align_top
  view_center = "\u{F0622}", -- md-format_vertical_align_center
  view_bottom = "\u{F0621}", -- md-format_vertical_align_bottom
  view_left = "\u{F061F}", -- md-format_horizontal_align_left
  view_right = "\u{F0620}", -- md-format_horizontal_align_right
  pan_left = "\u{F0BB9}", -- md-pan_left
  pan_right = "\u{F0BBA}", -- md-pan_right
  page_up = "\u{F013F}", -- md-chevron_double_up
  page_down = "\u{F013C}", -- md-chevron_double_down
  word = "\u{F0FBA}", -- md-format_letter_starts_with
  word_end = "\u{F0FB8}", -- md-format_letter_ends_with
  char = "\u{F04FE}", -- md-target
  char_repeat = "\u{F0547}", -- md-repeat_variant
  paragraph = "\u{F027D}", -- md-format_paragraph
  match = "\u{F016A}", -- md-code_brackets
  paren = "\u{F0172}", -- md-code_parentheses
  brace = "\u{F0169}", -- md-code_braces
  angle = "\u{F016E}", -- md-code_less_than
  changes = "\u{F0DC9}", -- md-file_document_edit_outline
  last_insert = "\u{F0CB6}", -- md-pencil_outline
  jump = "\u{F01B7}", -- md-debug_step_over
  target = "\u{F04FE}", -- md-target
  crosshairs = "\u{F01A4}", -- md-crosshairs_gps
  map_marker = "\u{F034E}", -- md-map_marker
  compass = "\u{F018B}", -- md-compass
  flash = "\u{F0241}", -- md-flash
  flash_auto = "\u{F0242}", -- md-flash_auto
  flash_select = "\u{F0F82}", -- md-select_group
  flash_remote = "\u{F0454}", -- md-remote
  flash_search = "\u{F1A7E}", -- md-text_search_variant
  grow = "\u{F0616}", -- md-arrow_expand
  anchor = "\u{F0031}", -- md-anchor
  ["goto"] = "\u{F08C9}", -- md-bullseye_arrow
}

-- Window layout.
M.windows = {
  window = "\u{F10AC}", -- md-dock_window
  go_left = "\u{F0733}", -- md-arrow_left_bold_box_outline
  go_down = "\u{F0730}", -- md-arrow_down_bold_box_outline
  go_up = "\u{F0739}", -- md-arrow_up_bold_box_outline
  go_right = "\u{F0736}", -- md-arrow_right_bold_box_outline
  far_left = "\u{F10AA}", -- md-dock_left
  far_bottom = "\u{F10A9}", -- md-dock_bottom
  far_top = "\u{F1513}", -- md-dock_top
  far_right = "\u{F10AB}", -- md-dock_right
  height_inc = "\u{F084F}", -- md-arrow_expand_vertical
  height_dec = "\u{F084D}", -- md-arrow_collapse_vertical
  width_inc = "\u{F084E}", -- md-arrow_expand_horizontal
  width_dec = "\u{F084C}", -- md-arrow_collapse_horizontal
  max_height = "\u{F0E7A}", -- md-arrow_up_down_bold
  max_width = "\u{F0E74}", -- md-arrow_left_right_bold
  equalize = "\u{F01FD}", -- md-equal_box
  split_below = "\u{F0BCB}", -- md-view_split_horizontal
  split_right = "\u{F0BCC}", -- md-view_split_vertical
  close = "\u{F05AD}", -- md-window_close
  only = "\u{F05AF}", -- md-window_maximize
  swap = "\u{F0BCD}", -- md-swap_horizontal_bold
  switch = "\u{F08C1}", -- md-swap_horizontal_variant
  to_tab = "\u{F03CC}", -- md-open_in_new
  hydra = "\u{F0931}", -- md-pin_outline
  zoom = "\u{F0293}", -- md-fullscreen
  dock = "\u{F06FD}", -- md-page_layout_sidebar_left
  dock_pick = "\u{F0843}", -- md-view_dashboard_variant
  layout = "\u{F0574}", -- md-view_quilt
  grid = "\u{F0570}", -- md-view_grid
}

-- Tab pages.
M.tabs = {
  tab = "\u{F04E9}", -- md-tab
  new = "\u{F075C}", -- md-tab_plus
  next = "\u{F0BB0}", -- md-page_next
  prev = "\u{F0BB2}", -- md-page_previous
  first = "\u{F0600}", -- md-page_first
  last = "\u{F0601}", -- md-page_last
  close = "\u{F0B4C}", -- md-tab_remove
  close_others = "\u{F0B4B}", -- md-tab_minus
  search = "\u{F199E}", -- md-tab_search
  unselected = "\u{F04EA}", -- md-tab_unselected
}

-- Operators and text edits.
M.edit = {
  change = "\u{F03EB}", -- md-pencil
  delete = "\u{F01B4}", -- md-delete
  yank = "\u{F018F}", -- md-content_copy
  replace = "\u{F06D4}", -- md-find_replace
  format = "\u{F0261}", -- md-format_align_justify
  indent = "\u{F0276}", -- md-format_indent_increase
  outdent = "\u{F0275}", -- md-format_indent_decrease
  upper = "\u{F0B36}", -- md-format_letter_case_upper
  lower = "\u{F0B35}", -- md-format_letter_case_lower
  case = "\u{F0B34}", -- md-format_letter_case
  visual = "\u{F0485}", -- md-select
  visual_line = "\u{F09AA}", -- md-text_long
  visual_last = "\u{F0FDA}", -- md-select_place
  move_up = "\u{F0737}", -- md-arrow_up_bold
  move_down = "\u{F072E}", -- md-arrow_down_bold
  line_above = "\u{F04F4}", -- md-table_row_plus_before
  line_below = "\u{F04F3}", -- md-table_row_plus_after
  delete_line = "\u{F006E}", -- md-backspace
  delete_word = "\u{F0B5C}", -- md-backspace_outline
  repeat_sub = "\u{F0456}", -- md-repeat
  macro = "\u{F044B}", -- md-record_rec
  macro_repeat = "\u{F0458}", -- md-repeat_once
  undo_tree = "\u{F0531}", -- md-tree
  escape = "\u{F12B7}", -- md-keyboard_esc
  join = "\u{F00F8}", -- md-call_merge
  sort = "\u{F04BA}", -- md-sort
  wrap = "\u{F05B6}", -- md-wrap
}

-- Code intelligence: language servers, tree-sitter, comments and formatting.
M.code = {
  code = "\u{F0169}", -- md-code_braces
  action = "\u{F06E9}", -- md-lightbulb_on_outline
  rename = "\u{F0455}", -- md-rename_box
  references = "\u{F0FE8}", -- md-vector_link
  definition = "\u{F08C9}", -- md-bullseye_arrow
  declaration = "\u{F05DD}", -- md-bullseye
  implementation = "\u{F1323}", -- md-hammer_wrench
  type_definition = "\u{F0C24}", -- md-alpha_t_box_outline
  symbols = "\u{F0832}", -- md-shape_outline
  signature = "\u{F0DFB}", -- md-signature
  codelens = "\u{F02AA}", -- md-glasses
  hover = "\u{F02FD}", -- md-information_outline
  format = "\u{F027C}", -- md-format_paint
  autoformat = "\u{F0068}", -- md-auto_fix
  autoformat_buffer = "\u{F0216}", -- md-file_check
  lint = "\u{F00E2}", -- md-broom
  snippet = "\u{F0190}", -- md-content_cut
  comment = "\u{F0182}", -- md-comment_outline
  comment_line = "\u{F0189}", -- md-comment_text_outline
  comment_add = "\u{F0183}", -- md-comment_plus_outline
  treesitter = "\u{F0645}", -- md-file_tree
  node_parent = "\u{F0F82}", -- md-select_group
  node_child = "\u{F0487}", -- md-select_inverse
  node_next = "\u{F0485}", -- md-select
  node_prev = "\u{F0488}", -- md-select_off
  node_sibling = "\u{F0AD9}", -- md-select_compare
  grow_selection = "\u{F0A6C}", -- md-select_drag
  inspect = "\u{F020A}", -- md-eyedropper
  inlay_hints = "\u{F0BD7}", -- md-tooltip_text_outline
  conceal = "\u{F06D1}", -- md-eye_off_outline
  line_numbers = "\u{F027B}", -- md-format_list_numbered
  relative_numbers = "\u{F03A0}", -- md-numeric
  tag = "\u{F04F9}", -- md-tag
  tag_preview = "\u{F1907}", -- md-tag_search
  lsp = "\u{F08D6}", -- md-cogs
  outline = "\u{F027A}", -- md-format_list_bulleted_type
  words = "\u{F0FB9}", -- md-format_letter_matches
  regex = "\u{F0451}", -- md-regex
  ["function"] = "\u{F0295}", -- md-function
  lambda = "\u{F0627}", -- md-lambda
  variable = "\u{F0AE7}", -- md-variable
  api = "\u{F109B}", -- md-api
  console = "\u{F018D}", -- md-console
  debug = "\u{F00E4}", -- md-bug
  test = "\u{F0668}", -- md-test_tube
  coverage = "\u{F07AF}", -- md-chart_donut
  benchmark = "\u{F051B}", -- md-timer_outline
}

-- Pickers and searches.
M.search = {
  search = "\u{F0349}", -- md-magnify
  find = "\u{F021E}", -- md-file_find
  files = "\u{F0C7C}", -- md-file_search
  files_cwd = "\u{F0C7D}", -- md-file_search_outline
  git_files = "\u{F02A2}", -- md-git
  config = "\u{F107B}", -- md-file_cog
  projects = "\u{F069D}", -- md-folder_star
  recent = "\u{F12E1}", -- md-file_clock
  grep = "\u{F13B8}", -- md-text_search
  grep_buffers = "\u{F0EAE}", -- md-text_box_search
  lines = "\u{F126F}", -- md-format_list_text
  command_history = "\u{F07B7}", -- md-console_line
  commands = "\u{F0633}", -- md-apple_keyboard_command
  notifications = "\u{F009A}", -- md-bell
  registers = "\u{F1267}", -- md-clipboard_multiple
  search_history = "\u{F02DA}", -- md-history
  autocmds = "\u{F06A9}", -- md-robot
  help = "\u{F087E}", -- md-lifebuoy
  highlights = "\u{F0E31}", -- md-format_color_highlight
  icons = "\u{F01F2}", -- md-emoticon_outline
  jumps = "\u{F0D20}", -- md-map_marker_path
  keymaps = "\u{F030C}", -- md-keyboard
  buffer_keymaps = "\u{F097B}", -- md-keyboard_outline
  marks = "\u{F0E15}", -- md-bookmark_multiple
  man = "\u{F14F7}", -- md-book_open_variant
  plugin_spec = "\u{F0A66}", -- md-puzzle_outline
  resume = "\u{F099B}", -- md-restore
  undo = "\u{F02DA}", -- md-history
  word = "\u{F0FB9}", -- md-format_letter_matches
  replace = "\u{F06D4}", -- md-find_replace
  next = "\u{F13B8}", -- md-text_search
  prev = "\u{F13B8}", -- md-text_search
  forward = "\u{F1874}", -- md-magnify_expand
  backward = "\u{F0980}", -- md-magnify_close
  todo_fix = "\u{F063E}", -- md-checkbox_multiple_marked_circle_outline
  clear = "\u{F120D}", -- md-magnify_remove_outline
}

-- The quickfix, location and argument lists.
M.lists = {
  quickfix = "\u{F0DD0}", -- md-format_list_bulleted_square
  location = "\u{F0352}", -- md-map_marker_radius
  args = "\u{F0222}", -- md-file_multiple
}

-- Diagnostic severities (Error, Warn, Info, Hint), as language servers and the
-- picker name them, and the keys that move between diagnostics.
M.diagnostics = {
  Error = "\u{F057}", -- fa-times_circle
  Warn = "\u{F071}", -- fa-warning
  Info = "\u{F05A}", -- fa-info_circle
  Hint = "\u{F0EB}", -- fa-lightbulb
  group = "\u{F04D9}", -- md-stethoscope
  jump = "\u{F04D9}", -- md-stethoscope
  line = "\u{F0362}", -- md-message_alert
  list = "\u{F0CE4}", -- md-alert_box_outline
  buffer = "\u{F0A4C}", -- md-file_alert_outline
}

-- Git.
M.git = {
  git = "\u{F02A2}", -- md-git
  github = "\u{F02A4}", -- md-github
  branch = "\u{E725}", -- dev-git_branch
  added = "\u{F0FE}", -- fa-plus_square
  modified = "\u{F14B}", -- fa-pencil_square
  removed = "\u{F146}", -- fa-minus_square
  renamed = "\u{F1031}", -- md-file_move_outline
  untracked = "\u{F078B}", -- md-help_box
  staged = "\u{F0E1E}", -- md-check_bold
  conflict = "\u{F0787}", -- md-sword_cross
  commit = "\u{F0718}", -- md-source_commit
  merge = "\u{F062D}", -- md-source_merge
  pull = "\u{F04C2}", -- md-source_pull
  pull_request = "\u{F04C2}", -- md-source_pull
  issue = "\u{F41B}", -- oct-issue_opened
  stash = "\u{F03D4}", -- md-package_down
  tag = "\u{F04FC}", -- md-tag_outline
  remote = "\u{F0CCF}", -- md-source_repository
  diff = "\u{F055A}", -- md-vector_difference
  blame = "\u{F0935}", -- md-account_search_outline
  log = "\u{F0BD3}", -- md-timeline_text
  hunk = "\u{F0992}", -- md-plus_minus
  hunk_stage = "\u{F0334}", -- md-plus_box_multiple
  hunk_reset = "\u{F054D}", -- md-undo_variant
  fork = "\u{F04C1}", -- md-source_fork
  repository = "\u{F0CD0}", -- md-source_repository_multiple
  lazygit = "\u{F062C}", -- md-source_branch
}

-- The sign column's change bars, drawn as plain block characters.
M.gitsigns = {
  add = "\u{258E}", -- U+258E left one quarter block
  change = "\u{258E}", -- U+258E left one quarter block
  delete = "\u{2581}", -- U+2581 lower one eighth block
  topdelete = "\u{2594}", -- U+2594 upper one eighth block
  changedelete = "\u{258E}", -- U+258E left one quarter block
  untracked = "\u{2506}", -- U+2506 box drawings light triple dash vertical
}

-- Folds.
M.fold = {
  fold = "\u{F054E}", -- md-unfold_less_horizontal
  open = "\u{F054F}", -- md-unfold_more_horizontal
  close = "\u{F054E}", -- md-unfold_less_horizontal
  toggle = "\u{F0761}", -- md-unfold_more_vertical
  create = "\u{F0704}", -- md-plus_box_outline
  delete = "\u{F06F2}", -- md-minus_box_outline
  update = "\u{F0450}", -- md-refresh
}

-- Spelling.
M.spell = {
  spell = "\u{F04C6}", -- md-spellcheck
  add = "\u{F05DB}", -- md-book_plus
  bad = "\u{F0A97}", -- md-book_remove
  suggest = "\u{F19E4}", -- md-lightbulb_question_outline
}

-- Text objects.
M.textobj = {
  around = "\u{F0D32}", -- md-selection_ellipse
  inside = "\u{F0487}", -- md-select_inverse
  string = "\u{EB8D}", -- cod-symbol_string
  angle = "\u{F016E}", -- md-code_less_than
  parens = "\u{F0172}", -- md-code_parentheses
  brackets = "\u{F016A}", -- md-code_brackets
  braces = "\u{F0169}", -- md-code_braces
  word = "\u{F0FBA}", -- md-format_letter_starts_with
  paragraph = "\u{F027D}", -- md-format_paragraph
  sentence = "\u{F09A9}", -- md-text_short
  tag = "\u{F0174}", -- md-code_tags
  scope = "\u{F10D6}", -- md-code_braces_box
  scope_top = "\u{F0623}", -- md-format_vertical_align_top
  scope_bottom = "\u{F0621}", -- md-format_vertical_align_bottom
}

-- Sessions.
M.session = {
  session = "\u{F006F}", -- md-backup_restore
  restore = "\u{F006F}", -- md-backup_restore
  pick = "\u{F10D4}", -- md-clipboard_list
  last = "\u{F02DA}", -- md-history
  stop = "\u{F1643}", -- md-content_save_off
}

-- Multiple cursors.
M.multicursor = {
  cursor = "\u{F05E7}", -- md-cursor_text
  add_match = "\u{F1143}", -- md-plus_box_multiple_outline
  skip = "\u{F01B7}", -- md-debug_step_over
  all = "\u{F0486}", -- md-select_all
  toggle = "\u{F0CFD}", -- md-cursor_default_click
  delete = "\u{F09E7}", -- md-delete_outline
  clear = "\u{F00E2}", -- md-broom
  align = "\u{F0262}", -- md-format_align_left
  above = "\u{F0738}", -- md-arrow_up_bold_box
  below = "\u{F072F}", -- md-arrow_down_bold_box
}

-- Terminals.
M.terminal = {
  term = "\u{F018D}", -- md-console
  cwd = "\u{F018D}", -- md-console
  root = "\u{F08A9}", -- md-console_network
  run = "\u{F07B7}", -- md-console_line
  float = "\u{F0614}", -- md-application_outline
}

-- The interface itself, and everyday objects worth a name.
M.ui = {
  toggle = "\u{F0521}", -- md-toggle_switch
  toggle_off = "\u{F0522}", -- md-toggle_switch_off
  redraw = "\u{F0450}", -- md-refresh
  escape = "\u{F12B7}", -- md-keyboard_esc
  cursorline = "\u{F05C8}", -- md-format_line_style
  notifications = "\u{F009A}", -- md-bell
  notifications_off = "\u{F009B}", -- md-bell_off
  palette = "\u{F03D8}", -- md-palette
  swatch = "\u{F08B5}", -- md-palette_swatch
  dashboard = "\u{F056E}", -- md-view_dashboard
  statusline = "\u{F10A9}", -- md-dock_bottom
  keyboard = "\u{F030C}", -- md-keyboard
  mouse = "\u{F037D}", -- md-mouse
  help = "\u{F0625}", -- md-help_circle_outline
  info = "\u{F02FD}", -- md-information_outline
  vim = "\u{E62B}", -- custom-vim
  neovim = "\u{E6AE}", -- custom-neovim
  health = "\u{F05F6}", -- md-heart_pulse
  checkhealth = "\u{F06EF}", -- md-medical_bag
  messages = "\u{F0369}", -- md-message_text
  log = "\u{F09ED}", -- md-text_box_outline
  news = "\u{F0395}", -- md-newspaper
  rss = "\u{F046B}", -- md-rss
  web = "\u{F059F}", -- md-web
  email = "\u{F01EE}", -- md-email
  calendar = "\u{F00ED}", -- md-calendar
  clock = "\u{F0150}", -- md-clock_outline
  alarm = "\u{F0020}", -- md-alarm
  user = "\u{F0004}", -- md-account
  users = "\u{F0849}", -- md-account_group
  key = "\u{F0306}", -- md-key
  shield = "\u{F0565}", -- md-shield_check
  heart = "\u{F02D1}", -- md-heart
  coffee = "\u{F0176}", -- md-coffee
  rocket = "\u{F14DE}", -- md-rocket_launch
  thumb_up = "\u{F0513}", -- md-thumb_up
  thumb_down = "\u{F0511}", -- md-thumb_down
  question = "\u{F02D7}", -- md-help_circle
  dots = "\u{F01D8}", -- md-dots_horizontal
  dots_vertical = "\u{F01D9}", -- md-dots_vertical
  menu = "\u{F035C}", -- md-menu
  list = "\u{F0279}", -- md-format_list_bulleted
  table = "\u{F04EB}", -- md-table
  chart = "\u{F0128}", -- md-chart_bar
  graph = "\u{F012A}", -- md-chart_line
  pie = "\u{F012B}", -- md-chart_pie
  image = "\u{F02E9}", -- md-image
  camera = "\u{F0100}", -- md-camera
  video = "\u{F0567}", -- md-video
  music = "\u{F075A}", -- md-music
  microphone = "\u{F036C}", -- md-microphone
  volume = "\u{F057E}", -- md-volume_high
  mute = "\u{F0581}", -- md-volume_off
  wifi = "\u{F05A9}", -- md-wifi
  bluetooth = "\u{F00AF}", -- md-bluetooth
  battery = "\u{F0079}", -- md-battery
  plug = "\u{F06A5}", -- md-power_plug
  sun = "\u{F0599}", -- md-weather_sunny
  moon = "\u{F0594}", -- md-weather_night
  brightness = "\u{F00DF}", -- md-brightness_6
  contrast = "\u{F0197}", -- md-contrast_circle
  brush = "\u{F00E3}", -- md-brush
  eyedropper = "\u{F020A}", -- md-eyedropper
  layers = "\u{F0328}", -- md-layers
  sidebar = "\u{F06FD}", -- md-page_layout_sidebar_left
  zen = "\u{F117B}", -- md-meditation
  dim = "\u{F00DD}", -- md-brightness_4
  indent_guides = "\u{F0276}", -- md-format_indent_increase
  scroll = "\u{F1552}", -- md-mouse_move_vertical
  animate = "\u{F05D8}", -- md-animation
  profiler = "\u{F029A}", -- md-gauge
  profiler_highlights = "\u{F066E}", -- md-chart_timeline
  preview = "\u{F06D0}", -- md-eye_outline
  fire = "\u{F0238}", -- md-fire
  lightning = "\u{F140B}", -- md-lightning_bolt
  flag = "\u{F023B}", -- md-flag
  label = "\u{F0316}", -- md-label_outline
  bell = "\u{F009E}", -- md-bell_ring
  target = "\u{F04FE}", -- md-target
  globe = "\u{F01E7}", -- md-earth
  emoji = "\u{F01F2}", -- md-emoticon_outline
}

-- Claude Code.
M.claude = {
  claude = "\u{2726}", -- U+2726 black four pointed star
  ai = "\u{F0674}", -- md-creation
  chat = "\u{F0EDE}", -- md-chat_outline
  send = "\u{F048A}", -- md-send
  add_file = "\u{F0EED}", -- md-file_plus_outline
  add_buffer = "\u{F1A9E}", -- md-file_document_plus_outline
  accept = "\u{F05E0}", -- md-check_circle
  deny = "\u{F0159}", -- md-close_circle
  resume = "\u{F040D}", -- md-play_circle_outline
  continue = "\u{F02DA}", -- md-history
  model = "\u{F09D1}", -- md-brain
  robot = "\u{F167A}", -- md-robot_outline
  focus = "\u{F02F1}", -- md-image_filter_center_focus
}

-- lazy.nvim's own interface, one entry per key of its ui.icons table.
M.lazy = {
  cmd = "\u{F07B7}", -- md-console_line
  config = "\u{F0493}", -- md-cog
  debug = "\u{F00E4}", -- md-bug
  event = "\u{F140B}", -- md-lightning_bolt
  favorite = "\u{F04CE}", -- md-star
  ft = "\u{F0219}", -- md-file_document
  init = "\u{F0425}", -- md-power
  import = "\u{F02FA}", -- md-import
  keys = "\u{F030C}", -- md-keyboard
  lazy = "\u{F04B2}", -- md-sleep
  loaded = "\u{F012F}", -- md-checkbox_blank_circle
  not_loaded = "\u{F0130}", -- md-checkbox_blank_circle_outline
  plugin = "\u{F0431}", -- md-puzzle
  runtime = "\u{E62B}", -- custom-vim
  require = "\u{F08B1}", -- md-language_lua
  source = "\u{F022E}", -- md-file_code
  start = "\u{F14DE}", -- md-rocket_launch
  task = "\u{F0E1E}", -- md-check_bold
}

-- Mason's package states.
M.mason = {
  mason = "\u{F03D7}", -- md-package_variant_closed
  installed = "\u{F05E0}", -- md-check_circle
  pending = "\u{F0996}", -- md-progress_clock
  uninstalled = "\u{F015A}", -- md-close_circle_outline
}

-- todo-comments keywords.
M.todo = {
  FIX = "\u{F00E4}", -- md-bug
  TODO = "\u{F0134}", -- md-checkbox_marked_circle_outline
  HACK = "\u{F0238}", -- md-fire
  WARN = "\u{F0026}", -- md-alert
  PERF = "\u{F04C5}", -- md-speedometer
  NOTE = "\u{F11D7}", -- md-note_text_outline
  TEST = "\u{F0668}", -- md-test_tube
}

-- The debugger: its sign-column marks (capitalised, as nvim-dap names them) and
-- its controls.
M.dap = {
  debug = "\u{F00E4}", -- md-bug
  Stopped = "\u{F0055}", -- md-arrow_right_thick
  Breakpoint = "\u{F111}", -- fa-circle
  BreakpointCondition = "\u{F059}", -- fa-question_circle
  BreakpointRejected = "\u{F06A}", -- fa-exclamation_circle
  LogPoint = "\u{F036A}", -- md-message_text_outline
  continue = "\u{F040C}", -- md-play_circle
  step_over = "\u{F01B7}", -- md-debug_step_over
  step_into = "\u{F01B9}", -- md-debug_step_into
  step_out = "\u{F01B8}", -- md-debug_step_out
  run_to_cursor = "\u{F0CFE}", -- md-cursor_default_click_outline
  run_last = "\u{F02DA}", -- md-history
  restart = "\u{F0709}", -- md-restart
  terminate = "\u{F0666}", -- md-stop_circle
  pause = "\u{F03E5}", -- md-pause_circle
  repl = "\u{F07B7}", -- md-console_line
  eval = "\u{F0A9A}", -- md-calculator_variant
  widgets = "\u{F072C}", -- md-widgets
  ui = "\u{F0675}", -- md-application_cog
  frame_up = "\u{F0060}", -- md-arrow_up_bold_circle_outline
  frame_down = "\u{F0048}", -- md-arrow_down_bold_circle_outline
}

-- Chips, logic gates and signals, for the hardware languages.
M.hardware = {
  chip = "\u{EC19}", -- cod-chip
  microchip = "\u{F2DB}", -- fa-microchip
  fae_chip = "\u{E266}", -- fae-chip
  cpu = "\u{F0EE0}", -- md-cpu_64_bit
  cpu32 = "\u{F0EDF}", -- md-cpu_32_bit
  cpu_oct = "\u{F4BC}", -- oct-cpu
  memory = "\u{F035B}", -- md-memory
  fa_memory = "\u{EFC5}", -- fa-memory
  ic = "\u{F1913}", -- md-integrated_circuit_chip
  board = "\u{F0697}", -- md-developer_board
  circuit = "\u{EABE}", -- cod-circuit_board
  expansion = "\u{F08AE}", -- md-expansion_card
  waveform = "\u{F147D}", -- md-waveform
  sine = "\u{F095B}", -- md-sine_wave
  cosine = "\u{F1479}", -- md-cosine_wave
  square_wave = "\u{F147B}", -- md-square_wave
  resistor = "\u{F0B44}", -- md-resistor
  gate_and = "\u{F08E1}", -- md-gate_and
  gate_or = "\u{F08E5}", -- md-gate_or
  gate_not = "\u{F08E4}", -- md-gate_not
  gate_nand = "\u{F08E2}", -- md-gate_nand
  gate_nor = "\u{F08E3}", -- md-gate_nor
  gate_xor = "\u{F08E7}", -- md-gate_xor
  gate_xnor = "\u{F08E6}", -- md-gate_xnor
  serial = "\u{F065C}", -- md-serial_port
  ethernet = "\u{F0200}", -- md-ethernet
  usb = "\u{F0553}", -- md-usb
  sd = "\u{F0479}", -- md-sd
  flash = "\u{F0241}", -- md-flash
  lightning = "\u{F140B}", -- md-lightning_bolt
  power = "\u{F06A5}", -- md-power_plug
  clock = "\u{F0E97}", -- md-clock_digital
  sigma = "\u{F04A0}", -- md-sigma
  lambda = "\u{F0627}", -- md-lambda
  ["function"] = "\u{F0295}", -- md-function
  function_variant = "\u{F0871}", -- md-function_variant
  variable = "\u{F0AE7}", -- md-variable
  symbol_variable = "\u{EA88}", -- cod-symbol_variable
  timer = "\u{F051F}", -- md-timer_sand
  constraint = "\u{F0EBE}", -- md-ruler_square_compass
  netlist = "\u{F104A}", -- md-graph_outline
  oscilloscope = "\u{F0C50}", -- md-chart_bell_curve
}

-- Languages and tools.
M.lang = {
  python = "\u{F0320}", -- md-language_python
  lua = "\u{F08B1}", -- md-language_lua
  rust = "\u{F1617}", -- md-language_rust
  go = "\u{F07D3}", -- md-language_go
  c = "\u{F0671}", -- md-language_c
  cpp = "\u{F0672}", -- md-language_cpp
  csharp = "\u{F031B}", -- md-language_csharp
  java = "\u{F0B37}", -- md-language_java
  javascript = "\u{F031E}", -- md-language_javascript
  typescript = "\u{F06E6}", -- md-language_typescript
  haskell = "\u{F0C92}", -- md-language_haskell
  ruby = "\u{F0D2D}", -- md-language_ruby
  swift = "\u{F06E5}", -- md-language_swift
  kotlin = "\u{F1219}", -- md-language_kotlin
  r = "\u{F07D4}", -- md-language_r
  php = "\u{F031F}", -- md-language_php
  fortran = "\u{F121A}", -- md-language_fortran
  html = "\u{F031D}", -- md-language_html5
  css = "\u{F031C}", -- md-language_css3
  markdown = "\u{F0354}", -- md-language_markdown
  markdown_outline = "\u{F0F5B}", -- md-language_markdown_outline
  latex = "\u{E69B}", -- seti-tex
  docker = "\u{F0868}", -- md-docker
  nix = "\u{F1105}", -- md-nix
  react = "\u{E7BA}", -- dev-react
  clojure = "\u{E768}", -- dev-clojure
  ocaml = "\u{E67A}", -- seti-ocaml
  gotmpl = "\u{E627}", -- seti-go
  shader = "\u{F0B84}", -- md-cube_scan
  terraform = "\u{F1062}", -- md-terraform
  json = "\u{F0626}", -- md-code_json
  yaml = "\u{F016A}", -- md-code_brackets
  toml = "\u{F08BB}", -- md-cog_outline
  sql = "\u{F0866}", -- md-database_search
  script = "\u{F0BC2}", -- md-script_text
  beer = "\u{F0098}", -- md-beer
  gavel = "\u{F029B}", -- md-gavel
}

-- Symbol and completion kinds: every kind the language server protocol names,
-- and kinds for hardware description languages and Claude.
M.kinds = {
  Array = "\u{F016A}", -- md-code_brackets
  Boolean = "\u{F0A1A}", -- md-toggle_switch_outline
  Class = "\u{EB5B}", -- cod-symbol_class
  Color = "\u{F03D8}", -- md-palette
  Constant = "\u{EB5D}", -- cod-symbol_constant
  Constructor = "\u{F1323}", -- md-hammer_wrench
  Enum = "\u{EA95}", -- cod-symbol_enum
  EnumMember = "\u{EB5E}", -- cod-symbol_enum_member
  Event = "\u{EA86}", -- cod-symbol_event
  Field = "\u{EB5F}", -- cod-symbol_field
  File = "\u{F0224}", -- md-file_outline
  Folder = "\u{F0256}", -- md-folder_outline
  Function = "\u{F0295}", -- md-function
  Interface = "\u{EB61}", -- cod-symbol_interface
  Key = "\u{EA93}", -- cod-symbol_key
  Keyword = "\u{EB62}", -- cod-symbol_keyword
  Method = "\u{EA8C}", -- cod-symbol_method
  Module = "\u{F01A7}", -- md-cube_outline
  Namespace = "\u{EA8B}", -- cod-symbol_namespace
  Null = "\u{F07E2}", -- md-null
  Number = "\u{F03A0}", -- md-numeric
  Object = "\u{F0169}", -- md-code_braces
  Operator = "\u{EB64}", -- cod-symbol_operator
  Package = "\u{F03D7}", -- md-package_variant_closed
  Property = "\u{EB65}", -- cod-symbol_property
  Reference = "\u{EB36}", -- cod-references
  Snippet = "\u{EB66}", -- cod-symbol_snippet
  String = "\u{EB8D}", -- cod-symbol_string
  Struct = "\u{EA91}", -- cod-symbol_structure
  Text = "\u{F0284}", -- md-format_text
  TypeParameter = "\u{F0C24}", -- md-alpha_t_box_outline
  Unit = "\u{EA96}", -- cod-symbol_ruler
  Value = "\u{EA90}", -- cod-symbol_numeric
  Variable = "\u{EA88}", -- cod-symbol_variable
  Control = "\u{F062E}", -- md-tune
  Collapsed = "\u{F0704}", -- md-plus_box_outline
  Claude = "\u{2726}", -- U+2726 black four pointed star
  Macro = "\u{F0423}", -- md-pound
  Parameter = "\u{EA92}", -- cod-symbol_parameter
  Label = "\u{F0316}", -- md-label_outline
  Type = "\u{F0C24}", -- md-alpha_t_box_outline
  TypeAlias = "\u{F0C26}", -- md-alpha_t_circle_outline
  Decorator = "\u{F0065}", -- md-at
  Attribute = "\u{F04FC}", -- md-tag_outline
  Trait = "\u{F0A66}", -- md-puzzle_outline
  Union = "\u{F0778}", -- md-set_all
  Component = "\u{F1355}", -- md-widgets_outline
  Heading = "\u{F0274}", -- md-format_header_pound
  Link = "\u{F0339}", -- md-link_variant
  Regex = "\u{F0451}", -- md-regex
  StaticMethod = "\u{F0871}", -- md-function_variant
  Signal = "\u{F095B}", -- md-sine_wave
  Wire = "\u{F055E}", -- md-vector_line
  Port = "\u{F065C}", -- md-serial_port
  Register = "\u{F035B}", -- md-memory
  Clock = "\u{F147B}", -- md-square_wave
  Reset = "\u{F0901}", -- md-power_cycle
  Instance = "\u{EC19}", -- cod-chip
  Assertion = "\u{F0CC8}", -- md-shield_check_outline
  Coverage = "\u{F07AF}", -- md-chart_donut
  Task = "\u{F0756}", -- md-format_list_checks
  Process = "\u{F08D6}", -- md-cogs
  Sequence = "\u{F0BD2}", -- md-timeline_outline
}

-- The dashboard's buttons.
M.dashboard = {
  find_file = "\u{F002}", -- fa-search
  recent = "\u{F1DA}", -- fa-history
  projects = "\u{F07C}", -- fa-folder_open
  search_text = "\u{F13B8}", -- md-text_search
  config = "\u{F013}", -- fa-cog
  plugins = "\u{F04B2}", -- md-sleep
  language_tools = "\u{F1064}", -- md-tools
  quit = "\u{F0425}", -- md-power
  notes = "\u{F082E}", -- md-notebook
  tip = "\u{F0EB}", -- fa-lightbulb
}

-- The status bar. None of these may be an arrow, chevron, angle or triangle;
-- tests/test_icons.lua checks each against lua/ach/glyphs_forbidden.lua.
M.status = {
  vim = "\u{E62B}", -- custom-vim
  branch = "\u{E725}", -- dev-git_branch
  added = "\u{F0FE}", -- fa-plus_square
  modified = "\u{F14B}", -- fa-pencil_square
  removed = "\u{F146}", -- fa-minus_square
  project = "\u{F07C}", -- fa-folder_open
  unsaved = "\u{25CF}", -- U+25CF black circle
  readonly = "\u{F023}", -- fa-lock
  error = "\u{F057}", -- fa-times_circle
  warn = "\u{F071}", -- fa-warning
  info = "\u{F05A}", -- fa-info_circle
  hint = "\u{F0EB}", -- fa-lightbulb
  lsp = "\u{F085}", -- fa-cogs
  formatter = "\u{F027C}", -- md-format_paint
  linter = "\u{F00E2}", -- md-broom
  words = "\u{F022D}", -- md-file_word_box
  indent = "\u{F1050}", -- md-keyboard_space
  claude = "\u{2726}", -- U+2726 black four pointed star
  recording = "\u{25CF}", -- U+25CF black circle
  search = "\u{F002}", -- fa-search
  selection = "\u{F246}", -- fa-i_cursor
  updates = "\u{F03D6}", -- md-package_variant
  dap = "\u{F188}", -- fa-bug
}

-- lazy.nvim's list bullets, one per nesting depth in its debug view. Its own
-- second bullet is an arrow, which this set swaps for an open circle.
M.lazy_list = { "\u{25CF}", "\u{25CB}", "\u{2605}", "\u{2012}" }

-- Every key description this configuration, Neovim and which-key show, with the
-- glyph and colour which-key draws beside it. which-key compares descriptions in
-- lower case, so two that differ only in case must share an icon.
M.keys = {
  -- Keys this configuration sets: windows, buffers and lines
  ["Close Window"] = { "windows.close", "blue" },
  ["Down"] = { "nav.down", "azure" },
  ["Up"] = { "nav.up", "azure" },
  ["Go to Left Window"] = { "windows.go_left", "blue" },
  ["Go to Lower Window"] = { "windows.go_down", "blue" },
  ["Go to Upper Window"] = { "windows.go_up", "blue" },
  ["Go to Right Window"] = { "windows.go_right", "blue" },
  ["Increase Window Height"] = { "windows.height_inc", "blue" },
  ["Decrease Window Height"] = { "windows.height_dec", "blue" },
  ["Decrease Window Width"] = { "windows.width_dec", "blue" },
  ["Increase Window Width"] = { "windows.width_inc", "blue" },
  ["Split Window Below"] = { "windows.split_below", "blue" },
  ["Split Window Right"] = { "windows.split_right", "blue" },
  ["Delete Window"] = { "windows.close", "red" },
  ["Move Down"] = { "edit.move_down", "yellow" },
  ["Move Up"] = { "edit.move_up", "yellow" },
  ["Prev Buffer"] = { "buffers.buffer", "cyan" },
  ["Next Buffer"] = { "buffers.buffer", "cyan" },
  ["Switch to Other Buffer"] = { "buffers.alternate", "cyan" },
  ["Delete Buffer"] = { "buffers.delete", "red" },
  ["Delete Other Buffers"] = { "buffers.delete_others", "red" },
  ["Delete Buffer and Window"] = { "buffers.delete_window", "red" },
  ["Escape and Clear hlsearch"] = { "ui.escape", "grey" },
  ["Redraw / Clear hlsearch"] = { "ui.redraw", "cyan" },
  ["Next Search Result"] = { "search.next", "green" },
  ["Prev Search Result"] = { "search.prev", "green" },
  ["Save File"] = { "actions.save", "green" },
  ["New File"] = { "files.new", "cyan" },
  ["Copy File Path"] = { "files.copy_path", "cyan" },
  ["Indent Left"] = { "edit.outdent", "yellow" },
  ["Indent Right"] = { "edit.indent", "yellow" },
  ["Add Comment Below"] = { "code.comment_add", "azure" },
  ["Add Comment Above"] = { "code.comment_add", "azure" },
  ["Location List"] = { "lists.location", "azure" },
  ["Quickfix List"] = { "lists.quickfix", "azure" },
  ["Line Diagnostics"] = { "diagnostics.line", "green" },
  ["Next Diagnostic"] = { "diagnostics.jump", "green" },
  ["Prev Diagnostic"] = { "diagnostics.jump", "green" },
  ["Next Error"] = { "diagnostics.Error", "red" },
  ["Prev Error"] = { "diagnostics.Error", "red" },
  ["Next Warning"] = { "diagnostics.Warn", "yellow" },
  ["Prev Warning"] = { "diagnostics.Warn", "yellow" },
  ["Undo Tree"] = { "edit.undo_tree", "yellow" },
  ["Inspect Pos"] = { "code.inspect", "cyan" },
  ["Inspect Tree"] = { "code.treesitter", "green" },
  ["Terminal (cwd)"] = { "terminal.cwd", "red" },
  ["Terminal (Root Dir)"] = { "terminal.root", "red" },
  ["New Tab"] = { "tabs.new", "purple" },
  ["Next Tab"] = { "tabs.next", "purple" },
  ["Previous Tab"] = { "tabs.prev", "purple" },
  ["Close Tab"] = { "tabs.close", "red" },
  ["Close Other Tabs"] = { "tabs.close_others", "red" },
  ["First Tab"] = { "tabs.first", "purple" },
  ["Last Tab"] = { "tabs.last", "purple" },
  ["Quit All"] = { "actions.quit", "red" },
  ["Lazy"] = { "lazy.lazy", "blue" },
  ["Buffer Keymaps (which-key)"] = { "search.buffer_keymaps", "cyan" },
  ["Window Hydra Mode (which-key)"] = { "windows.hydra", "blue" },
  -- Keys this configuration sets: pickers
  ["Find Files (Root Dir)"] = { "search.files", "green" },
  ["Buffers"] = { "buffers.list", "cyan" },
  ["Grep (Root Dir)"] = { "search.grep", "green" },
  ["Command History"] = { "search.command_history", "green" },
  ["Notification History"] = { "search.notifications", "blue" },
  ["Find Config File"] = { "search.config", "green" },
  ["Find Files (cwd)"] = { "search.files_cwd", "green" },
  ["Find Files (git-files)"] = { "search.git_files", "orange" },
  ["Projects"] = { "search.projects", "azure" },
  ["Recent"] = { "search.recent", "green" },
  ["Recent (cwd)"] = { "search.recent", "green" },
  ["Registers"] = { "search.registers", "yellow" },
  ["Search History"] = { "search.search_history", "green" },
  ["Autocmds"] = { "search.autocmds", "green" },
  ["Buffer Lines"] = { "search.lines", "green" },
  ["Grep Open Buffers"] = { "search.grep_buffers", "green" },
  ["Commands"] = { "search.commands", "green" },
  ["Diagnostics"] = { "diagnostics.list", "green" },
  ["Buffer Diagnostics"] = { "diagnostics.buffer", "green" },
  ["Grep (cwd)"] = { "search.grep", "green" },
  ["Help Pages"] = { "search.help", "green" },
  ["Highlights"] = { "search.highlights", "green" },
  ["Icons"] = { "search.icons", "yellow" },
  ["Jumps"] = { "search.jumps", "green" },
  ["Keymaps"] = { "search.keymaps", "green" },
  ["Marks"] = { "search.marks", "green" },
  ["Man Pages"] = { "search.man", "green" },
  ["Search for Plugin Spec"] = { "search.plugin_spec", "green" },
  ["Resume"] = { "search.resume", "green" },
  ["Undo History"] = { "search.undo", "green" },
  ["Selection or Word (Root Dir)"] = { "search.word", "green" },
  ["Selection or Word (cwd)"] = { "search.word", "green" },
  -- Keys this configuration sets: editor plugins
  ["Flash Jump"] = { "nav.flash", "yellow" },
  ["Flash Select by Syntax"] = { "nav.flash_select", "yellow" },
  ["Flash Remote"] = { "nav.flash_remote", "yellow" },
  ["Flash Search by Syntax"] = { "nav.flash_search", "yellow" },
  ["Toggle Flash in Search"] = { "nav.flash_auto", "yellow" },
  ["Grow Selection by Syntax"] = { "code.grow_selection", "purple" },
  ["Search and Replace"] = { "search.replace", "blue" },
  ["Problems (Trouble)"] = { "diagnostics.list", "green" },
  ["Problems in This Buffer (Trouble)"] = { "diagnostics.buffer", "green" },
  ["Symbols (Trouble)"] = { "code.symbols", "purple" },
  ["Definitions and References (Trouble)"] = { "code.references", "purple" },
  ["Location List (Trouble)"] = { "lists.location", "azure" },
  ["Quickfix List (Trouble)"] = { "lists.quickfix", "azure" },
  ["Previous Problem or Quickfix Entry"] = { "lists.quickfix", "azure" },
  ["Next Problem or Quickfix Entry"] = { "lists.quickfix", "azure" },
  ["Next TODO Comment"] = { "todo.TODO", "yellow" },
  ["Previous TODO Comment"] = { "todo.TODO", "yellow" },
  ["TODO Comments (Trouble)"] = { "todo.TODO", "yellow" },
  ["TODO and FIX Comments (Trouble)"] = { "search.todo_fix", "yellow" },
  ["TODO Comments"] = { "todo.TODO", "yellow" },
  ["TODO and FIX Comments"] = { "search.todo_fix", "yellow" },
  ["Open Folder as Text (oil)"] = { "files.folder_edit", "cyan" },
  ["Restore Session for This Folder"] = { "session.restore", "azure" },
  ["Pick a Session"] = { "session.pick", "azure" },
  ["Restore Last Session"] = { "session.last", "azure" },
  ["Don't Save This Session"] = { "session.stop", "red" },
  ["Previous Cursor"] = { "multicursor.cursor", "purple" },
  ["Next Cursor"] = { "multicursor.cursor", "purple" },
  ["Delete This Cursor"] = { "multicursor.delete", "red" },
  ["Clear Cursors"] = { "multicursor.clear", "purple" },
  ["Add Cursor at Next Match"] = { "multicursor.add_match", "purple" },
  ["Add Cursor at Previous Match"] = { "multicursor.add_match", "purple" },
  ["Skip to Next Match"] = { "multicursor.skip", "purple" },
  ["Skip to Previous Match"] = { "multicursor.skip", "purple" },
  ["Add Cursors at Every Match"] = { "multicursor.all", "purple" },
  ["Add or Remove a Cursor Here"] = { "multicursor.toggle", "purple" },
  ["Align Cursors"] = { "multicursor.align", "purple" },
  ["Add Cursor Above"] = { "multicursor.above", "purple" },
  ["Add Cursor Below"] = { "multicursor.below", "purple" },
  ["File Tree (project)"] = { "files.tree", "cyan" },
  ["File Tree (working folder)"] = { "files.tree_outline", "cyan" },
  ["Toggle Docked Panes"] = { "windows.dock", "blue" },
  ["Pick a Docked Pane"] = { "windows.dock_pick", "blue" },
  -- Neovim's own keys
  [":blast"] = { "buffers.buffer", "cyan" },
  [":bnext"] = { "buffers.buffer", "cyan" },
  [":bprevious"] = { "buffers.buffer", "cyan" },
  [":brewind"] = { "buffers.buffer", "cyan" },
  [":clast"] = { "lists.quickfix", "azure" },
  [":cnext"] = { "lists.quickfix", "azure" },
  [":cnfile"] = { "lists.quickfix", "azure" },
  [":cpfile"] = { "lists.quickfix", "azure" },
  [":cprevious"] = { "lists.quickfix", "azure" },
  [":crewind"] = { "lists.quickfix", "azure" },
  [":llast"] = { "lists.location", "azure" },
  [":lnext"] = { "lists.location", "azure" },
  [":lnfile"] = { "lists.location", "azure" },
  [":lpfile"] = { "lists.location", "azure" },
  [":lprevious"] = { "lists.location", "azure" },
  [":lrewind"] = { "lists.location", "azure" },
  [":last"] = { "lists.args", "azure" },
  [":next"] = { "lists.args", "azure" },
  [":previous"] = { "lists.args", "azure" },
  [":rewind"] = { "lists.args", "azure" },
  [":ptnext"] = { "code.tag_preview", "purple" },
  [":ptprevious"] = { "code.tag_preview", "purple" },
  [":tlast"] = { "code.tag", "purple" },
  [":tnext"] = { "code.tag", "purple" },
  [":tprevious"] = { "code.tag", "purple" },
  [":trewind"] = { "code.tag", "purple" },
  [":help &-default"] = { "edit.repeat_sub", "yellow" },
  [":help CTRL-L-default"] = { "ui.redraw", "cyan" },
  [":help Y-default"] = { "edit.yank", "green" },
  [":help i_CTRL-U-default"] = { "edit.delete_line", "red" },
  [":help i_CTRL-W-default"] = { "edit.delete_word", "red" },
  [":help v_#-default"] = { "search.word", "green" },
  [":help v_star-default"] = { "search.word", "green" },
  [":help v_@-default"] = { "edit.macro", "red" },
  [":help v_Q-default"] = { "edit.macro_repeat", "red" },
  ["Add empty line above cursor"] = { "edit.line_above", "yellow" },
  ["Add empty line below cursor"] = { "edit.line_below", "yellow" },
  ["Comment textobject"] = { "code.comment", "azure" },
  ["Toggle comment"] = { "code.comment", "azure" },
  ["Toggle comment line"] = { "code.comment_line", "azure" },
  ["Jump to the first diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the last diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the next diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the previous diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Show diagnostics under the cursor"] = { "diagnostics.line", "green" },
  ["Select parent (outer) node"] = { "code.node_parent", "green" },
  ["Select child (inner) node"] = { "code.node_child", "green" },
  ["Select next node"] = { "code.node_next", "green" },
  ["Select previous node"] = { "code.node_prev", "green" },
  ["Select next sibling node"] = { "code.node_sibling", "green" },
  ["Select previous sibling node"] = { "code.node_sibling", "green" },
  ["vim.lsp.buf.code_action()"] = { "code.action", "purple" },
  ["vim.lsp.buf.document_symbol()"] = { "code.symbols", "purple" },
  ["vim.lsp.buf.implementation()"] = { "code.implementation", "purple" },
  ["vim.lsp.buf.references()"] = { "code.references", "purple" },
  ["vim.lsp.buf.rename()"] = { "code.rename", "purple" },
  ["vim.lsp.buf.signature_help()"] = { "code.signature", "purple" },
  ["vim.lsp.buf.type_definition()"] = { "code.type_definition", "purple" },
  ["vim.lsp.codelens.run()"] = { "code.codelens", "purple" },
  ["vim.snippet.jump if active, otherwise <Tab>"] = { "code.snippet", "purple" },
  ["vim.snippet.jump if active, otherwise <S-Tab>"] = { "code.snippet", "purple" },
  ["Opens filepath or URI under cursor with the system handler (file explorer, web browser, …)"] = { "actions.open_external", "blue" },
  -- which-key's built-in descriptions: operators
  ["Change"] = { "edit.change", "yellow" },
  ["Delete"] = { "edit.delete", "red" },
  ["Yank"] = { "edit.yank", "green" },
  ["Replace"] = { "edit.replace", "yellow" },
  ["Format"] = { "edit.format", "yellow" },
  ["Indent left"] = { "edit.outdent", "yellow" },
  ["Indent right"] = { "edit.indent", "yellow" },
  ["Uppercase"] = { "edit.upper", "yellow" },
  ["Lowercase"] = { "edit.lower", "yellow" },
  ["Toggle case"] = { "edit.case", "yellow" },
  ["Visual"] = { "edit.visual", "yellow" },
  ["Visual Line"] = { "edit.visual_line", "yellow" },
  ["Create fold"] = { "fold.create", "blue" },
  ["Run program"] = { "terminal.run", "red" },
  -- which-key's built-in descriptions: motions
  ["Left"] = { "nav.left", "azure" },
  ["Right"] = { "nav.right", "azure" },
  ["End of line"] = { "nav.line_end", "azure" },
  ["Start of line"] = { "nav.line_start", "azure" },
  ["Start of line (non ws)"] = { "nav.line_first_char", "azure" },
  ["First line"] = { "nav.first_line", "azure" },
  ["Last line"] = { "nav.last_line", "azure" },
  ["Matching (){}[]"] = { "nav.match", "azure" },
  ["Move to next char"] = { "nav.char", "azure" },
  ["Move to prev char"] = { "nav.char", "azure" },
  ["Move before next char"] = { "nav.char", "azure" },
  ["Move before prev char"] = { "nav.char", "azure" },
  ["Next ftFT"] = { "nav.char_repeat", "azure" },
  ["Prev ftFT"] = { "nav.char_repeat", "azure" },
  ["Next word"] = { "nav.word", "azure" },
  ["Prev word"] = { "nav.word", "azure" },
  ["Next WORD"] = { "nav.word", "azure" },
  ["Prev WORD"] = { "nav.word", "azure" },
  ["Next end of word"] = { "nav.word_end", "azure" },
  ["Prev end of word"] = { "nav.word_end", "azure" },
  ["Next end of WORD"] = { "nav.word_end", "azure" },
  ["Next empty line"] = { "nav.paragraph", "azure" },
  ["Prev empty line"] = { "nav.paragraph", "azure" },
  ["Search forward"] = { "search.forward", "green" },
  ["Search backward"] = { "search.backward", "green" },
  -- which-key's built-in descriptions: text objects
  ["around"] = { "textobj.around", "cyan" },
  ["inside"] = { "textobj.inside", "cyan" },
  ["' string"] = { "textobj.string", "cyan" },
  ["` string"] = { "textobj.string", "cyan" },
  ["inner ' string"] = { "textobj.string", "cyan" },
  ["inner ` string"] = { "textobj.string", "cyan" },
  ["<> block"] = { "textobj.angle", "cyan" },
  ["inner <>"] = { "textobj.angle", "cyan" },
  ["[(]) block"] = { "textobj.parens", "cyan" },
  ["inner [(])"] = { "textobj.parens", "cyan" },
  ["[] block"] = { "textobj.brackets", "cyan" },
  ["inner []"] = { "textobj.brackets", "cyan" },
  ["[{]} block"] = { "textobj.braces", "cyan" },
  ["inner [{]}"] = { "textobj.braces", "cyan" },
  ["word with ws"] = { "textobj.word", "cyan" },
  ["WORD with ws"] = { "textobj.word", "cyan" },
  ["inner word"] = { "textobj.word", "cyan" },
  ["inner WORD"] = { "textobj.word", "cyan" },
  ["paragraph"] = { "textobj.paragraph", "cyan" },
  ["inner paragraph"] = { "textobj.paragraph", "cyan" },
  ["sentence"] = { "textobj.sentence", "cyan" },
  ["inner sentence"] = { "textobj.sentence", "cyan" },
  ["tag block"] = { "textobj.tag", "cyan" },
  ["inner tag block"] = { "textobj.tag", "cyan" },
  -- which-key's built-in descriptions: windows
  ["window"] = { "windows.window", "blue" },
  ["Go to the left window"] = { "windows.go_left", "blue" },
  ["Go to the down window"] = { "windows.go_down", "blue" },
  ["Go to the up window"] = { "windows.go_up", "blue" },
  ["Go to the right window"] = { "windows.go_right", "blue" },
  ["Move window to far left"] = { "windows.far_left", "blue" },
  ["Move window to far bottom"] = { "windows.far_bottom", "blue" },
  ["Move window to far top"] = { "windows.far_top", "blue" },
  ["Move window to far right"] = { "windows.far_right", "blue" },
  ["Increase height"] = { "windows.height_inc", "blue" },
  ["Decrease height"] = { "windows.height_dec", "blue" },
  ["Increase width"] = { "windows.width_inc", "blue" },
  ["Decrease width"] = { "windows.width_dec", "blue" },
  ["Max out the height"] = { "windows.max_height", "blue" },
  ["Max out the width"] = { "windows.max_width", "blue" },
  ["Equally high and wide"] = { "windows.equalize", "blue" },
  ["Split window"] = { "windows.split_below", "blue" },
  ["Split window vertically"] = { "windows.split_right", "blue" },
  ["Close all other windows"] = { "windows.only", "blue" },
  ["Quit a window"] = { "windows.close", "red" },
  ["Swap current with next"] = { "windows.swap", "blue" },
  ["Switch windows"] = { "windows.switch", "blue" },
  ["Break out into a new tab"] = { "windows.to_tab", "blue" },
  -- which-key's built-in descriptions: folds, spelling and scrolling
  ["Close all folds"] = { "fold.close", "blue" },
  ["Close all folds under cursor"] = { "fold.close", "blue" },
  ["Close fold under cursor"] = { "fold.close", "blue" },
  ["Open all folds"] = { "fold.open", "blue" },
  ["Open all folds under cursor"] = { "fold.open", "blue" },
  ["Open fold under cursor"] = { "fold.open", "blue" },
  ["Toggle all folds under cursor"] = { "fold.toggle", "blue" },
  ["Toggle fold under cursor"] = { "fold.toggle", "blue" },
  ["Toggle folding"] = { "fold.toggle", "blue" },
  ["Delete all folds in file"] = { "fold.delete", "red" },
  ["Delete all folds under cursor"] = { "fold.delete", "red" },
  ["Delete fold under cursor"] = { "fold.delete", "red" },
  ["Fold more"] = { "fold.close", "blue" },
  ["Fold less"] = { "fold.open", "blue" },
  ["Update folds"] = { "fold.update", "blue" },
  ["Add word to spell list"] = { "spell.add", "yellow" },
  ["Mark word as bad/misspelling"] = { "spell.bad", "red" },
  ["Spelling suggestions"] = { "spell.suggest", "yellow" },
  ["Next misspelled word"] = { "spell.spell", "yellow" },
  ["Previous misspelled word"] = { "spell.spell", "yellow" },
  ["Top this line"] = { "nav.view_top", "azure" },
  ["Center this line"] = { "nav.view_center", "azure" },
  ["Bottom this line"] = { "nav.view_bottom", "azure" },
  ["Left this line"] = { "nav.view_left", "azure" },
  ["Right this line"] = { "nav.view_right", "azure" },
  ["Half screen to the left"] = { "nav.pan_left", "azure" },
  ["Half screen to the right"] = { "nav.pan_right", "azure" },
  ["Show cursor line"] = { "ui.cursorline", "cyan" },
  -- which-key's built-in descriptions: brackets and window lines
  ["Home line of window (top)"] = { "nav.window_top", "azure" },
  ["Middle line of window"] = { "nav.window_middle", "azure" },
  ["Last line of window"] = { "nav.window_bottom", "azure" },
  ["Next ("] = { "nav.paren", "azure" },
  ["Previous ("] = { "nav.paren", "azure" },
  ["Next <"] = { "nav.angle", "azure" },
  ["Previous <"] = { "nav.angle", "azure" },
  ["Next {"] = { "nav.brace", "azure" },
  ["Previous {"] = { "nav.brace", "azure" },
  ["Next unmatched group"] = { "nav.paren", "azure" },
  ["Previous unmatched group"] = { "nav.paren", "azure" },
  ["Next method start"] = { "kinds.Method", "purple" },
  ["Next method end"] = { "kinds.Method", "purple" },
  ["Previous method start"] = { "kinds.Method", "purple" },
  ["Previous method end"] = { "kinds.Method", "purple" },
  -- which-key's built-in descriptions: the g prefix
  ["Go to file under cursor"] = { "files.find", "cyan" },
  ["Go to last insert"] = { "nav.last_insert", "azure" },
  ["Go to next tab page"] = { "tabs.next", "purple" },
  ["Go to previous tab page"] = { "tabs.prev", "purple" },
  ["Go to [count] newer position in change list"] = { "nav.changes", "azure" },
  ["Go to [count] older position in change list"] = { "nav.changes", "azure" },
  ["Last visual selection"] = { "edit.visual_last", "yellow" },
  ["Open file with system app"] = { "actions.open_external", "blue" },
  ["Search forwards and select"] = { "search.forward", "green" },
  ["Search backwards and select"] = { "search.backward", "green" },
  ["Cycle backwards through results"] = { "search.prev", "green" },
  -- Text objects from mini.ai and Snacks scope
  ["Around textobject"] = { "textobj.around", "cyan" },
  ["Inside textobject"] = { "textobj.inside", "cyan" },
  ["Around next textobject"] = { "textobj.around", "cyan" },
  ["Around last textobject"] = { "textobj.around", "cyan" },
  ["Inside next textobject"] = { "textobj.inside", "cyan" },
  ["Inside last textobject"] = { "textobj.inside", "cyan" },
  ["Move to left \"around\""] = { "textobj.around", "cyan" },
  ["Move to right \"around\""] = { "textobj.around", "cyan" },
  ["inner scope"] = { "textobj.scope", "cyan" },
  ["full scope"] = { "textobj.scope", "cyan" },
  ["jump to top edge of scope"] = { "textobj.scope_top", "cyan" },
  ["jump to bottom edge of scope"] = { "textobj.scope_bottom", "cyan" },
  -- Keys added by later tasks go above this line.
}

-- which-key group names and their icons. The key spec passes these as each
-- group's icon, so a group never falls back to which-key's guess.
M.groups = {
  ["tabs"] = { "tabs.tab", "purple" },
  ["claude"] = { "claude.claude", "orange" },
  ["buffer"] = { "buffers.list", "cyan" },
  ["code"] = { "code.code", "purple" },
  ["debug"] = { "dap.debug", "red" },
  ["file/find"] = { "search.find", "green" },
  ["git"] = { "git.git", "orange" },
  ["hunks"] = { "git.hunk", "orange" },
  ["multicursor"] = { "multicursor.cursor", "purple" },
  ["quit/session"] = { "session.session", "azure" },
  ["search"] = { "search.search", "green" },
  ["toggles"] = { "ui.toggle", "cyan" },
  ["windows"] = { "windows.window", "blue" },
  ["diagnostics/quickfix"] = { "diagnostics.group", "green" },
  ["prev"] = { "nav.prev", "azure" },
  ["next"] = { "nav.next", "azure" },
  ["goto"] = { "nav.goto", "azure" },
  ["fold"] = { "fold.fold", "blue" },
  -- Groups added by later tasks go above this line.
}

-- Snacks toggle ids and their icons. A toggle is drawn green when on and grey
-- when off, so the icon can say what it toggles rather than which way.
M.toggles = {
  autoformat = "code.autoformat",
  autoformat_buffer = "code.autoformat_buffer",
  spell = "spell.spell",
  wrap = "edit.wrap",
  relativenumber = "code.relative_numbers",
  line_number = "code.line_numbers",
  diagnostics = "diagnostics.group",
  conceallevel = "code.conceal",
  treesitter = "code.treesitter",
  inlay_hints = "code.inlay_hints",
  indent = "ui.indent_guides",
  dim = "ui.dim",
  zoom = "windows.zoom",
  zen = "ui.zen",
  words = "code.words",
  scroll = "ui.scroll",
  animate = "ui.animate",
  profiler = "ui.profiler",
  profiler_highlights = "ui.profiler_highlights",
  -- Toggles added by later tasks go above this line.
}

-- A safety net for descriptions M.keys does not list, such as a key a plugin adds
-- after an update. Lua patterns, tried in order against the lower-cased description.
-- There is deliberately no catch-all: a description none of these match falls
-- through to which-key's own rules.
M.keywords = {
  { "claude", "claude.claude", "orange" },
  { "%f[%a]ai%f[%A]", "claude.ai", "orange" },
  { "breakpoint", "dap.Breakpoint", "red" },
  { "debug", "dap.debug", "red" },
  { "%f[%a]dap%f[%A]", "dap.debug", "red" },
  { "hunk", "git.hunk", "orange" },
  { "blame", "git.blame", "orange" },
  { "diff", "git.diff", "orange" },
  { "commit", "git.commit", "orange" },
  { "branch", "git.branch", "orange" },
  { "stash", "git.stash", "orange" },
  { "lazygit", "git.lazygit", "orange" },
  { "%f[%a]git", "git.git", "orange" },
  { "github", "git.github", "orange" },
  { "diagnostic", "diagnostics.jump", "green" },
  { "problem", "diagnostics.list", "green" },
  { "%f[%a]error", "diagnostics.Error", "red" },
  { "warning", "diagnostics.Warn", "yellow" },
  { "quickfix", "lists.quickfix", "azure" },
  { "location", "lists.location", "azure" },
  { "%f[%a]todo", "todo.TODO", "yellow" },
  { "test", "code.test", "purple" },
  { "terminal", "terminal.term", "red" },
  { "format", "code.format", "purple" },
  { "rename", "code.rename", "purple" },
  { "reference", "code.references", "purple" },
  { "definition", "code.definition", "purple" },
  { "declaration", "code.declaration", "purple" },
  { "implementation", "code.implementation", "purple" },
  { "symbol", "code.symbols", "purple" },
  { "code action", "code.action", "purple" },
  { "hover", "code.hover", "purple" },
  { "signature", "code.signature", "purple" },
  { "snippet", "code.snippet", "purple" },
  { "%f[%a]lsp", "code.lsp", "purple" },
  { "treesitter", "code.treesitter", "purple" },
  { "mason", "mason.mason", "green" },
  { "lazy", "lazy.lazy", "blue" },
  { "session", "session.session", "azure" },
  { "fold", "fold.fold", "blue" },
  { "spell", "spell.spell", "yellow" },
  { "cursor", "multicursor.cursor", "purple" },
  { "window", "windows.window", "blue" },
  { "%f[%a]tab%f[%A]", "tabs.tab", "purple" },
  { "buffer", "buffers.buffer", "cyan" },
  { "folder", "files.folder", "cyan" },
  { "director", "files.folder", "cyan" },
  { "grep", "search.grep", "green" },
  { "replace", "search.replace", "green" },
  { "find", "search.find", "green" },
  { "search", "search.search", "green" },
  { "file", "files.file", "cyan" },
  { "notif", "search.notifications", "blue" },
  { "help", "search.help", "green" },
  { "keymap", "search.keymaps", "green" },
  { "toggle", "ui.toggle", "cyan" },
  { "%f[%a]quit", "actions.quit", "red" },
  { "%f[%a]exit", "actions.quit", "red" },
  { "%f[%a]save", "actions.save", "green" },
  { "comment", "code.comment", "azure" },
  { "yank", "edit.yank", "green" },
  { "%f[%a]copy", "actions.copy", "green" },
  { "paste", "actions.paste", "yellow" },
  { "delete", "edit.delete", "red" },
  { "%f[%a]close", "actions.close", "red" },
  { "%f[%a]open", "actions.open", "yellow" },
  { "preview", "ui.preview", "cyan" },
  { "markdown", "lang.markdown_outline", "blue" },
  { "latex", "lang.latex", "blue" },
  { "%f[%a]chat", "claude.chat", "orange" },
  { "%f[%a]build", "actions.build", "yellow" },
  { "%f[%a]run", "actions.run", "green" },
  { "install", "actions.install", "yellow" },
  { "update", "actions.update", "yellow" },
  { "profile", "ui.profiler", "cyan" },
  { "colou?r", "ui.palette", "cyan" },
  { "theme", "ui.palette", "cyan" },
  { "select", "edit.visual", "yellow" },
  { "%f[%a]jump", "nav.jump", "azure" },
  { "%f[%a]next", "nav.next", "azure" },
  { "%f[%a]prev", "nav.prev", "azure" },
  { "%f[%a]go to", "nav.goto", "azure" },
  { "%f[%a]goto", "nav.goto", "azure" },
  { "%f[%a]move", "actions.move", "yellow" },
}

-- File types, extensions and file names mini.icons draws wrongly or not at all:
-- each language-table file type it has no icon for, and distinct icons for the
-- hardware languages, which it otherwise draws alike.
M.filetypes = {
  bsv = { "hardware.gate_xnor", "green" },
  edn = { "lang.clojure", "blue" },
  gotmpl = { "lang.gotmpl", "blue" },
  hlsl = { "lang.shader", "blue" },
  ["javascript.jsx"] = { "lang.react", "blue" },
  ["markdown.mdx"] = { "lang.markdown_outline", "blue" },
  ocamlinterface = { "lang.ocaml", "blue" },
  ["typescript.tsx"] = { "lang.react", "blue" },
  veryl = { "hardware.gate_nand", "green" },
  xdc = { "hardware.constraint", "orange" },
  upf = { "hardware.power", "yellow" },
  verilog = { "hardware.gate_and", "green" },
  systemverilog = { "hardware.ic", "green" },
  vhdl = { "hardware.gate_xor", "green" },
  firrtl = { "hardware.netlist", "green" },
  sdc = { "hardware.timer", "orange" },
  tcl = { "lang.script", "blue" },
}
M.extensions = {
  v = { "hardware.gate_and", "green" },
  vh = { "hardware.gate_and", "green" },
  sv = { "hardware.ic", "green" },
  svh = { "hardware.ic", "green" },
  vhd = { "hardware.gate_xor", "green" },
  vhdl = { "hardware.gate_xor", "green" },
  bsv = { "hardware.gate_xnor", "green" },
  veryl = { "hardware.gate_nand", "green" },
  fir = { "hardware.netlist", "green" },
  sdc = { "hardware.timer", "orange" },
  xdc = { "hardware.constraint", "orange" },
  upf = { "hardware.power", "yellow" },
  vcd = { "hardware.waveform", "green" },
  fst = { "hardware.waveform", "green" },
  gtkw = { "hardware.waveform", "green" },
  sp = { "hardware.resistor", "green" },
  spice = { "hardware.resistor", "green" },
}
M.filenames = {
  ["lazy-lock.json"] = { "lazy.lazy", "blue" },
  ["mason-lock.json"] = { "mason.mason", "green" },
  Brewfile = { "lang.beer", "yellow" },
  [".nvim.lua"] = { "ui.neovim", "green" },
  [".latexmkrc"] = { "lang.latex", "blue" },
  justfile = { "lang.gavel", "orange" },
  Justfile = { "lang.gavel", "orange" },
  ["CLAUDE.md"] = { "claude.claude", "orange" },
}

-- The glyph a reference such as "git.branch" names, or nil when it names none.
function M.get(ref)
  local category, name = ref:match("^([%w_]+)%.([%w_]+)$")
  local t = category and vim.tbl_contains(M.vocabulary, category) and M[category]
  return t and t[name] or nil
end

local function resolve(entry)
  return entry and { icon = M.get(entry[1]), color = entry[2] } or nil
end

-- The icon and colour for a key description, or nil when M.keys has none.
function M.key(desc)
  return resolve(M.keys[desc])
end

-- The icon and colour for a which-key group name, or nil when M.groups has none.
function M.group(name)
  return resolve(M.groups[name])
end

-- which-key's icons.rules: one exact rule per M.keys description, then the
-- keyword rules. which-key tries these before its own.
function M.which_key_rules()
  local descs = vim.tbl_keys(M.keys)
  table.sort(descs)
  local rules = {}
  for _, desc in ipairs(descs) do
    local icon = M.key(desc)
    rules[#rules + 1] = { pattern = "^" .. vim.pesc(desc:lower()) .. "$", icon = icon.icon, color = icon.color }
  end
  for _, rule in ipairs(M.keywords) do
    rules[#rules + 1] = { pattern = rule[1], icon = M.get(rule[2]), color = rule[3] }
  end
  return rules
end

-- Gives a Snacks toggle its icon from M.toggles, green when on and grey when
-- off, and returns the toggle so the call can chain on to :map(). A toggle with
-- no entry keeps Snacks' default icon, and tests/test_keys.lua fails on it.
function M.toggle(toggle)
  local ref = M.toggles[toggle.opts.id]
  if ref then
    toggle.opts.icon = M.get(ref)
    toggle.opts.color = { enabled = "green", disabled = "grey" }
  end
  return toggle
end

-- mini.icons' overrides, in the shape its setup() takes.
function M.mini()
  local function shape(t)
    local out = {}
    for name, entry in pairs(t) do
      out[name] = { glyph = M.get(entry[1]), hl = "MiniIcons" .. entry[2]:sub(1, 1):upper() .. entry[2]:sub(2) }
    end
    return out
  end
  return { filetype = shape(M.filetypes), extension = shape(M.extensions), file = shape(M.filenames) }
end

-- A copy of a name-to-glyph table with a space after each glyph, the shape the
-- Snacks picker, trouble and lazy.nvim expect.
function M.spaced(t)
  local out = {}
  for name, glyph in pairs(t) do
    out[name] = glyph .. " "
  end
  return out
end

-- lazy.nvim's ui.icons table.
function M.lazy_ui()
  local icons = M.spaced(M.lazy)
  icons.loaded, icons.not_loaded, icons.list = M.lazy.loaded, M.lazy.not_loaded, M.lazy_list
  return icons
end

-- todo-comments' keywords, each with its icon. todo-comments merges these into
-- its own defaults, so every keyword keeps its colour and alternative spellings.
function M.todo_keywords()
  local out = {}
  for name, glyph in pairs(M.todo) do
    out[name] = { icon = glyph .. " " }
  end
  return out
end

return M
```

- [ ] **Let lazy.nvim draw from it**

In `lua/ach/lazy.lua`, add the `ui` line between `change_detection` and `rocks`, so the plugin manager's window uses the same icons as everything else:

```lua
  change_detection = { notify = false },
  -- Every icon in lazy.nvim's window comes from the icon database.
  ui = { icons = require("ach.icons").lazy_ui() },
  rocks = { enabled = false },
```

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all ten `test_icons` tests pass, along with every earlier test. Exit 0.

- [ ] **Commit**

```bash
git add lua/ach/icons.lua tests/test_icons.lua
git commit --only lua/ach/icons.lua lua/ach/lazy.lua tests/test_icons.lua -m "feat(icons): add the icon database for keys, groups, toggles and file types"
```

---

### Task: Status bar

**Files:**
- Create: `lua/ach/util.lua`, `lua/ach/statusline.lua`, `lua/ach/plugins/statusline.lua`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Test: `tests/test_statusline.lua`

**Interfaces:**
- Consumes: `require("ach.palette")` from the theme task; `require("ach.glyphs")` from the glyph task; `require("ach.icons")`, its `status` table and `mini()`, from the icon database task.
- Produces:
  - `require("ach.util")`: `git_root(buf?: integer): string|nil` and `root(buf?: integer): string`, the git root or else the working folder.
  - `require("ach.statusline")`: `icons` (name to glyph), `theme(): table`, `options(): table` (the lualine setup table), `setup(opts)`, and the components `git()`, `file()`, `context()`, `activity()`, `claude()`, `tools()`, `words()`, `updates()`, `format()`, each returning a statusline string, empty when it has nothing to show.
  - Optional modules the bar reads when present, defined by later plans: `require("ach.claude").status(): "connected"|"waiting"|"off"`, `require("ach.lint").linters_for(buf): string[]`, conform's `list_formatters_to_run(buf)`, and nvim-dap's `status()`. The bar reads each through `package.loaded`, so it never loads a plugin just to draw itself.
  - The variables `vim.g.autoformat` and `vim.b.autoformat`: when either is `false`, the formatter is left out of the bar, because nothing will run on save.

The bar, left to right: the mode tile; a git tile with the branch and the added, changed and removed counts; a file tile with the project folder, the file-type icon, the path relative to the project, the unsaved and read-only marks, and the code structure around the cursor (shown at 120 columns or wider); a diagnostics tile. Then, after the free space: plugin updates and the debugger; the recording register, search position and selection size; Claude; the language servers, formatter and linter; the word count; the indentation, with any unusual encoding or line ending; and the position tile in the mode's colour. A tile with nothing to show disappears together with the gap beside it.

- [ ] **Write the failing test**

`tests/test_statusline.lua`:

```lua
local function hex(s)
  return tonumber(s:sub(2), 16)
end

local function sample(t, name, lines)
  local dir = t.tmpdir()
  vim.fn.writefile(lines or { "" }, dir .. "/" .. name)
  vim.cmd("silent only")
  vim.cmd.cd(dir)
  vim.cmd.edit(dir .. "/" .. name)
  vim.b.gitsigns_status_dict = nil
  return dir
end

-- Draws the bar and returns its text and its runs of one background colour.
local function draw(columns)
  vim.o.columns = columns or 200
  require("lualine").refresh({ force = true, place = { "statusline" } })
  -- lualine writes the drawn bar into the window's own statusline value.
  local stl = vim.wo.statusline ~= "" and vim.wo.statusline or vim.go.statusline
  local res = vim.api.nvim_eval_statusline(stl, { highlights = true, maxwidth = vim.o.columns })
  local runs = {}
  for i, h in ipairs(res.highlights) do
    local stop = res.highlights[i + 1] and res.highlights[i + 1].start or #res.str
    local text = res.str:sub(h.start + 1, stop)
    -- Neovim 0.12 lists stacked groups in `groups`; the last one is drawn on top.
    local group = h.groups and h.groups[#h.groups] or h.group
    local bg = group and group ~= "" and vim.api.nvim_get_hl(0, { name = group, link = false }).bg or nil
    local last = runs[#runs]
    if last and last.bg == bg then
      last.text = last.text .. text
    elseif text ~= "" then
      table.insert(runs, { text = text, bg = bg })
    end
  end
  return res, runs
end

-- Runs fn with every optional tile given something to show, then removes the stubs.
local function with_stubs(fn)
  local saved = { claude = package.loaded["ach.claude"], lint = package.loaded["ach.lint"] }
  package.loaded["ach.claude"] = { status = function() return "connected" end }
  package.loaded["ach.lint"] = { linters_for = function() return { "selene" } end }
  vim.fn.reg_recording = function() return "q" end
  vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 3 }
  local ns = vim.api.nvim_create_namespace("ach_test_statusline")
  vim.diagnostic.set(ns, 0, {
    { lnum = 0, col = 0, message = "e", severity = vim.diagnostic.severity.ERROR },
    { lnum = 0, col = 0, message = "w", severity = vim.diagnostic.severity.WARN },
    { lnum = 0, col = 0, message = "i", severity = vim.diagnostic.severity.INFO },
    { lnum = 0, col = 0, message = "h", severity = vim.diagnostic.severity.HINT },
  })
  vim.fn.setreg("/", "a")
  vim.o.hlsearch = true
  vim.v.hlsearch = 1
  local ok, err = pcall(fn)
  package.loaded["ach.claude"], package.loaded["ach.lint"] = saved.claude, saved.lint
  vim.fn.reg_recording = nil
  vim.diagnostic.reset(ns, 0)
  vim.cmd("nohlsearch")
  if not ok then
    error(err, 0)
  end
end

return {
  ["lualine provides the components the bar uses"] = function(t)
    for _, name in ipairs({ "mode", "diagnostics", "lsp_status", "location", "progress" }) do
      t.ok(pcall(require, "lualine.components." .. name), "lualine component " .. name)
    end
  end,

  ["draws the mode tile in the mode's colour, then a one-cell gap, then the file tile"] = function(t)
    local p = require("ach.palette")
    sample(t, "alpha.lua", { "return 1" })
    local _, runs = draw()
    t.eq(runs[1].bg, hex(p.line.blue), "normal-mode tile")
    t.ok(runs[1].text:find("NORMAL", 1, true), "mode name in " .. runs[1].text)
    t.eq(runs[2], { text = " ", bg = hex(p.bg_dark) }, "gap")
    t.eq(runs[3].bg, hex(p.line.bg), "file tile")
    t.ok(runs[3].text:find("alpha.lua", 1, true), "file name in " .. runs[3].text)
  end,

  ["gives each mode its colour, with readable text"] = function(t)
    local p = require("ach.palette")
    local ratio = require("ach.contrast").ratio
    local theme = require("ach.statusline").theme()
    local want = {
      normal = "blue",
      insert = "green",
      terminal = "green",
      visual = "violet",
      command = "yellow",
      replace = "red",
    }
    for mode, colour in pairs(want) do
      t.eq(theme[mode].a.bg, p.line[colour], mode)
      t.ok(ratio(theme[mode].a.fg, theme[mode].a.bg) >= 4.5, mode .. " text contrast")
    end
    t.ok(ratio(p.line.fg, p.line.bg) >= 4.5, "tile text contrast")
  end,

  ["outside a git repository, drops the branch tile and names the working folder"] = function(t)
    local sl = require("ach.statusline")
    local p = require("ach.palette")
    local dir = sample(t, "notes.txt", { "one two" })
    local res, runs = draw()
    t.ok(not res.str:find(sl.icons.branch, 1, true), "no branch icon")
    t.eq(runs[2], { text = " ", bg = hex(p.bg_dark) }, "a single gap after the mode tile")
    t.ok(runs[3].text:find(vim.fs.basename(dir), 1, true), "working folder's name in " .. runs[3].text)
  end,

  ["inside a git repository, shows the branch and the changed-line counts"] = function(t)
    local sl = require("ach.statusline")
    local dir = sample(t, "alpha.lua", { "return 1" })
    vim.system({ "git", "init", "-q", dir }):wait()
    vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 0 }
    local res = draw()
    t.ok(res.str:find(sl.icons.branch .. " main", 1, true), "branch")
    t.ok(res.str:find(sl.icons.added .. " 2", 1, true), "added")
    t.ok(res.str:find(sl.icons.modified .. " 1", 1, true), "changed")
    t.ok(not res.str:find(sl.icons.removed, 1, true), "a zero count is hidden")
  end,

  ["shows the plain file icon for XML, whose own icon is an angle bracket"] = function(t)
    local glyphs = require("ach.glyphs")
    local own = require("mini.icons").get("file", "a.xml")
    t.ok(#glyphs.offending(own) > 0, "premise: mini.icons gives XML a forbidden icon")
    sample(t, "a.xml", { "<a/>" })
    local res = draw()
    t.ok(res.str:find(glyphs.fallback, 1, true), "plain file icon shown")
    t.ok(not res.str:find(own, 1, true), "XML's own icon not shown")
  end,

  ["names the function around the cursor"] = function(t)
    sample(t, "alpha.lua", { "local M = {}", "function M.alpha()", "  local x = 1", "  return x", "end", "return M" })
    vim.treesitter.start(0, "lua")
    vim.treesitter.get_parser(0, "lua"):parse()
    vim.api.nvim_win_set_cursor(0, { 3, 2 })
    t.eq(require("ach.statusline").context(), "M.alpha")
  end,

  ["shows a red dot and the register while recording"] = function(t)
    sample(t, "alpha.lua", { "return 1" })
    vim.fn.reg_recording = function() return "q" end
    local ok, res = pcall(draw)
    vim.fn.reg_recording = nil
    t.ok(ok, tostring(res))
    t.ok(res.str:find("\u{25CF} q", 1, true), "recording mark in " .. res.str)
  end,

  ["counts words in prose"] = function(t)
    sample(t, "note.md", { "one two three" })
    local res = draw()
    t.ok(res.str:find("3 words", 1, true), "word count in " .. res.str)
  end,

  ["draws no forbidden glyph with every tile showing"] = function(t)
    local glyphs = require("ach.glyphs")
    local found = {}
    local files = {
      { "alpha.lua", { "local M = {}", "function M.alpha()", "  return 1", "end" } },
      { "note.md", { "a b" } },
    }
    for _, file in ipairs(files) do
      sample(t, file[1], file[2])
      with_stubs(function()
        local res = draw()
        for _, cp in ipairs(glyphs.offending(res.str)) do
          table.insert(found, ("U+%04X in %s"):format(cp, file[1]))
        end
      end)
    end
    t.eq(found, {}, "forbidden glyphs in the status bar")
  end,

  ["uses no forbidden glyph among its own icons"] = function(t)
    local glyphs = require("ach.glyphs")
    local found = {}
    for name, icon in pairs(require("ach.statusline").icons) do
      if #glyphs.offending(icon) > 0 then
        table.insert(found, name)
      end
    end
    t.eq(found, {})
  end,

  ["fits an 80-column window without truncating"] = function(t)
    sample(t, "alpha.lua", { "return 1" })
    vim.b.gitsigns_status_dict = { head = "main", added = 2, changed = 1, removed = 3 }
    local res = draw(80)
    t.ok(res.width <= 80, "width " .. res.width)
    t.ok(not res.str:find("<", 1, true), "Neovim's truncation mark appeared: " .. res.str)
  end,

  ["mini.icons draws the icon database's file-type icons"] = function(t)
    local I, mini = require("ach.icons"), require("mini.icons")
    local wrong = {}
    for category, kind in pairs({ filetype = "filetypes", extension = "extensions", file = "filenames" }) do
      for name, e in pairs(I[kind]) do
        local glyph, hl = mini.get(category, name)
        local want = "MiniIcons" .. e[2]:sub(1, 1):upper() .. e[2]:sub(2)
        if glyph ~= I.get(e[1]) or hl ~= want then
          wrong[#wrong + 1] = ("%s %s draws %s in %s"):format(category, name, tostring(glyph), tostring(hl))
        end
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "file types mini.icons draws differently")
  end,
}
```

- [ ] **Run it and see it fail**

Run: `scripts/check --only test_statusline`
Expected: FAIL on every test, with `module 'lualine' not found`, `module 'lualine.components.mode' not found`, `module 'mini.icons' not found` or `module 'ach.statusline' not found`.

- [ ] **Write the helpers and the bar**

`lua/ach/util.lua`:

```lua
-- Small helpers shared by the status bar, the dashboard and the pickers.
local M = {}

-- The nearest folder at or above the buffer's file that holds .git, if any.
function M.git_root(buf)
  return vim.fs.root(buf or 0, ".git")
end

-- The buffer's project: its git root, or else the working folder.
function M.root(buf)
  return M.git_root(buf) or vim.uv.cwd()
end

return M
```

`lua/ach/statusline.lua`:

```lua
-- The status bar: square tiles on the bar's navy, one blank cell between
-- neighbours, and the outermost tile on each side in the mode's colour.
-- Colours come only from lua/ach/palette.lua, and file-type icons pass through
-- lua/ach/glyphs.lua, so nothing angled reaches the bar.
local glyphs = require("ach.glyphs")
local p = require("ach.palette")
local util = require("ach.util")

local M = {}
local line, base = p.line, p.bg_dark

-- The bar's glyphs: the status table of the icon database, where each is named
-- by its Nerd Fonts 3.5.1 name. tests/test_icons.lua keeps every one of them out
-- of the forbidden set, and the test below checks the same from the bar's side.
M.icons = require("ach.icons").status

-- Text colours inside a tile, each on the tile's own background.
M.colors = {
  text = line.fg,
  dim = line.semilightgray,
  blue = line.blue,
  green = line.green,
  violet = line.violet,
  yellow = line.yellow,
  red = line.red,
}

-- File types whose word count is shown.
M.prose = {
  markdown = true,
  ["markdown.mdx"] = true,
  mdx = true,
  tex = true,
  plaintex = true,
  text = true,
  gitcommit = true,
  typst = true,
}

local function hl(name)
  return "%#AchSl_" .. name .. "#"
end

-- Text from a file or a plugin goes through this, so a % in it prints as %.
local function esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

local icon_groups = {}

function M.set_highlights()
  icon_groups = {}
  for name, fg in pairs(M.colors) do
    vim.api.nvim_set_hl(0, "AchSl_" .. name, { fg = fg, bg = line.bg })
  end
end

-- A copy of a file-type icon's highlight group, on the tile's background.
local function icon_hl(group)
  if not icon_groups[group] then
    local name = "AchSl_icon_" .. (group:gsub("[^%w_]", "_"))
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    vim.api.nvim_set_hl(0, name, { fg = fg or tonumber(line.fg:sub(2), 16), bg = line.bg })
    icon_groups[group] = "%#" .. name .. "#"
  end
  return icon_groups[group]
end

function M.theme()
  local function mode(colour)
    return {
      a = { bg = colour, fg = p.bg, gui = "bold" },
      b = { bg = line.bg, fg = line.fg },
      c = { bg = base, fg = line.fg },
    }
  end
  local inactive = { bg = line.inactive_bg, fg = line.semilightgray }
  return {
    normal = mode(line.blue),
    insert = mode(line.green),
    terminal = mode(line.green),
    visual = mode(line.violet),
    command = mode(line.yellow),
    replace = mode(line.red),
    inactive = { a = inactive, b = inactive, c = inactive },
  }
end

function M.git()
  local g = vim.b.gitsigns_status_dict
  if type(g) ~= "table" or not g.head or g.head == "" then
    return ""
  end
  local s = hl("violet") .. M.icons.branch .. " " .. hl("text") .. esc(g.head)
  local diffs = { { "added", "added", "green" }, { "changed", "modified", "yellow" }, { "removed", "removed", "red" } }
  for _, d in ipairs(diffs) do
    local count = g[d[1]] or 0
    if count > 0 then
      s = s .. " " .. hl(d[3]) .. M.icons[d[2]] .. " " .. hl("text") .. count
    end
  end
  return s
end

function M.filetype_icon(name)
  local ok, icons = pcall(require, "mini.icons")
  if not ok then
    return glyphs.fallback, "AchSl_text"
  end
  local icon, group = icons.get("file", name)
  return glyphs.safe_icon(icon), group
end

-- Tree-sitter node kinds that name a scope worth showing.
local SCOPES = { "function", "method", "class", "struct", "impl", "module", "interface", "trait", "enum", "namespace" }

local function is_scope(kind)
  if kind:find("call", 1, true) then
    return false
  end
  for _, word in ipairs(SCOPES) do
    if kind:find(word, 1, true) then
      return true
    end
  end
  return false
end

-- A scope's name: its name field, or the identifier at the end of a C-style
-- declarator chain, or for a Rust impl the type it implements.
local function name_of(node, kind, buf)
  local target = node:field("name")[1]
  if not target then
    local d = node:field("declarator")[1]
    while d and not d:type():find("identifier", 1, true) do
      d = d:field("declarator")[1] or d:named_child(0)
    end
    target = d
  end
  if not target and kind:find("impl", 1, true) then
    target = node:field("type")[1]
  end
  if not target then
    return nil
  end
  return (vim.treesitter.get_node_text(target, buf):gsub("%s+", " "))
end

-- Where the cursor sits in the code, outermost first, such as "Parser · parse".
function M.context()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.treesitter.highlighter.active[buf] then
    return ""
  end
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
  if not ok or not node then
    return ""
  end
  local names = {}
  while node do
    local kind = node:type()
    if is_scope(kind) then
      local name = name_of(node, kind, buf)
      if name then
        table.insert(names, 1, name)
      end
    end
    node = node:parent()
  end
  local s = table.concat(names, " · ")
  local n = vim.fn.strchars(s)
  if n > 40 then
    s = "…" .. vim.fn.strcharpart(s, n - 39)
  end
  return s
end

function M.file()
  local buf = vim.api.nvim_get_current_buf()
  local root = util.root(buf)
  local s = hl("blue") .. M.icons.project .. " " .. hl("text") .. esc(vim.fs.basename(root))
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or vim.bo[buf].buftype ~= "" then
    return s
  end
  local icon, group = M.filetype_icon(name)
  local path = vim.fs.relpath(root, name) or vim.fn.fnamemodify(name, ":~")
  s = s .. "  " .. icon_hl(group) .. icon .. " " .. hl("text") .. esc(path)
  if vim.bo[buf].modified then
    s = s .. " " .. hl("yellow") .. M.icons.unsaved
  end
  if vim.bo[buf].readonly or not vim.bo[buf].modifiable then
    s = s .. " " .. hl("red") .. M.icons.readonly
  end
  local where = vim.o.columns >= 120 and M.context() or ""
  if where ~= "" then
    s = s .. "  " .. hl("dim") .. esc(where)
  end
  return s
end

function M.has_diagnostics()
  return #vim.diagnostic.get(0) > 0
end

-- The selection's size: characters within a line, lines across several, and
-- lines by columns for a block.
function M.selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return ""
  end
  local l1, c1, l2, c2 = vim.fn.line("v"), vim.fn.col("v"), vim.fn.line("."), vim.fn.col(".")
  local lines = math.abs(l2 - l1) + 1
  if mode == "\22" then
    return ("%d×%d"):format(lines, math.abs(c2 - c1) + 1)
  elseif mode == "V" or lines > 1 then
    return lines .. (lines == 1 and " line" or " lines")
  end
  local chars = math.abs(c2 - c1) + 1
  return chars .. (chars == 1 and " char" or " chars")
end

function M.activity()
  local parts = {}
  local reg = vim.fn.reg_recording()
  if reg ~= "" then
    table.insert(parts, hl("red") .. M.icons.recording .. " " .. hl("text") .. reg)
  end
  if vim.v.hlsearch == 1 then
    local ok, count = pcall(vim.fn.searchcount, { maxcount = 9999, timeout = 50 })
    if ok and (count.total or 0) > 0 then
      table.insert(parts, hl("yellow") .. M.icons.search .. " " .. hl("text") .. count.current .. "/" .. count.total)
    end
  end
  local size = M.selection()
  if size ~= "" then
    table.insert(parts, hl("violet") .. M.icons.selection .. " " .. hl("text") .. size)
  end
  return table.concat(parts, " ")
end

function M.claude()
  local claude = package.loaded["ach.claude"]
  local state = claude and claude.status() or "off"
  if state == "connected" then
    return hl("violet") .. M.icons.claude .. " Claude"
  elseif state == "waiting" then
    return hl("dim") .. M.icons.claude .. " Claude"
  end
  return ""
end

-- The formatter that will run on save and the linters watching this buffer.
function M.tools()
  local buf = vim.api.nvim_get_current_buf()
  local parts = {}
  local conform = package.loaded["conform"]
  if conform and vim.g.autoformat ~= false and vim.b[buf].autoformat ~= false then
    local names = {}
    for _, f in ipairs(conform.list_formatters_to_run(buf)) do
      table.insert(names, f.name)
    end
    if #names > 0 then
      table.insert(parts, hl("violet") .. M.icons.formatter .. " " .. hl("text") .. esc(table.concat(names, " ")))
    end
  end
  local lint = package.loaded["ach.lint"]
  if lint then
    local names = lint.linters_for(buf)
    if #names > 0 then
      table.insert(parts, hl("yellow") .. M.icons.linter .. " " .. hl("text") .. esc(table.concat(names, " ")))
    end
  end
  return table.concat(parts, " ")
end

function M.has_code_tools()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0 or M.tools() ~= ""
end

function M.words()
  if not M.prose[vim.bo.filetype] then
    return ""
  end
  local count = vim.fn.wordcount()
  local n = count.visual_words or count.words
  return hl("blue") .. M.icons.words .. " " .. hl("text") .. n .. (n == 1 and " word" or " words")
end

function M.updates()
  local parts = {}
  local ok, status = pcall(require, "lazy.status")
  if ok and status.has_updates() then
    local n = #require("lazy.manage.checker").updated
    table.insert(parts, hl("yellow") .. M.icons.updates .. " " .. hl("text") .. n)
  end
  local dap = package.loaded["dap"]
  if dap then
    local state = dap.status()
    if state ~= "" then
      table.insert(parts, hl("red") .. M.icons.dap .. " " .. hl("text") .. esc(state))
    end
  end
  return table.concat(parts, " ")
end

function M.format()
  local width = vim.bo.shiftwidth
  if width == 0 then
    width = vim.bo.tabstop
  end
  local s = hl("blue") .. M.icons.indent .. " " .. hl("text") .. (vim.bo.expandtab and "SPC " or "TAB ") .. width
  local encoding = vim.bo.fileencoding
  if encoding ~= "" and encoding ~= "utf-8" then
    s = s .. " " .. encoding
  end
  if vim.bo.fileformat ~= "unix" then
    s = s .. " " .. vim.bo.fileformat
  end
  return s
end

-- One cell of the bar's own navy, shown only when the tile beside it is.
local function gap(cond)
  return {
    function()
      return " "
    end,
    padding = 0,
    color = { bg = base },
    cond = cond,
  }
end

local function shown(fn)
  return function()
    return fn() ~= ""
  end
end

function M.options()
  local tile = { fg = line.fg, bg = line.bg }
  return {
    options = {
      theme = M.theme(),
      globalstatus = true,
      component_separators = "",
      section_separators = "",
      disabled_filetypes = { statusline = { "snacks_dashboard" } },
    },
    sections = {
      lualine_a = { { "mode", icon = M.icons.vim } },
      lualine_b = {},
      lualine_c = {
        gap(shown(M.git)),
        { M.git, color = tile },
        gap(),
        { M.file, color = tile },
        gap(M.has_diagnostics),
        {
          "diagnostics",
          color = tile,
          symbols = {
            error = M.icons.error .. " ",
            warn = M.icons.warn .. " ",
            info = M.icons.info .. " ",
            hint = M.icons.hint .. " ",
          },
          diagnostics_color = {
            error = { fg = line.red, bg = line.bg },
            warn = { fg = line.yellow, bg = line.bg },
            info = { fg = line.blue, bg = line.bg },
            hint = { fg = line.green, bg = line.bg },
          },
        },
      },
      lualine_x = {
        { M.updates, color = tile },
        gap(shown(M.updates)),
        { M.activity, color = tile },
        gap(shown(M.activity)),
        { M.claude, color = tile },
        gap(shown(M.claude)),
        -- lualine's own defaults already end a ready server with ✓, U+2713.
        { "lsp_status", icon = M.icons.lsp, color = tile },
        { M.tools, color = tile },
        gap(M.has_code_tools),
        { M.words, color = tile },
        gap(shown(M.words)),
      },
      lualine_y = { { M.format }, gap() },
      lualine_z = { { "location" }, { "progress" } },
    },
  }
end

function M.setup(opts)
  M.set_highlights()
  local group = vim.api.nvim_create_augroup("ach_statusline", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.set_highlights })
  -- Show or clear the recording mark at once, not at the next timed refresh.
  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = group,
    callback = function()
      vim.schedule(function()
        require("lualine").refresh({ place = { "statusline" } })
      end)
    end,
  })
  require("lualine").setup(opts)
end

return M
```

`lua/ach/plugins/statusline.lua`:

```lua
-- The status bar and the icon set behind it. The nvim-web-devicons stand-in
-- is adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/ui.lua.
return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-mini/mini.icons" },
    opts = function()
      return require("ach.statusline").options()
    end,
    config = function(_, opts)
      require("ach.statusline").setup(opts)
    end,
  },
  {
    "nvim-mini/mini.icons",
    -- The icon database's overrides: the hardware languages get chips, gates and
    -- waveforms, and file types mini.icons does not know get an icon of their own.
    opts = function()
      return require("ach.icons").mini()
    end,
    init = function()
      -- Plugins that ask for nvim-web-devicons get mini.icons instead.
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
}
```

- [ ] **Install lualine and mini.icons**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains `lualine.nvim` and `mini.icons`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all thirteen `test_statusline` tests pass, along with every earlier test. Exit 0. If `fits an 80-column window without truncating` fails, the bar has grown: move the newest tile behind a `vim.o.columns` condition, the way the code-structure name is, rather than widening the test.

- [ ] **Commit**

```bash
git add lua/ach/util.lua lua/ach/statusline.lua lua/ach/plugins/statusline.lua tests/test_statusline.lua
git commit --only lua/ach/util.lua lua/ach/statusline.lua lua/ach/plugins/statusline.lua tests/test_statusline.lua lazy-lock.json -m "feat(statusline): add the tiled status bar with coloured icons and no angled glyphs"
```

---

### Task: Banner and dashboard

**Files:**
- Create: `assets/banner.txt`, `lua/ach/banner.lua`, `lua/ach/dashboard.lua`, `lua/ach/plugins/dashboard.lua`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Test: `tests/test_banner.lua`, `tests/test_dashboard.lua`

**Interfaces:**
- Consumes: the highlight groups `AchBanner`, `AchBannerShadow` and `AchBannerCaption` from the theme task; `vim.g.ach_root` from the harness task; `require("ach.icons")`, its `dashboard`, `ui` and `files` tables, from the icon database task.
- Produces:
  - `require("ach.banner")`: `font` (letter to seven row strings, `X` filled), `grid(word: string, gap?: integer): string[]`, `render(word: string, indent?: integer): string[]`, `lines(): string[]` (the seventeen banner lines, trailing spaces removed), `width(lines: string[]): integer`, and `chunks(lines: string[], width?: integer): {[1]: string, hl?: string}[]`, the snacks.nvim text chunks for those lines.
  - `require("ach.dashboard")`: `caption`, `tips: string[]`, `tip_icon: string`, `tip(): string` (one tip, fixed for the session), `reserved: table<string, true>`, `extra_buttons`, `buttons(): table[]`, `add_button({ key: string, desc: string, icon: string, action: string|function })`, which raises `dashboard key "<k>" is already taken` on a clash, `min_banner_columns = 80`, and `sections(self): table[]`, the snacks dashboard section list.
  - `add_button` is the hook the owner's private `.nvim.lua` calls to add a notes button. It must be called before the dashboard opens, which happens at `UIEnter`, after `.nvim.lua` has run.
  - The global `Snacks`, loaded at startup, with `notifier` and `dashboard` enabled. Later tasks add their own snacks options in their own spec files, and lazy.nvim merges them.

- [ ] **Write the failing banner tests**

`tests/test_banner.lua`:

```lua
local banner = require("ach.banner")

return {
  ["the rule reproduces the banner the spec prints"] = function(t)
    t.eq(banner.lines(), vim.fn.readfile(t.root .. "/assets/banner.txt"))
  end,

  ["is seventeen lines and 78 columns"] = function(t)
    local lines = banner.lines()
    t.eq(#lines, 17, "line count")
    t.eq(banner.width(lines), 78, "width")
  end,

  ["shades the cell below and to the right of each filled cell"] = function(t)
    -- The letter I on its own: three filled cells on top and bottom, a
    -- one-cell stem, and the shadow one row down and one cell right.
    t.eq(banner.render("I"), {
      "██████",
      "  ██░░░░",
      "  ██░░",
      "  ██░░",
      "  ██░░",
      "  ██░░",
      "██████",
      "  ░░░░░░",
    })
  end,

  ["splits the banner into runs of one colour"] = function(t)
    local lines = banner.lines()
    local only = { AchBanner = "█", AchBannerShadow = "░" }
    local texts, mixed = {}, {}
    for _, chunk in ipairs(banner.chunks(lines)) do
      texts[#texts + 1] = chunk[1]
      local body = chunk[1]:gsub("^\n", "")
      local rest = body:gsub(vim.pesc(only[chunk.hl] or " "), "")
      if rest ~= "" then
        mixed[#mixed + 1] = vim.inspect(chunk)
      end
    end
    t.eq(mixed, {}, "chunks that mix characters")
    local rows = vim.split(table.concat(texts), "\n", { plain = true })
    t.eq(#rows, 17, "rows")
    for i, row in ipairs(rows) do
      t.eq(vim.api.nvim_strwidth(row), 78, "width of row " .. i)
      t.eq((row:gsub("%s+$", "")), lines[i], "row " .. i)
    end
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_banner`
Expected: FAIL. `test_banner` reports `module 'ach.banner' not found` and the exit code is 1.

- [ ] **Write the banner file and the lettering rule**

`assets/banner.txt` holds the seventeen lines the spec prints under its Dashboard heading, with no trailing spaces and one final newline. Copy them exactly:

```text
                    ██████        ████████    ██      ██
                  ██  ░░░░██    ██  ░░░░░░░░  ██░░    ██░░
                  ██░░    ██░░  ██░░          ██░░    ██░░
                  ██████████░░  ██░░          ██████████░░
                  ██░░░░░░██░░  ██░░          ██░░░░░░██░░
                  ██░░    ██░░  ██░░          ██░░    ██░░
                  ██░░    ██░░    ████████    ██░░    ██░░
                    ░░      ░░      ░░░░░░░░    ░░      ░░

██      ██    ██████████      ██████      ██      ██    ██████    ██      ██
████    ██░░  ██░░░░░░░░░░  ██  ░░░░██    ██░░    ██░░    ██░░░░  ████  ████░░
██░░██  ██░░  ██░░          ██░░    ██░░  ██░░    ██░░    ██░░    ██░░██  ██░░
██░░  ████░░  ████████      ██░░    ██░░  ██░░    ██░░    ██░░    ██░░  ░░██░░
██░░    ██░░  ██░░░░░░░░    ██░░    ██░░  ██░░    ██░░    ██░░    ██░░    ██░░
██░░    ██░░  ██░░          ██░░    ██░░    ██  ██  ░░    ██░░    ██░░    ██░░
██░░    ██░░  ██████████      ██████  ░░      ██  ░░    ██████    ██░░    ██░░
  ░░      ░░    ░░░░░░░░░░      ░░░░░░          ░░        ░░░░░░    ░░      ░░
```

`lua/ach/banner.lua`:

```lua
-- The ACH NEOVIM banner. Each letter is a five-by-seven grid (I is three
-- wide). A filled cell is drawn "██"; an empty cell whose upper-left
-- neighbour is filled gets the shadow "░░"; anything else is two spaces.
local M = {}

M.font = {
  A = { ".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
  C = { ".XXXX", "X....", "X....", "X....", "X....", "X....", ".XXXX" },
  E = { "XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX" },
  H = { "X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
  I = { "XXX", ".X.", ".X.", ".X.", ".X.", ".X.", "XXX" },
  M = { "X...X", "XX.XX", "X.X.X", "X...X", "X...X", "X...X", "X...X" },
  N = { "X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X" },
  O = { ".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX." },
  V = { "X...X", "X...X", "X...X", "X...X", "X...X", ".X.X.", "..X.." },
}

-- The word's seven rows of cells, letters separated by `gap` empty cells.
function M.grid(word, gap)
  local rows = {}
  for r = 1, 7 do
    local parts = {}
    for i = 1, #word do
      parts[#parts + 1] = M.font[word:sub(i, i)][r]
    end
    rows[r] = table.concat(parts, ("."):rep(gap or 2))
  end
  return rows
end

-- Eight lines: seven of letters and one of shadow. `indent` is in cells.
function M.render(word, indent)
  local g = M.grid(word)
  local cols = #g[1]
  local function filled(r, c)
    return r >= 1 and r <= 7 and c >= 1 and c <= cols and g[r]:sub(c, c) == "X"
  end
  local out = {}
  for r = 1, 8 do
    local cells = {}
    for c = 1, cols + 1 do
      cells[c] = filled(r, c) and "██" or (filled(r - 1, c - 1) and "░░" or "  ")
    end
    out[r] = (("  "):rep(indent or 0) .. table.concat(cells)):gsub("%s+$", "")
  end
  return out
end

-- ACH centred over NEOVIM, with one empty line between them.
function M.lines()
  local indent = math.floor((#M.grid("NEOVIM")[1] - #M.grid("ACH")[1]) / 2)
  local out = M.render("ACH", indent)
  out[#out + 1] = ""
  vim.list_extend(out, M.render("NEOVIM"))
  return out
end

function M.width(lines)
  local widest = 0
  for _, line in ipairs(lines) do
    widest = math.max(widest, vim.api.nvim_strwidth(line))
  end
  return widest
end

-- snacks.nvim text chunks: letters in AchBanner, shadow in AchBannerShadow,
-- spaces uncoloured. Every line is padded to the same width so snacks centres
-- the banner as one block, and each line after the first starts with "\n",
-- which is how a snacks text item breaks into rows.
function M.chunks(lines, width)
  width = width or M.width(lines)
  local colour = { ["█"] = "AchBanner", ["░"] = "AchBannerShadow" }
  local out = {}
  for i, line in ipairs(lines) do
    line = line .. (" "):rep(width - vim.api.nvim_strwidth(line))
    local run, group, first = "", false, true
    local function flush()
      if run ~= "" then
        out[#out + 1] = { (first and i > 1) and ("\n" .. run) or run, hl = group or nil }
        first = false
      end
    end
    for _, ch in ipairs(vim.fn.split(line, "\\zs")) do
      local g = colour[ch] or false
      if g ~= group then
        flush()
        run, group = "", g
      end
      run = run .. ch
    end
    flush()
  end
  return out
end

return M
```

- [ ] **Run the banner tests and see them pass**

Run: `scripts/check --only test_banner`
Expected: all four `test_banner` tests pass and the exit code is 0.

- [ ] **Write the failing dashboard tests**

`tests/test_dashboard.lua`:

```lua
local banner = require("ach.banner")
local dashboard = require("ach.dashboard")

-- Writes two files into a fresh folder, one of them inside a git repository,
-- and makes them the recent files the dashboard lists.
local function seed(t)
  local base = t.tmpdir()
  local project = base .. "/ach-dash-project"
  vim.fn.mkdir(project, "p")
  vim.fn.system({ "git", "-C", project, "init", "-q" })
  vim.fn.writefile({ "# notes" }, project .. "/ach-dash-notes.md")
  vim.fn.writefile({ "plain" }, base .. "/ach-dash-plain.txt")
  vim.v.oldfiles = { project .. "/ach-dash-notes.md", base .. "/ach-dash-plain.txt" }
end

-- Draws the dashboard in a new tab at the given width, returns its lines and
-- the highlight groups it used, then closes the tab, which wipes the buffer.
local function draw(columns)
  local saved = vim.o.columns
  vim.o.columns = columns
  vim.cmd("tabnew")
  local dash = Snacks.dashboard.open({ win = 0 })
  local lines = vim.api.nvim_buf_get_lines(dash.buf, 0, -1, false)
  local groups = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(dash.buf, -1, 0, -1, { details = true })) do
    if mark[4].hl_group then
      groups[mark[4].hl_group] = true
    end
  end
  vim.cmd("tabclose")
  vim.o.columns = saved
  return lines, groups
end

local function has(lines, text)
  return table.concat(lines, "\n"):find(text, 1, true) ~= nil
end

return {
  ["draws every part at full width"] = function(t)
    seed(t)
    local lines, groups = draw(200)
    local top = banner.lines()[1]:gsub("^%s+", "")
    local want = {
      top,
      "░░  computer architecture · post-quantum cryptography  ░░",
      "Find File",
      "Recent Files",
      "Projects",
      "Search Text",
      "Configuration",
      "Plugins",
      "Quit",
      "ach-dash-notes.md",
      "ach-dash-plain.txt",
      dashboard.tip(),
      "Neovim loaded ",
    }
    local missing = {}
    for _, text in ipairs(want) do
      if not has(lines, text) then
        missing[#missing + 1] = text
      end
    end
    t.eq(missing, {}, "parts missing from the dashboard")
    for _, group in ipairs({ "AchBanner", "AchBannerShadow", "AchBannerCaption" }) do
      t.ok(groups[group], group .. " is used")
    end
  end,

  ["lists the project a recent file belongs to"] = function(t)
    seed(t)
    local lines = draw(200)
    local found = false
    for _, line in ipairs(lines) do
      if line:find("ach-dash-project", 1, true) and not line:find("ach-dash-notes", 1, true) then
        found = true
      end
    end
    t.ok(found, "a Projects row for ach-dash-project")
  end,

  ["shows the words instead of the banner in a narrow window"] = function(t)
    seed(t)
    local lines = draw(60)
    t.ok(not has(lines, "██"), "no banner letters at 60 columns")
    t.ok(has(lines, "ACH NEOVIM"), "the words ACH NEOVIM")
    local wide = {}
    for i, line in ipairs(lines) do
      local width = vim.api.nvim_strwidth((line:gsub("%s+$", "")))
      if width > 60 then
        wide[#wide + 1] = ("line %d is %d columns"):format(i, width)
      end
    end
    t.eq(wide, {}, "lines wider than the window")
  end,

  ["offers language tools exactly when Mason is installed"] = function(t)
    local lines = draw(200)
    t.eq(has(lines, "Language Tools"), vim.fn.exists(":Mason") == 2)
  end,

  ["every button draws an icon from the icon database"] = function(t)
    local held, bad = {}, {}
    for _, glyph in pairs(require("ach.icons").dashboard) do
      held[glyph] = true
    end
    for _, b in ipairs(dashboard.buttons()) do
      if not held[b.icon] then
        bad[#bad + 1] = b.key .. " " .. b.desc
      end
    end
    t.eq(bad, {}, "buttons whose icon the database does not hold")
    t.eq(dashboard.tip_icon, require("ach.icons").dashboard.tip, "the tip's icon")
  end,

  ["shows a button added by a private .nvim.lua"] = function(t)
    local notes = require("ach.icons").dashboard.notes
    dashboard.add_button({ key = "n", desc = "Notes", icon = notes, action = function() end })
    local ok, lines = pcall(draw, 200)
    dashboard.extra_buttons = {}
    t.ok(ok, "the dashboard draws with the extra button: " .. tostring(lines))
    t.ok(has(lines, "Notes"), "the Notes button")
  end,

  ["refuses a button key that is already taken"] = function(t)
    local ok, err = pcall(dashboard.add_button, { key = "f", desc = "Other", icon = "x", action = "enew" })
    t.eq(ok, false, "adding a second f button")
    t.ok(tostring(err):find("already taken", 1, true), "the error says why, got: " .. tostring(err))
    t.eq(dashboard.extra_buttons, {}, "nothing was added")
  end,

  ["keeps one tip for the whole session"] = function(t)
    t.eq(dashboard.tip(), dashboard.tip())
    t.ok(vim.tbl_contains(dashboard.tips, dashboard.tip()), "the tip comes from the list")
  end,

  ["every tip fits a 60-column window"] = function(t)
    local long = {}
    for _, tip in ipairs(dashboard.tips) do
      local width = vim.api.nvim_strwidth(dashboard.tip_icon .. " " .. tip)
      if width > 60 then
        long[#long + 1] = ("%d: %s"):format(width, tip)
      end
    end
    t.eq(long, {}, "tips wider than 60 columns")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_dashboard`
Expected: FAIL. `test_dashboard` reports `module 'ach.dashboard' not found` and the exit code is 1.

- [ ] **Write the dashboard and its plugin spec**

`lua/ach/dashboard.lua`:

```lua
-- The start screen: the ACH NEOVIM banner, the research caption, the buttons,
-- recent files and projects, a tip that changes at each start, and the
-- startup time. snacks.nvim draws it; this module says what goes on it.
local banner = require("ach.banner")
local I = require("ach.icons")

local M = {}

-- Below this width the 78-column banner would wrap, so the words replace it.
M.min_banner_columns = 80

M.caption = {
  { "░░", hl = "AchBannerShadow" },
  { "  computer architecture · post-quantum cryptography  ", hl = "AchBannerCaption" },
  { "░░", hl = "AchBannerShadow" },
}

M.tip_icon = I.dashboard.tip
M.tips = {
  "Your configuration lives in ~/.config/nvim",
  "History, undo and sessions live in ~/.local/state/nvim",
  "Plugins and language tools live in ~/.local/share/nvim",
  "Press Space and pause to see every key that can follow",
  "Space s k searches every key by what it does",
  "Space ? lists the keys that belong to this buffer",
  "Space u f turns format on save off and on again",
  "Space q s brings back the last session in this folder",
  "Space a c opens Claude Code beside the file",
  "Space a b hands the current file to Claude Code",
  "docs/key-card.md has the everyday keys on one page",
}

local chosen
function M.tip()
  chosen = chosen or M.tips[vim.uv.hrtime() % #M.tips + 1]
  return chosen
end

-- Keys the built-in buttons use, including m, which appears once Mason does.
M.reserved = { f = true, r = true, p = true, g = true, c = true, l = true, m = true, q = true }
M.extra_buttons = {}

-- Adds a button between the built-in ones and Quit. The owner's private
-- .nvim.lua calls this for a notes button, so this repository never names
-- that folder.
function M.add_button(button)
  vim.validate("key", button.key, "string")
  vim.validate("desc", button.desc, "string")
  vim.validate("icon", button.icon, "string")
  vim.validate("action", button.action, { "string", "function" })
  local taken = M.reserved[button.key] or false
  for _, b in ipairs(M.extra_buttons) do
    taken = taken or b.key == button.key
  end
  if taken then
    error(("dashboard key %q is already taken"):format(button.key), 2)
  end
  table.insert(M.extra_buttons, { key = button.key, desc = button.desc, icon = button.icon, action = button.action })
end

function M.buttons()
  local list = {
    { key = "f", icon = I.dashboard.find_file, desc = "Find File", action = function() Snacks.picker.files() end },
    { key = "r", icon = I.dashboard.recent, desc = "Recent Files", action = function() Snacks.picker.recent() end },
    { key = "p", icon = I.dashboard.projects, desc = "Projects", action = function() Snacks.picker.projects() end },
    { key = "g", icon = I.dashboard.search_text, desc = "Search Text", action = function() Snacks.picker.grep() end },
    {
      key = "c",
      icon = I.dashboard.config,
      desc = "Configuration",
      action = function() Snacks.picker.files({ cwd = vim.g.ach_root }) end,
    },
    { key = "l", icon = I.dashboard.plugins, desc = "Plugins", action = function() vim.cmd("Lazy") end },
  }
  if vim.fn.exists(":Mason") == 2 then
    list[#list + 1] = {
      key = "m",
      icon = I.dashboard.language_tools,
      desc = "Language Tools",
      action = function() vim.cmd("Mason") end,
    }
  end
  for _, b in ipairs(M.extra_buttons) do
    list[#list + 1] = vim.tbl_extend("force", {}, b)
  end
  list[#list + 1] = { key = "q", icon = I.dashboard.quit, desc = "Quit", action = function() vim.cmd("qa") end }
  return list
end

-- The section list snacks.nvim draws, rebuilt on every redraw, so a resize
-- swaps between the banner and the words.
function M.sections(self)
  local width = vim.api.nvim_win_get_width(self.win)
  local head = width >= M.min_banner_columns and banner.chunks(banner.lines())
    or { { "ACH NEOVIM", hl = "AchBanner" } }
  local buttons = M.buttons()
  buttons.padding = 1
  return {
    { text = head, align = "center", padding = 1 },
    { text = M.caption, align = "center", padding = 1 },
    buttons,
    { icon = I.ui.clock, title = "Recent Files", section = "recent_files", limit = 8, indent = 2, padding = 1 },
    { icon = I.files.folder_search, title = "Projects", section = "projects", limit = 8, indent = 2, padding = 1 },
    { text = { { M.tip_icon .. " " .. M.tip(), hl = "footer" } }, align = "center", padding = 1 },
    { section = "startup" },
  }
end

return M
```

`lua/ach/plugins/dashboard.lua`:

```lua
-- snacks.nvim loads first of all: its notifier must catch the first message,
-- and its dashboard opens at UIEnter, after a private .nvim.lua has had the
-- chance to add a button. Other plugin files add their own snacks options.
return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      notifier = { enabled = true, timeout = 3000 },
      dashboard = {
        enabled = true,
        sections = {
          function(self)
            return require("ach.dashboard").sections(self)
          end,
        },
      },
    },
  },
}
```

- [ ] **Install snacks.nvim**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains `snacks.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all four `test_banner` tests and all nine `test_dashboard` tests pass, along with every earlier test. Exit 0. If `shows the words instead of the banner in a narrow window` fails on a recent-file line, snacks has changed how it shortens paths; read the failing line before changing anything, because the 60-column promise is the Review Focus item this test exists for.

- [ ] **Look at it once**

Run: `nvim -u init.lua` in a terminal at least 80 columns wide.
Expected: the blue ACH NEOVIM banner with its grey-blue shadow, the caption, seven buttons, the tip and the startup line. Narrow the terminal below 80 columns and the banner becomes the words `ACH NEOVIM`. Quit with `q`.

- [ ] **Commit**

```bash
git add assets/banner.txt lua/ach/banner.lua lua/ach/dashboard.lua lua/ach/plugins/dashboard.lua tests/test_banner.lua tests/test_dashboard.lua
git commit --only assets/banner.txt lua/ach/banner.lua lua/ach/dashboard.lua lua/ach/plugins/dashboard.lua tests/test_banner.lua tests/test_dashboard.lua lazy-lock.json -m "feat(dashboard): add the ACH NEOVIM banner and start screen"
```

---

### Task: Keys

**Files:**
- Modify: `lua/ach/keymaps.lua` (replace the header-only file)
- Create: `lua/ach/plugins/keys.lua`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Modify: `lua/ach/icons.lua`, only if an icon test below names a description the database lacks
- Test: `tests/test_keys.lua`

**Interfaces:**
- Consumes: `require("ach.util").root(buf?)` from the status bar task; `vim.g.ach_root` from the harness task; `vim.g.autoformat` from the options task; the global `Snacks` from the dashboard task; `require("ach.testhook")`, its `keymaps` and `keymaps_without_desc`, from the harness task; `require("ach.icons")` from the icon database task.
- Produces:
  - The Space menus: `<leader><tab>` tabs, `a` Claude, `b` buffer, `c` code, `d` debug, `f` file and find, `g` git, `m` multicursor, `q` quit and session, `s` search, `u` toggles, `w` windows, `x` diagnostics and quickfix, each a which-key group. Later tasks add keys inside these menus and add no new top-level menu without adding its group here.
  - Format on save runs only when `vim.g.autoformat ~= false and vim.b[buf].autoformat ~= false`. `<leader>uf` flips the first and `<leader>uF` the second. The languages plan's conform setup reads exactly that condition, as the status bar already does.
  - which-key carries `opts_extend = { "spec" }`, so a later task may add a group from its own plugin file with a which-key spec whose `opts.spec` lists it, and the list here grows rather than being replaced.
  - `tests/test_keys.lua` checks every plugin key any later task declares: each must carry a `desc`, and no key in `keymaps.lua` may replace one. A later task that adds a plugin key needs no test of its own for either.
  - The same file checks icons the same way. Every key this configuration sets must have its line in `M.keys` and draw that icon in which-key; every key which-key can show must get an icon from the database; every Snacks toggle and every which-key group must draw the database's icon. A later task that adds a key, a group or a toggle adds its line to `lua/ach/icons.lua` in the same commit, and wraps a new toggle in `I.toggle`, and needs no icon test of its own.
  - `[q` and `]q` are left to the trouble spec in the editor task, which falls back to the quickfix list when trouble is closed.

- [ ] **Write the failing tests**

`tests/test_keys.lua`:

```lua
local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")
local I = require("ach.icons")

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

local function mapped(lhs, mode)
  return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil
end

-- which-key hides a key with this description, so it never shows an icon.
local function shown(desc)
  return desc and desc ~= "" and desc ~= "which_key_ignore"
end

-- The first of the icon database's which-key rules that finds the description.
local function database_icon(rules, desc)
  local lower = desc:lower()
  for _, rule in ipairs(rules) do
    if lower:find(rule.pattern) then
      return rule
    end
  end
end

-- Every description in which-key's presets: operators, motions, text objects and the rest.
local function preset_descs(spec, out)
  out = out or {}
  for k, v in pairs(spec) do
    if k == "desc" and type(v) == "string" then
      out[#out + 1] = v
    elseif type(v) == "table" then
      preset_descs(v, out)
    end
  end
  return out
end

return {
  ["keys set by this configuration all have descriptions"] = function(t)
    t.eq(require("ach.testhook").keymaps_without_desc, {}, "keys without a description")
  end,

  ["every plugin key has a description"] = function(t)
    local bare = {}
    for _, k in ipairs(plugin_keys()) do
      if not k.desc or k.desc == "" then
        bare[#bare + 1] = k.plugin .. ": " .. k.id
      end
    end
    t.eq(bare, {}, "plugin keys without a description")
  end,

  ["every Space key has a description"] = function(t)
    local bare = {}
    for _, mode in ipairs({ "n", "x", "o" }) do
      for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
        local lhs = vim.fn.keytrans(m.lhsraw or m.lhs)
        if lhs:find("^<Space>") and (m.desc == nil or m.desc == "") then
          bare[#bare + 1] = mode .. " " .. lhs
        end
      end
    end
    t.eq(bare, {}, "Space keys without a description")
  end,

  ["no core key replaces a plugin's key"] = function(t)
    local lost = {}
    for _, k in ipairs(plugin_keys()) do
      if not k.ft then
        local m = vim.fn.maparg(k.lhs, k.mode, false, true)
        if m.desc ~= k.desc then
          lost[#lost + 1] = ("%s %s from %s now reads %q"):format(k.mode, k.lhs, k.plugin, m.desc or "nothing")
        end
      end
    end
    t.eq(lost, {}, "plugin keys overridden")
  end,

  ["each Space menu has a which-key group"] = function(t)
    local wk = Config.plugins["which-key.nvim"]
    t.ok(wk, "which-key.nvim is in the plugin list")
    local have = groups(Plugin.values(wk, "opts", false).spec)
    local missing = {}
    local menus = { "<leader><tab>", "<leader>a", "<leader>b", "<leader>c", "<leader>d", "<leader>f" }
    vim.list_extend(menus, { "<leader>g", "<leader>m", "<leader>q", "<leader>s" })
    vim.list_extend(menus, { "<leader>u", "<leader>w", "<leader>x" })
    for _, lhs in ipairs(menus) do
      if not have[lhs] then
        missing[#missing + 1] = lhs
      end
    end
    t.eq(missing, {}, "Space menus without a group")
  end,

  ["which-key is loaded by the time the first key is pressed"] = function(t)
    t.ok(package.loaded["which-key"], "which-key loaded at VeryLazy")
  end,

  ["the keys the spec names exist"] = function(t)
    local want = {
      "<leader><space>", "<leader>ff", "<leader>fr", "<leader>fn", "<leader>fp", "<leader>fc",
      "<leader>bb", "<leader>bd", "<leader>bo", "<leader>sh", "<leader>sk", "<leader>sg",
      "<leader>uf", "<leader>uF", "<leader>uw", "<leader>us", "<leader>ul", "<leader>uh", "<leader>uu",
      "<leader>xl", "<leader>xq", "<leader>qq", "<leader>?", "<leader>ft", "<leader>cd",
    }
    local missing = {}
    for _, lhs in ipairs(want) do
      if not mapped(lhs) then
        missing[#missing + 1] = lhs
      end
    end
    t.eq(missing, {}, "keys the spec names")
  end,

  ["Space u f flips format on save"] = function(t)
    local m = vim.fn.maparg("<leader>uf", "n", false, true)
    t.ok(m.callback, "Space u f has a function behind it")
    local before = vim.g.autoformat
    m.callback()
    t.eq(vim.g.autoformat, not before, "after one press")
    m.callback()
    t.eq(vim.g.autoformat, before, "after two presses")
  end,

  ["Space u F flips format on save for this buffer only"] = function(t)
    local m = vim.fn.maparg("<leader>uF", "n", false, true)
    t.ok(m.callback, "Space u F has a function behind it")
    m.callback()
    t.eq(vim.b.autoformat, false, "the buffer is off after one press")
    t.ok(vim.g.autoformat ~= false, "the global setting is untouched")
    m.callback()
    t.eq(vim.b.autoformat, true, "the buffer is back on after two presses")
  end,

  ["the undo tree opens through packadd"] = function(t)
    vim.cmd.packadd("nvim.undotree")
    t.eq(vim.fn.exists(":Undotree"), 2, ":Undotree after packadd nvim.undotree")
  end,

  ["every key this configuration sets draws its own icon in which-key"] = function(t)
    local wk_icons = require("which-key.icons")
    local descs = {}
    for _, k in ipairs(require("ach.testhook").keymaps) do
      if shown(k.desc) then
        descs[k.desc] = true
      end
    end
    for _, k in ipairs(plugin_keys()) do
      if shown(k.desc) then
        descs[k.desc] = true
      end
    end
    local wrong = {}
    for desc in pairs(descs) do
      local want = I.key(desc)
      local icon, hl = wk_icons.get({ desc = desc })
      if not want then
        wrong[#wrong + 1] = desc .. ": no line in M.keys"
      elseif icon ~= want.icon or hl ~= "WhichKeyIcon" .. want.color:sub(1, 1):upper() .. want.color:sub(2) then
        wrong[#wrong + 1] = desc .. ": which-key draws another icon"
      end
    end
    table.sort(wrong)
    t.eq(wrong, {}, "keys without their own icon")
  end,

  ["every key which-key can show has an icon from the database"] = function(t)
    local rules, descs = I.which_key_rules(), {}
    for _, mode in ipairs({ "n", "x", "o", "s" }) do
      for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
        if shown(m.desc) and not m.lhs:find("<Plug>", 1, true) then
          descs[m.desc] = mode .. " " .. vim.fn.keytrans(m.lhsraw or m.lhs)
        end
      end
    end
    for _, desc in ipairs(preset_descs(require("which-key.plugins.presets"))) do
      descs[desc] = descs[desc] or "which-key preset"
    end
    local bare = {}
    for desc, where in pairs(descs) do
      if not database_icon(rules, desc) then
        bare[#bare + 1] = where .. ": " .. desc
      end
    end
    table.sort(bare)
    t.eq(bare, {}, "keys the database gives no icon")
  end,

  ["every toggle and every which-key group draws the database's icon"] = function(t)
    local wk = Config.plugins["which-key.nvim"]
    t.ok(wk, "which-key.nvim is in the plugin list")
    local bad = {}
    for id, toggle in pairs(Snacks.toggle.toggles) do
      local ref = I.toggles[id]
      if not ref or toggle.opts.icon ~= I.get(ref) then
        bad[#bad + 1] = "toggle " .. id
      end
    end
    local function walk(spec)
      for _, item in ipairs(spec or {}) do
        if type(item) == "table" then
          if type(item[1]) == "string" and item.group then
            local want, got = I.group(item.group), item.icon
            if not want or type(got) ~= "table" or got.icon ~= want.icon or got.color ~= want.color then
              bad[#bad + 1] = "group " .. item.group
            end
          end
          walk(item)
        end
      end
    end
    walk(Plugin.values(wk, "opts", false).spec)
    table.sort(bad)
    t.eq(bad, {}, "toggles and groups without the database's icon")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_keys`
Expected: FAIL on `each Space menu has a which-key group` (`which-key.nvim is in the plugin list`), `which-key is loaded by the time the first key is pressed`, `the keys the spec names exist` (every key listed as missing), both format tests (`has a function behind it`), and the three icon tests (`module 'which-key.icons' not found`, `module 'which-key.plugins.presets' not found` and `which-key.nvim is in the plugin list`). Five pass already: the four checks on descriptions and overrides, because nothing defines a key yet, and `the undo tree opens through packadd`, which guards the built-in route `Space u u` relies on.

- [ ] **Write the core keys**

`lua/ach/keymaps.lua` (replace the whole file):

```lua
-- Core keys. Every key carries a description, which which-key shows and
-- tests/test_keys.lua checks. Plugin keys live in their plugin specs, and no
-- key here may replace one; the test checks that too.
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/config/keymaps.lua.
local map = vim.keymap.set
local I = require("ach.icons")

local function root()
  return require("ach.util").root()
end

-- Move by screen line through a wrapped line, unless a count is given.
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Windows.
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- Move lines. Option works as Alt once Ghostty's macos-option-as-alt is set.
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Buffers.
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })

-- Escape also clears the search highlight.
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })
map("n", "<leader>ur", "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>", { desc = "Redraw / Clear hlsearch" })

-- n always searches forward and N backward, whichever way the search began.
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Files.
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
map("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied " .. path, vim.log.levels.INFO, { title = "File path" })
end, { desc = "Copy File Path" })

-- Keep the selection after shifting it.
map("x", "<", "<gv", { desc = "Indent Left" })
map("x", ">", ">gv", { desc = "Indent Right" })

-- A comment line above or below, in the file's own comment syntax.
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- Location and quickfix lists. [q and ]q belong to the trouble spec.
map("n", "<leader>xl", function()
  local open = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  local ok, err = pcall(open and vim.cmd.lclose or vim.cmd.lopen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  local open = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  local ok, err = pcall(open and vim.cmd.cclose or vim.cmd.copen)
  if not ok and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

-- Diagnostics: jump, then show the message under the cursor.
local function jump(count, severity)
  return function()
    local found = vim.diagnostic.jump({
      count = count * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
    })
    if found then
      vim.diagnostic.open_float({ scope = "cursor", focus = false })
    end
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", jump(1), { desc = "Next Diagnostic" })
map("n", "[d", jump(-1), { desc = "Prev Diagnostic" })
map("n", "]e", jump(1, "ERROR"), { desc = "Next Error" })
map("n", "[e", jump(-1, "ERROR"), { desc = "Prev Error" })
map("n", "]w", jump(1, "WARN"), { desc = "Next Warning" })
map("n", "[w", jump(-1, "WARN"), { desc = "Prev Warning" })

-- Toggles under Space u. which-key shows each one's current state, and I.toggle
-- gives each its icon from the database, green when on and grey when off. The
-- two format toggles carry ids because the database looks a toggle up by id.
I.toggle(Snacks.toggle({
  id = "autoformat",
  name = "Format on Save (all buffers)",
  get = function() return vim.g.autoformat ~= false end,
  set = function(state) vim.g.autoformat = state end,
})):map("<leader>uf")
I.toggle(Snacks.toggle({
  id = "autoformat_buffer",
  name = "Format on Save (this buffer)",
  get = function() return vim.b.autoformat ~= false end,
  set = function(state) vim.b.autoformat = state end,
})):map("<leader>uF")
I.toggle(Snacks.toggle.option("spell", { name = "Spelling" })):map("<leader>us")
I.toggle(Snacks.toggle.option("wrap", { name = "Wrap" })):map("<leader>uw")
I.toggle(Snacks.toggle.option("relativenumber", { name = "Relative Number" })):map("<leader>uL")
I.toggle(Snacks.toggle.line_number()):map("<leader>ul")
I.toggle(Snacks.toggle.diagnostics()):map("<leader>ud")
I.toggle(Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal" })):map("<leader>uc")
I.toggle(Snacks.toggle.treesitter()):map("<leader>uT")
I.toggle(Snacks.toggle.inlay_hints()):map("<leader>uh")
I.toggle(Snacks.toggle.indent()):map("<leader>ug")
I.toggle(Snacks.toggle.dim()):map("<leader>uD")
I.toggle(Snacks.toggle.zoom()):map("<leader>wm"):map("<leader>uZ")
I.toggle(Snacks.toggle.zen()):map("<leader>uz")

-- The undo tree ships with Neovim 0.12 as an optional package.
map("n", "<leader>uu", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd("Undotree")
end, { desc = "Undo Tree" })
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- Terminal. Ghostty sends Control-/ as itself; older terminals send Control-_.
map("n", "<leader>fT", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function() Snacks.terminal(nil, { cwd = root() }) end, { desc = "which_key_ignore" })

-- Tabs.
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })

-- Quit, and the plugin manager.
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
```

`lua/ach/plugins/keys.lua`:

```lua
-- which-key draws every key that can follow Space after a short pause, and
-- snacks.picker is the finder behind the f and s menus.
-- The picker keys are adapted from LazyVim (Apache-2.0),
-- lua/lazyvim/plugins/extras/editor/snacks_picker.lua.
-- Every icon comes from lua/ach/icons.lua: the groups' icons directly, each
-- key's through the rules which-key tries before its own.
local I = require("ach.icons")

local function root()
  return require("ach.util").root()
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    -- A later plugin file may add groups with its own which-key spec; this makes
    -- lazy.nvim join the lists instead of letting the later one replace this one.
    opts_extend = { "spec" },
    opts = {
      preset = "helix",
      icons = { rules = I.which_key_rules() },
      spec = {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "tabs", icon = I.group("tabs") },
          { "<leader>a", group = "claude", icon = I.group("claude") },
          {
            "<leader>b",
            group = "buffer",
            icon = I.group("buffer"),
            expand = function()
              return require("which-key.extras").expand.buf()
            end,
          },
          { "<leader>c", group = "code", icon = I.group("code") },
          { "<leader>d", group = "debug", icon = I.group("debug") },
          { "<leader>f", group = "file/find", icon = I.group("file/find") },
          { "<leader>g", group = "git", icon = I.group("git") },
          { "<leader>gh", group = "hunks", icon = I.group("hunks") },
          { "<leader>m", group = "multicursor", icon = I.group("multicursor") },
          { "<leader>q", group = "quit/session", icon = I.group("quit/session") },
          { "<leader>s", group = "search", icon = I.group("search") },
          { "<leader>u", group = "toggles", icon = I.group("toggles") },
          {
            "<leader>w",
            group = "windows",
            icon = I.group("windows"),
            proxy = "<c-w>",
            expand = function()
              return require("which-key.extras").expand.win()
            end,
          },
          { "<leader>x", group = "diagnostics/quickfix", icon = I.group("diagnostics/quickfix") },
          { "[", group = "prev", icon = I.group("prev") },
          { "]", group = "next", icon = I.group("next") },
          { "g", group = "goto", icon = I.group("goto") },
          { "z", group = "fold", icon = I.group("fold") },
        },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        enabled = true,
        icons = { kinds = I.spaced(I.kinds), diagnostics = I.spaced(I.diagnostics) },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader><space>", function() Snacks.picker.files({ cwd = root() }) end, desc = "Find Files (Root Dir)" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() Snacks.picker.grep({ cwd = root() }) end, desc = "Grep (Root Dir)" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      -- find
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.g.ach_root }) end, desc = "Find Config File" },
      { "<leader>ff", function() Snacks.picker.files({ cwd = root() }) end, desc = "Find Files (Root Dir)" },
      { "<leader>fF", function() Snacks.picker.files() end, desc = "Find Files (cwd)" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, desc = "Recent (cwd)" },
      -- search
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
      { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
      { "<leader>sg", function() Snacks.picker.grep({ cwd = root() }) end, desc = "Grep (Root Dir)" },
      { "<leader>sG", function() Snacks.picker.grep() end, desc = "Grep (cwd)" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
      { "<leader>sw", function() Snacks.picker.grep_word({ cwd = root() }) end, desc = "Selection or Word (Root Dir)", mode = { "n", "x" } },
      { "<leader>sW", function() Snacks.picker.grep_word() end, desc = "Selection or Word (cwd)", mode = { "n", "x" } },
    },
  },
}
```

- [ ] **Install which-key**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains `which-key.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all thirteen `test_keys` tests pass, along with every earlier test. Exit 0. If `every key which-key can show has an icon from the database` fails, each line names the mode, the key and the description: add that description to `M.keys` above its marker line in `lua/ach/icons.lua`, choosing a glyph from the vocabulary, or add a keyword when several descriptions share a word. If the toggle and group test fails, wrap the named toggle in `I.toggle` and give its id a line in `M.toggles`, or give the group's `icon` field `I.group(name)` and its name a line in `M.groups`. If `no core key replaces a plugin's key` fails, the message names the key, the plugin it belonged to and the description now on it: delete the line in `keymaps.lua`, never the plugin's key.

- [ ] **Try the menus once**

Run: `nvim -u init.lua`, then press Space and wait.
Expected: which-key opens at the bottom with the groups listed above, each with a word and an icon. Press `u` and the toggles show their current state. Press Escape twice to close it, then `q` on the dashboard to quit.

- [ ] **Commit**

```bash
git add lua/ach/plugins/keys.lua tests/test_keys.lua
git commit --only lua/ach/keymaps.lua lua/ach/plugins/keys.lua lua/ach/icons.lua tests/test_keys.lua lazy-lock.json -m "feat(keys): add the core keys, the which-key menus and the picker keys"
```

---

### Task: Editor plugins

**Files:**
- Create: `lua/ach/plugins/editor.lua`, `lua/ach/plugins/ui.lua`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Modify: `lua/ach/icons.lua`, only if `test_keys` names one of this task's keys as having no icon of its own
- Test: `tests/test_editor.lua`

**Interfaces:**
- Consumes: `require("ach.util").root(buf?)` from the status bar task; the global `Snacks` and the snacks spec with `lazy = false` from the dashboard task; the which-key groups `c`, `f`, `m`, `q`, `s`, `u` and `x` from the keys task; `laststatus = 3` and `splitkeep = "screen"` from the options task, which edgy needs; the terminal keys `<c-/>` and `Space f t` from the keys task, whose windows edgy docks; `require("ach.icons")` from the icon database task, its `kinds` and `todo` tables and its `spaced` and `todo_keywords` helpers.
- Produces:
  - `[q` and `]q` step through trouble's list while trouble is open and through the quickfix list otherwise. At either end of the quickfix list they warn instead of raising.
  - `nvim <folder>` opens the snacks explorer rather than netrw, and `Space e` opens it at the project root. Oil is reached only through `Space f o` and `:Oil`, so it never takes over a folder by itself.
  - `vim.o.statuscolumn` is snacks' column. The languages plan's diagnostics and the integrations plan's git signs draw into it and set no `statuscolumn` of their own.
  - snacks `words` is on. The languages plan binds `]]` and `[[` to `Snacks.words.jump` in its language-server attach handler, since the references it jumps between come from a server.
  - Trouble opens docked at the bottom, or on the right for `Space c S`, through edgy. The languages plan's server lists open in trouble and need no layout of their own.
  - Trouble's symbol icons and todo-comments' keyword icons come from the icon database. todo-comments keeps its own colours and alternate names, such as `FIXME` for `FIX`, because the database supplies only the icon.

- [ ] **Write the failing tests**

`tests/test_editor.lua`:

```lua
local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Keys = require("lazy.core.handler.keys")

local function mapped(lhs, mode)
  return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil
end

-- The function a plugin's spec binds to a normal-mode key. Calling lazy's stub
-- instead would replay the keys later, after the test has finished looking.
local function bound(plugin, lhs)
  local spec = Config.plugins[plugin]
  assert(spec, plugin .. " is not in the plugin list")
  for _, k in pairs(Keys.resolve(Plugin.values(spec, "keys", true))) do
    if k.lhs == lhs and k.mode == "n" then
      return k.rhs
    end
  end
  error(plugin .. " binds nothing to " .. lhs)
end

-- A three-line file with one quickfix entry per line, positioned on the first.
local function three_item_list(t)
  local file = t.tmpdir() .. "/three.txt"
  vim.fn.writefile({ "one", "two", "three" }, file)
  vim.fn.setqflist({}, " ", {
    items = {
      { filename = file, lnum = 1, text = "one" },
      { filename = file, lnum = 2, text = "two" },
      { filename = file, lnum = 3, text = "three" },
    },
  })
  vim.cmd("cfirst")
  return file
end

local function qf_index()
  return vim.fn.getqflist({ idx = 0 }).idx
end

local function wipe(file)
  vim.fn.setqflist({}, "r")
  vim.cmd("silent! bwipeout! " .. vim.fn.fnameescape(file))
end

return {
  ["the keys the spec names exist"] = function(t)
    local want = {
      { "<leader>e" }, { "<leader>fe" }, { "<leader>fo" }, { "<leader>sr" }, { "<leader>xx" }, { "<leader>xX" },
      { "<leader>cs" }, { "<leader>xL" }, { "<leader>xQ" }, { "[q" }, { "]q" }, { "]t" }, { "[t" },
      { "<leader>st" }, { "<leader>xt" }, { "<leader>qs" }, { "<leader>ql" }, { "<leader>qS" }, { "<leader>qd" },
      { "<leader>mn" }, { "<leader>mA" }, { "<A-Down>" }, { "<leader>ue" }, { "s" }, { "s", "x" }, { "s", "o" },
      { "S" }, { "<c-space>" }, { "<c-s>", "c" },
    }
    local missing = {}
    for _, k in ipairs(want) do
      if not mapped(k[1], k[2]) then
        missing[#missing + 1] = (k[2] or "n") .. " " .. k[1]
      end
    end
    t.eq(missing, {}, "keys the spec names")
  end,

  ["]q and [q walk the quickfix list while trouble is closed"] = function(t)
    local next_item, prev_item = bound("trouble.nvim", "]q"), bound("trouble.nvim", "[q")
    local file = three_item_list(t)
    t.ok(not require("trouble").is_open(), "trouble starts closed")
    next_item()
    local index, line = qf_index(), vim.fn.line(".")
    prev_item()
    local back = qf_index()
    wipe(file)
    t.eq(index, 2, "quickfix entry after ]q")
    t.eq(line, 2, "cursor line after ]q")
    t.eq(back, 1, "quickfix entry after [q")
  end,

  ["]q on the last entry warns instead of raising"] = function(t)
    local next_item = bound("trouble.nvim", "]q")
    local file = three_item_list(t)
    vim.cmd("clast")
    local ok, err = pcall(next_item)
    local index = qf_index()
    wipe(file)
    t.ok(ok, "]q raised: " .. tostring(err))
    t.eq(index, 3, "quickfix entry after ]q on the last one")
  end,

  ["sessions are saved under the state folder, never in the repository"] = function(t)
    require("lazy").load({ plugins = { "persistence.nvim" } })
    local dir = require("persistence.config").options.dir
    t.ok(vim.startswith(dir, vim.fn.stdpath("state")), "sessions go to " .. tostring(dir))
    t.ok(not vim.startswith(dir, t.root), "sessions go into the repository: " .. tostring(dir))
  end,

  ["a hex colour gets a swatch"] = function(t)
    require("lazy").load({ plugins = { "mini.hipatterns" } })
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "border = #547998" })
    require("mini.hipatterns").enable(buf)
    -- mini.hipatterns names the group after the lower-case digits and the style.
    local group = "MiniHipatterns_547998_bg"
    local found = vim.wait(2000, function()
      for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
        if m[4].hl_group == group then
          return true
        end
      end
      return false
    end, 50)
    vim.api.nvim_buf_delete(buf, { force = true })
    t.ok(found, "no " .. group .. " highlight on the hex colour")
  end,

  ["the status column is drawn by snacks"] = function(t)
    t.ok(vim.o.statuscolumn:find("snacks.statuscolumn", 1, true), "statuscolumn is " .. vim.o.statuscolumn)
  end,

  ["oil opens a folder as an editable buffer"] = function(t)
    local dir = t.tmpdir()
    vim.fn.writefile({}, dir .. "/a.txt")
    vim.cmd("Oil " .. vim.fn.fnameescape(dir))
    local opened = vim.wait(3000, function()
      return vim.bo.filetype == "oil"
    end, 50)
    local ft, name = vim.bo.filetype, vim.api.nvim_buf_get_name(0)
    vim.cmd("silent! bwipeout!")
    t.ok(opened, "filetype is " .. ft .. " in " .. name)
    t.ok(vim.startswith(name, "oil://"), "buffer name is " .. name)
  end,

  ["trouble and todo-comments draw the icon database's icons"] = function(t)
    local I = require("ach.icons")
    local trouble = Config.plugins["trouble.nvim"]
    t.ok(trouble, "trouble.nvim is in the plugin list")
    local kinds = Plugin.values(trouble, "opts", false).icons.kinds
    t.eq(kinds.Function, I.kinds.Function .. " ", "trouble's Function icon")
    -- todo-comments finishes its setup on the first tick after startup, so wait for it.
    require("lazy").load({ plugins = { "todo-comments.nvim" } })
    local todo = require("todo-comments.config")
    t.ok(vim.wait(2000, function() return todo.loaded end, 20), "todo-comments finished its setup")
    t.eq(todo.options.keywords.TODO.icon, I.todo.TODO .. " ", "the TODO icon")
    t.eq(todo.options.keywords.FIX.color, "error", "FIX keeps todo-comments' own colour")
    t.ok(vim.tbl_contains(todo.options.keywords.FIX.alt, "FIXME"), "FIX keeps FIXME as an alternate name")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_editor`
Expected: FAIL on all eight `test_editor` tests, then `0 passed, 8 failed, 0 need a person, 0 skipped`, exit 1. The keys test lists every key as missing, the two quickfix tests stop at `trouble.nvim is not in the plugin list`, the icon test at `trouble.nvim is in the plugin list`, `:Oil` is not an editor command, `vim.o.statuscolumn` is empty, and the persistence and hipatterns modules are not found.

- [ ] **Write the editor plugins**

`lua/ach/plugins/editor.lua`:

```lua
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/editor.lua, lua/lazyvim/plugins/util.lua
-- and lua/lazyvim/plugins/extras/editor/snacks_explorer.lua, for the flash, grug-far, trouble,
-- todo-comments, persistence and explorer specs.
local I = require("ach.icons")

local function root()
  return require("ach.util").root()
end

-- [q and ]q walk trouble's list while it is open and the quickfix list otherwise.
-- At either end of the quickfix list Neovim raises E553; that is news, not a fault.
local function step(dir)
  if require("trouble").is_open() then
    require("trouble")[dir]({ jump = true })
    return
  end
  local ok, err = pcall(vim.cmd[dir == "next" and "cnext" or "cprev"])
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

local function mc()
  return require("multicursor-nvim")
end

return {
  -- Jump to any spot on screen by typing two or three of its letters.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Select by Syntax" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash Remote" },
      {
        "R",
        mode = { "o", "x" },
        function() require("flash").treesitter_search() end,
        desc = "Flash Search by Syntax",
      },
      { "<c-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle Flash in Search" },
      {
        "<c-space>",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter({ actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" } })
        end,
        desc = "Grow Selection by Syntax",
      },
    },
  },

  -- Project-wide search and replace in a buffer you edit like any other.
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sr",
        function()
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          require("grug-far").open({
            transient = true,
            prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
          })
        end,
        mode = { "n", "x" },
        desc = "Search and Replace",
      },
    },
  },

  -- The problem list: diagnostics, symbols, references, quickfix and location lists.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      modes = { lsp = { win = { position = "right" } } },
      icons = { kinds = I.spaced(I.kinds) },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Problems (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Problems in This Buffer (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "Definitions and References (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      { "[q", function() step("prev") end, desc = "Previous Problem or Quickfix Entry" },
      { "]q", function() step("next") end, desc = "Next Problem or Quickfix Entry" },
    },
  },

  -- TODO, FIX, HACK, NOTE and WARN comments, highlighted and searchable.
  {
    "folke/todo-comments.nvim",
    cmd = "TodoTrouble",
    event = { "BufReadPost", "BufNewFile" },
    -- Only the icons change; the colours and alternate names stay todo-comments' own.
    opts = { keywords = I.todo_keywords() },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO Comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODO Comments (Trouble)" },
      {
        "<leader>xT",
        "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
        desc = "TODO and FIX Comments (Trouble)",
      },
      -- todo-comments registers this picker source with snacks when it loads, and pressing
      -- the key loads it first.
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "TODO Comments" },
      {
        "<leader>sT",
        function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end,
        desc = "TODO and FIX Comments",
      },
    },
  },

  -- A folder as a text buffer: rename a line to rename the file, delete it to delete the file.
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    opts = { default_file_explorer = false, view_options = { show_hidden = true } },
    keys = {
      { "<leader>fo", function() require("oil").open() end, desc = "Open Folder as Text (oil)" },
    },
  },

  -- One session per folder, saved on quit under ~/.local/state/nvim/sessions.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session for This Folder" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Pick a Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save This Session" },
    },
  },

  -- Several cursors that edit together.
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
      local m = mc()
      m.setup()
      -- These keys exist only while there is more than one cursor.
      m.addKeymapLayer(function(set)
        set({ "n", "x" }, "<left>", m.prevCursor, { desc = "Previous Cursor" })
        set({ "n", "x" }, "<right>", m.nextCursor, { desc = "Next Cursor" })
        set({ "n", "x" }, "<leader>md", m.deleteCursor, { desc = "Delete This Cursor" })
        set("n", "<esc>", function()
          if not m.cursorsEnabled() then
            m.enableCursors()
          else
            m.clearCursors()
          end
        end, { desc = "Clear Cursors" })
      end)
    end,
    keys = {
      { "<leader>mn", function() mc().matchAddCursor(1) end, mode = { "n", "x" }, desc = "Add Cursor at Next Match" },
      {
        "<leader>mN",
        function() mc().matchAddCursor(-1) end,
        mode = { "n", "x" },
        desc = "Add Cursor at Previous Match",
      },
      { "<leader>ms", function() mc().matchSkipCursor(1) end, mode = { "n", "x" }, desc = "Skip to Next Match" },
      { "<leader>mS", function() mc().matchSkipCursor(-1) end, mode = { "n", "x" }, desc = "Skip to Previous Match" },
      {
        "<leader>mA",
        function() mc().matchAllAddCursors() end,
        mode = { "n", "x" },
        desc = "Add Cursors at Every Match",
      },
      { "<leader>mx", function() mc().toggleCursor() end, mode = { "n", "x" }, desc = "Add or Remove a Cursor Here" },
      { "<leader>ma", function() mc().alignCursors() end, desc = "Align Cursors" },
      -- Ctrl with the arrows resizes windows (keymaps.lua), so Option adds cursors.
      { "<A-Up>", function() mc().lineAddCursor(-1) end, mode = { "n", "x" }, desc = "Add Cursor Above" },
      { "<A-Down>", function() mc().lineAddCursor(1) end, mode = { "n", "x" }, desc = "Add Cursor Below" },
    },
  },

  -- The file tree with git status, and two guards for very large or first-opened files.
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = true },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
    },
    keys = {
      { "<leader>fe", function() Snacks.explorer({ cwd = root() }) end, desc = "File Tree (project)" },
      { "<leader>fE", function() Snacks.explorer() end, desc = "File Tree (working folder)" },
      { "<leader>e", "<leader>fe", desc = "File Tree (project)", remap = true },
      { "<leader>E", "<leader>fE", desc = "File Tree (working folder)", remap = true },
    },
  },
}
```

`lua/ach/plugins/ui.lua`:

```lua
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/ui/edgy.lua, for the edgy spec.
-- The panes for plugins this configuration does not use are left out.

return {
  -- Help, the terminal, the problem list and search-and-replace dock into fixed panes.
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>ue", function() require("edgy").toggle() end, desc = "Toggle Docked Panes" },
      { "<leader>uE", function() require("edgy").select() end, desc = "Pick a Docked Pane" },
    },
    opts = function()
      local opts = {
        bottom = {
          { ft = "qf", title = "QuickFix" },
          {
            ft = "help",
            size = { height = 20 },
            -- A help file opened for editing is an ordinary file, not a docked page.
            filter = function(buf)
              return vim.bo[buf].buftype == "help"
            end,
          },
        },
        right = {
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
        -- Inside a docked pane, Ctrl and the arrows resize the pane.
        keys = {
          ["<c-Right>"] = function(win)
            win:resize("width", 2)
          end,
          ["<c-Left>"] = function(win)
            win:resize("width", -2)
          end,
          ["<c-Up>"] = function(win)
            win:resize("height", 2)
          end,
          ["<c-Down>"] = function(win)
            win:resize("height", -2)
          end,
        },
      }
      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "trouble",
          filter = function(_, win)
            local w = vim.w[win].trouble
            return w and w.position == pos and w.type == "split" and w.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
        table.insert(opts[pos], {
          ft = "snacks_terminal",
          size = { height = 0.4 },
          title = "%{b:snacks_terminal.id}: %{b:term_title}",
          filter = function(_, win)
            local w = vim.w[win].snacks_win
            return w and w.position == pos and w.relative == "editor" and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },

  -- Each nesting level of brackets in its own colour, from tokyonight's rainbow groups.
  -- It reads no options, so lazy.nvim only has to put it on the runtime path.
  { "HiPhish/rainbow-delimiters.nvim", event = { "BufReadPre", "BufNewFile" } },

  -- A swatch behind every hex colour such as #rrggbb.
  {
    "nvim-mini/mini.hipatterns",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      return { highlighters = { hex_color = require("mini.hipatterns").gen_highlighter.hex_color() } }
    end,
  },

  -- Indent guides, the current scope, highlights on other uses of the word under the
  -- cursor, the line-number column and the input box.
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = true },
      scope = { enabled = true },
      words = { enabled = true },
      statuscolumn = { enabled = true },
      input = { enabled = true },
    },
  },
}
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains `edgy.nvim`, `flash.nvim`, `grug-far.nvim`, `mini.hipatterns`, `multicursor.nvim`, `oil.nvim`, `persistence.nvim`, `rainbow-delimiters.nvim`, `todo-comments.nvim` and `trouble.nvim`.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all eight `test_editor` tests pass, along with every earlier test, and `test_keys` now checks the new plugin keys too: each has a description and its own icon, and none is replaced by a core key. Exit 0. If it names one of this task's keys as having no line in `M.keys`, add that line above the marker in `lua/ach/icons.lua`.

- [ ] **Look at it once**

Run: `nvim -u init.lua lua/ach/util.lua`
Expected: the line numbers sit in snacks' column, indent guides show, and nested brackets cycle through colours. `Space e` opens the file tree with git status beside changed files, and `q` closes it. `Space s r` opens search and replace docked on the right. `:help windows` docks help at the bottom. `s` and two letters jump to any match on screen. On a word, `Space m n` twice gives three cursors that type together, and Escape clears them. `Space f o` shows the folder as text. Quit with `Space q q`.

- [ ] **Commit**

```bash
git add lua/ach/plugins/editor.lua lua/ach/plugins/ui.lua tests/test_editor.lua
git commit --only lua/ach/plugins/editor.lua lua/ach/plugins/ui.lua lua/ach/icons.lua tests/test_editor.lua lazy-lock.json -m "feat(editor): add jumping, search and replace, the problem list, sessions and docked panes"
```

---

### Task: Completion

**Files:**
- Create: `lua/ach/plugins/coding.lua`
- Create: `snippets/package.json`, `snippets/all.json`, `snippets/tex.json`, `snippets/lua.json`
- Create: `scripts/fetch-matcher`
- Modify: `lazy-lock.json` (by `Lazy! sync`)
- Test: `tests/test_completion.lua`

**Interfaces:**
- Consumes: `vim.g.ach_root` from the harness task; the keys task's guard that no core key replaces a plugin key; `require("ach.icons").kinds` from the icon database task.
- Produces:
  - The completion menu's kind icons are the icon database's `kinds` table. A source that brings a new kind adds its line to `M.kinds` in `lua/ach/icons.lua`.
  - blink.cmp with `opts_extend = { "sources.default" }`. The languages plan adds a source by adding a blink spec whose `opts.sources.default` lists it and whose `opts.sources.providers` defines it, as it does for lazydev; the four sources here stay.
  - blink sets `vim.lsp.config("*", { capabilities = … })` only when it loads, at the first `InsertEnter`, which can come after a server has started. The languages plan's server engine therefore calls `require("blink.cmp").get_lsp_capabilities()` itself before it enables any server.
  - `snippets/` in VS Code format. A new language gets a file there and a line in `snippets/package.json`, and `tests/test_completion.lua` checks it with no change.
  - `scripts/fetch-matcher`, which downloads blink's compiled matcher and exits 0 only when it is in use. The owner's bootstrap runs it on a new machine.
  - mini.ai's `f`, `c` and `o` objects read the Tree-sitter text-object queries. The languages plan installs `nvim-treesitter-textobjects`, which ships them; until then those three report that no object was found, and every other object works.

- [ ] **Write the failing tests**

`tests/test_completion.lua`:

```lua
local function mapped(lhs, mode)
  return next(vim.fn.maparg(lhs, mode or "n", false, true)) ~= nil
end

local function blink_config()
  require("lazy").load({ plugins = { "blink.cmp" } })
  return require("blink.cmp.config")
end

local function read_json(path)
  local fd = assert(io.open(path, "r"))
  local data = fd:read("*a")
  fd:close()
  return vim.json.decode(data)
end

return {
  ["the compiled matcher is installed"] = function(t)
    require("lazy").load({ plugins = { "blink.cmp" } })
    if not pcall(require, "blink.cmp.fuzzy.rust") then
      t.human("blink.cmp's compiled matcher is missing: run scripts/fetch-matcher")
    end
  end,

  ["completion draws on the language server, paths, snippets and open files"] = function(t)
    local default = blink_config().sources.default
    local missing = {}
    for _, name in ipairs({ "lsp", "path", "snippets", "buffer" }) do
      if not vim.tbl_contains(default, name) then
        missing[#missing + 1] = name
      end
    end
    t.eq(missing, {}, "completion sources")
  end,

  ["our snippets reach blink"] = function(t)
    local opts = vim.deepcopy(blink_config().sources.providers.snippets.opts)
    -- Only the configured folder, so a friendly-snippets prefix cannot stand in for ours.
    opts.friendly_snippets = false
    local registry = require("blink.cmp.sources.snippets.default.registry").new(opts)
    local want = { all = { "today" }, lua = { "mod" }, tex = { "align", "eq", "ex", "frac", "mk", "thm" } }
    local missing = {}
    for ft, prefixes in pairs(want) do
      local have = {}
      for _, s in ipairs(registry:get_snippets_for_ft(ft)) do
        -- blink splits a list of prefixes into one snippet each; accept either form.
        for _, p in ipairs(type(s.prefix) == "table" and s.prefix or { s.prefix }) do
          have[p] = true
        end
      end
      for _, p in ipairs(prefixes) do
        if not have[p] then
          missing[#missing + 1] = ft .. " " .. p
        end
      end
    end
    table.sort(missing)
    t.eq(missing, {}, "snippets blink cannot see")
  end,

  ["every snippet file parses and every snippet has a prefix and a body"] = function(t)
    local dir = t.root .. "/snippets"
    local bad = {}
    for _, entry in ipairs(read_json(dir .. "/package.json").contributes.snippets) do
      local ok, snippets = pcall(read_json, dir .. "/" .. entry.path)
      if not ok then
        bad[#bad + 1] = entry.path .. ": " .. tostring(snippets)
      else
        for name, s in pairs(snippets) do
          if not s.prefix or not s.body then
            bad[#bad + 1] = entry.path .. ": " .. name
          end
        end
      end
    end
    table.sort(bad)
    t.eq(bad, {}, "broken snippets")
  end,

  ["the completion menu draws the icon database's kind icons"] = function(t)
    local kinds, drawn = require("ach.icons").kinds, blink_config().appearance.kind_icons
    for _, kind in ipairs({ "Function", "Snippet", "Text" }) do
      t.eq(drawn[kind], kinds[kind], "the " .. kind .. " icon")
    end
  end,

  ["brackets pair and text objects are ready after start"] = function(t)
    t.ok(mapped("(", "i"), "mini.pairs maps ( in insert mode")
    t.ok(mapped("a", "o") and mapped("i", "x"), "mini.ai maps a and i for operators and selections")
  end,
}
```

- [ ] **Run them and see them fail**

Run: `scripts/check --only test_completion`
Expected: FAIL on five tests and a person needed for one, then `0 passed, 5 failed, 1 need a person, 0 skipped`, exit 1. The three blink tests fail on `module 'blink.cmp.config' not found`, the snippet-file test on the missing `snippets/package.json`, and the pairs test on the unmapped `(`. The matcher test asks for a person, because lazy.nvim only reports the unknown plugin and the compiled module is absent.

- [ ] **Write the completion plugins, the snippets and the fetch script**

`lua/ach/plugins/coding.lua`:

```lua
-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/coding/blink.lua and
-- lua/lazyvim/plugins/coding.lua, for the blink.cmp and mini.ai specs.

return {
  -- The completion menu, fed by the language server, file paths, snippets and words in open buffers.
  {
    "saghen/blink.cmp",
    -- Releases carry the compiled matcher; scripts/fetch-matcher downloads the one for this tag.
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts_extend = { "sources.default" },
    opts = {
      keymap = { preset = "enter" },
      -- The kind icons are the icon database's, bare, since blink adds its own spacing.
      appearance = { nerd_font_variant = "mono", kind_icons = require("ach.icons").kinds },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
        menu = { draw = { treesitter = { "lsp" } } },
      },
      signature = { enabled = true },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          -- The repository's own folder, so the snippets are found through the link and under nvim -u alike.
          snippets = { opts = { search_paths = { vim.g.ach_root .. "/snippets" } } },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = { enabled = true },
    },
  },

  -- Closes brackets and quotes as they open.
  {
    "nvim-mini/mini.pairs",
    event = "VeryLazy",
    opts = { modes = { insert = true, command = true, terminal = false } },
  },

  -- Text objects: af and if for a function, ac and ic for a class, ao and io for a block,
  -- au and iu for a call, on top of mini.ai's brackets, quotes and arguments.
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        -- Look this far for an object, so a long function still counts as one.
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          u = ai.gen_spec.function_call(),
        },
      }
    end,
  },

  -- The right comment marker inside embedded languages, such as Lua inside Markdown.
  { "folke/ts-comments.nvim", event = "VeryLazy", opts = {} },
}
```

`snippets/package.json`:

```json
{
  "name": "ach-snippets",
  "description": "ACH-NEOVIM's own snippets, read beside friendly-snippets",
  "contributes": {
    "snippets": [
      { "language": ["all"], "path": "./all.json" },
      { "language": ["tex", "plaintex"], "path": "./tex.json" },
      { "language": ["lua"], "path": "./lua.json" }
    ]
  }
}
```

`snippets/all.json`:

```json
{
  "Today": {
    "prefix": "today",
    "body": "$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE",
    "description": "Today's date, as 2026-10-10"
  }
}
```

`snippets/tex.json` (a backslash is doubled for JSON, and `\\$` is a literal dollar sign in a snippet):

```json
{
  "Equation": {
    "prefix": "eq",
    "body": ["\\begin{equation}", "\t$0", "\\end{equation}"],
    "description": "A numbered equation"
  },
  "Align": {
    "prefix": "align",
    "body": ["\\begin{align}", "\t$0", "\\end{align}"],
    "description": "Aligned equations"
  },
  "Theorem": {
    "prefix": "thm",
    "body": ["\\begin{theorem}", "\t$0", "\\end{theorem}"],
    "description": "A theorem"
  },
  "Example": {
    "prefix": "ex",
    "body": ["\\begin{example}", "\t$0", "\\end{example}"],
    "description": "A worked example"
  },
  "Fraction": {
    "prefix": "frac",
    "body": "\\frac{$1}{$2}$0",
    "description": "A fraction"
  },
  "Inline math": {
    "prefix": "mk",
    "body": "\\$$1\\$$0",
    "description": "Inline math between dollar signs"
  }
}
```

`snippets/lua.json`:

```json
{
  "Module": {
    "prefix": "mod",
    "body": ["local M = {}", "", "$0", "", "return M"],
    "description": "A Lua module that returns its table"
  }
}
```

`scripts/fetch-matcher` (make it executable with `chmod +x scripts/fetch-matcher`):

```bash
#!/usr/bin/env bash
# Download blink.cmp's compiled fuzzy matcher for the release in lazy-lock.json.
#   scripts/fetch-matcher
# blink.cmp fetches it by itself in the background the first time it loads. This
# waits for that download, up to two minutes, so a new machine has the matcher
# before the first keystroke and the test suite has it before it runs.
# Exit 0 when the compiled matcher is in use, 1 when blink fell back to its Lua
# matcher, 2 when Neovim is missing.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$root"

if ! command -v nvim >/dev/null 2>&1; then
    echo "Neovim is not installed. Install it with: brew install neovim" >&2
    exit 2
fi

kind=$(nvim --headless -u init.lua \
    "+lua require('lazy').load({ plugins = { 'blink.cmp' } })" \
    "+lua vim.wait(120000, function() return require('blink.cmp.fuzzy').implementation_type == 'rust' end, 200)" \
    "+lua io.stdout:write(require('blink.cmp.fuzzy').implementation_type)" \
    +qa 2>/dev/null)
echo "blink.cmp matcher: $kind"
[ "$kind" = "rust" ]
```

- [ ] **Install the plugins**

Run: `nvim --headless -u init.lua "+Lazy! sync" +qa`
Expected: `lazy-lock.json` gains `blink.cmp`, `friendly-snippets`, `mini.ai`, `mini.pairs` and `ts-comments.nvim`, and the `blink.cmp` entry names a commit on a `v1.` release tag.

- [ ] **Fetch the matcher**

Run: `scripts/fetch-matcher`
Expected: `blink.cmp matcher: rust`, exit 0. If it prints `lua` after two minutes, the download failed: run `nvim -u init.lua +"checkhealth blink.cmp"` and read the fuzzy section before going on, since the matcher test will ask for a person until this passes.

- [ ] **Run the suite and see it pass**

Run: `scripts/check`
Expected: all six `test_completion` tests pass, along with every earlier test. Exit 0.

- [ ] **Look at it once**

Run: `nvim -u init.lua "$(mktemp -d)/try.tex"`
Expected: in insert mode, typing `eq` shows our equation snippet in the menu with its documentation beside it. Enter expands it with the cursor inside the environment. Typing `today` offers today's date, and `mk` gives a pair of dollar signs with the cursor between them. Quit with `:q!`.

- [ ] **Commit**

```bash
git add lua/ach/plugins/coding.lua snippets/package.json snippets/all.json snippets/tex.json snippets/lua.json scripts/fetch-matcher tests/test_completion.lua
git commit --only lua/ach/plugins/coding.lua snippets/package.json snippets/all.json snippets/tex.json snippets/lua.json scripts/fetch-matcher tests/test_completion.lua lazy-lock.json -m "feat(completion): add blink.cmp with the repository's snippets and the matcher fetch"
```
