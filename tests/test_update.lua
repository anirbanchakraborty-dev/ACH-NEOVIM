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
  return said, function(text) said[#said + 1] = text end
end

-- A stand-in for one lazy.nvim task, which failed when err is given.
local function task(err)
  return {
    has_errors = function() return err ~= nil end,
    output = function() return err or "" end,
  }
end

-- A stand-in for one installed Mason package.
local function pkg(name, installed, latest)
  return {
    name = name,
    get_installed_version = function() return installed end,
    get_latest_version = function() return latest end,
  }
end

local function registry(packages)
  return {
    refresh = function(done) done(true) end,
    get_installed_packages = function() return packages end,
  }
end

-- Stand-ins for everything the update, the restore and the list reach. The
-- second value records each call into lazy.nvim with its options.
local function deps(o)
  local calls = {}
  local function record(name)
    return function(opts) calls[#calls + 1] = { name, opts } end
  end
  return {
    lazy = { update = record("update"), restore = record("restore"), check = record("check") },
    plugins = function() return o.plugins or {} end,
    parsers = function()
      return {
        pwait = function() return true, o.parsers ~= false end,
      }
    end,
    masonlock = o.masonlock or {},
    registry = function() return o.registry or registry({}) end,
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
          vim.schedule(function() done({ "stylua" }, { "lua-language-server" }) end)
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
        update = function(done) done({}, {}) end,
      },
    })
    t.eq(U.apply(clean), {}, "nothing failed")
  end,

  ["a restore returns each Mason package that drifted to its pin and leaves the rest"] = function(t)
    local U = require("ach.update")
    local installed = {}
    local d, calls = deps({
      masonlock = {
        read = function() return { stylua = "2.0.2", taplo = "0.9.3", ["lua-language-server"] = "3.13.5" } end,
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
      restore = function() error("a passing update is never restored") end,
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
        check = function() error("the full check never runs after a failed update") end,
        restore = function() return restore_code end,
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
      apply = function() return 0 end,
      check = function() error("no check when nothing moved") end,
      restore = function() error("nothing to restore when nothing moved") end,
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
      apply = function() error("nothing updates over changes that are not committed") end,
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
