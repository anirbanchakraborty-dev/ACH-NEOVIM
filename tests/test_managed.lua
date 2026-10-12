-- Rust, Haskell, Java, Scala and Lean. Each plugin's own start is off; the
-- installer hands a buffer to ach.managed, which starts that plugin's server
-- once its program is there, in the right buffer. The plugins are stand-ins
-- in package.loaded, so no test loads one or starts a real server.
local opened = {}

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

-- Runs body, then wipes the buffers it opened, even when body fails.
local function tidy(body)
  local ok, err = pcall(body)
  for _, buf in ipairs(opened) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  opened = {}
  if not ok then
    error(err, 0)
  end
end

-- A buffer called path, of file type ft, that is never read from disk, so it
-- fires no BufReadPre and loads no plugin.
local function named(path, ft)
  local buf = vim.api.nvim_create_buf(true, false)
  opened[#opened + 1] = buf
  vim.api.nvim_buf_set_name(buf, path)
  vim.bo[buf].filetype = ft
  return buf
end

-- A stand-in for vim.fn.executable that finds only the programs in found,
-- read at each call, so a test can install one partway through.
local function only(found)
  return function(name) return found[name] and 1 or 0 end
end

local function entry(ft) return require("ach.lang").for_ft(ft) end

return {
  ["each plugin's own start is off"] = function(t)
    local rust = vim.g.rustaceanvim or {}
    t.eq(vim.tbl_get(rust, "server", "auto_attach"), false, "rustaceanvim's own start")
    t.eq(
      vim.tbl_get(rust, "server", "default_settings", "rust-analyzer", "check", "command"),
      "clippy",
      "rust-analyzer checks with Clippy"
    )
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "hls", "auto_attach"), false, "haskell-tools' own start")
    t.eq(vim.tbl_get(vim.g.lean_config or {}, "lsp", "enable"), false, "lean.nvim's own start")
  end,

  ["the installer enables servers, then hands a managed language to its plugin"] = function(t)
    local M, L, install = require("ach.managed"), require("ach.lsp"), require("ach.install")
    local calls = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/main.rs", "rust")
      with({
        {
          L,
          "enable_for",
          function(ft) calls[#calls + 1] = "enable " .. ft end,
        },
        {
          M,
          "start",
          function(b, e) calls[#calls + 1] = "start " .. e.managed .. (b == buf and " here" or " elsewhere") end,
        },
      }, function()
        install.ready(buf, "rust", entry("rust"))
        install.ready(buf, "python", entry("python"))
      end)
      t.eq(calls, { "enable rust", "start rustaceanvim here", "enable python" })
    end)
  end,

  ["Rust and Haskell start in the buffer they were given"] = function(t)
    local M = require("ach.managed")
    local got = {}
    tidy(function()
      local rs = named(t.tmpdir() .. "/main.rs", "rust")
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      local here = vim.api.nvim_get_current_buf()
      with({
        { vim.fn, "executable", only({ ["rust-analyzer"] = true, ["haskell-language-server-wrapper"] = true }) },
        {
          package.loaded,
          "rustaceanvim.lsp",
          {
            start = function(b) got.rust = b end,
          },
        },
        {
          package.loaded,
          "haskell-tools",
          {
            lsp = {
              start = function(b) got.haskell = { b, vim.api.nvim_get_current_buf() } end,
            },
          },
        },
      }, function()
        M.start(rs, entry("rust"))
        M.start(hs, entry("haskell"))
      end)
      t.eq(got.rust, rs, "rust-analyzer's buffer")
      t.eq(got.haskell, { hs, hs }, "haskell-language-server's buffer, current while it starts")
      t.eq(vim.api.nvim_get_current_buf(), here, "the current buffer is put back")
    end)
  end,

  ["Java gets a data folder per project, Lombok, and the debug and test bundles"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local share, root = t.tmpdir(), t.tmpdir()
    for _, jar in ipairs({
      "jdtls/lombok.jar",
      "java-debug-adapter/com.microsoft.java.debug.plugin.jar",
      "java-test/com.microsoft.java.test.plugin-0.43.1.jar",
      "java-test/com.microsoft.java.test.runner-jar-with-dependencies.jar",
      "java-test/jacocoagent.jar",
      "java-test/junit-jupiter-api_5.11.0.jar",
    }) do
      vim.fn.mkdir(vim.fs.dirname(share .. "/" .. jar), "p")
      vim.fn.writefile({}, share .. "/" .. jar)
    end
    for _, dir in ipairs({ "a/app/.git", "a/app/src", "b/app/.git", "b/app/src" }) do
      vim.fn.mkdir(root .. "/" .. dir, "p")
    end
    local calls = {}
    tidy(function()
      local one = named(root .. "/a/app/src/Main.java", "java")
      local two = named(root .. "/b/app/src/Main.java", "java")
      with({
        { M, "share", share },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function() return { stand_in = true } end,
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function(config, opts, start_opts)
              calls[#calls + 1] = { config = config, opts = opts, start_opts = start_opts }
            end,
          },
        },
      }, function()
        M.start(one, entry("java"))
        M.start(two, entry("java"))
      end)
      t.eq(#calls, 2, "jdtls is asked once per buffer")
      local c = calls[1].config
      local data = c.cmd[#c.cmd]
      t.eq(c.cmd, { "jdtls", "--jvm-arg=-javaagent:" .. share .. "/jdtls/lombok.jar", "-data", data })
      t.eq(c.root_dir, root .. "/a/app", "the project's root")
      t.ok(vim.startswith(data, vim.fn.stdpath("cache") .. "/jdtls/app-"), "the data folder is in the cache: " .. data)
      t.ok(data ~= calls[2].config.cmd[#calls[2].config.cmd], "two projects called app keep two data folders")
      t.eq(c.init_options.bundles, {
        share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar",
        share .. "/java-test/com.microsoft.java.test.plugin-0.43.1.jar",
        share .. "/java-test/junit-jupiter-api_5.11.0.jar",
      }, "the bundles, without the test runner and the coverage agent")
      t.eq(c.capabilities, { stand_in = true })
      t.eq(calls[1].start_opts, { bufnr = one })
    end)
  end,

  ["a buffer that is not a file starts nothing"] = function(t)
    local M = require("ach.managed")
    local asked = 0
    tidy(function()
      local scratch = vim.api.nvim_create_buf(false, true)
      opened[#opened + 1] = scratch
      vim.bo[scratch].filetype = "java"
      local gone = named(t.tmpdir() .. "/Gone.java", "java")
      vim.api.nvim_buf_delete(gone, { force = true })
      with({
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function() asked = asked + 1 end,
          },
        },
      }, function()
        M.start(scratch, entry("java"))
        M.start(gone, entry("java"))
      end)
      t.eq(asked, 0)
    end)
  end,

  ["Scala starts Metals from the data folder"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local program = t.tmpdir() .. "/metals"
    local got
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only({ [program] = true }) },
        {
          L,
          "capabilities",
          function() return { stand_in = true } end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function() return { settings = {}, init_options = { statusBarProvider = "off" } } end,
            initialize_or_attach = function(config) got = { config = config, buf = vim.api.nvim_get_current_buf() } end,
          },
        },
      }, function() M.start(buf, entry("scala")) end)
      t.eq(got and got.buf, buf, "Metals attaches to the Scala buffer")
      t.eq(got.config.settings, { metalsBinaryPath = program })
      t.eq(got.config.capabilities, { stand_in = true })
      t.eq(got.config.init_options, { statusBarProvider = "off" }, "bare_config's other fields are kept")
    end)
  end,

  ["a missing Metals is installed once, then started in each Scala buffer"] = function(t)
    local M = require("ach.managed")
    local program = t.tmpdir() .. "/metals/metals"
    local found, runs, notes, started, finish = { coursier = true }, {}, {}, {}, nil
    tidy(function()
      local one = named(t.tmpdir() .. "/A.scala", "scala")
      local two = named(t.tmpdir() .. "/build.sbt", "sbt")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only(found) },
        {
          vim,
          "notify",
          function(msg, level) notes[#notes + 1] = { msg, level } end,
        },
        {
          vim,
          "system",
          function(cmd, _, on_exit)
            runs[#runs + 1] = cmd
            finish = on_exit
            return {}
          end,
        },
        {
          require("ach.lsp"),
          "capabilities",
          function() return {} end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function() return { settings = {} } end,
            initialize_or_attach = function() started[#started + 1] = vim.api.nvim_get_current_buf() end,
          },
        },
      }, function()
        M.start(one, entry("scala"))
        M.start(two, entry("sbt"))
        t.eq(
          runs,
          { { "coursier", "install", "--install-dir", vim.fs.dirname(program), "metals" } },
          "one install for two buffers"
        )
        t.eq(notes, { { "Installing Metals for Scala; it starts when the install finishes" } })
        t.eq(started, {}, "nothing starts before the install finishes")
        found[program] = true
        finish({ code = 0, stdout = "", stderr = "" })
        t.ok(vim.wait(1000, function() return #started == 2 end), "both buffers start once Metals is there")
      end)
      table.sort(started)
      local want = { one, two }
      table.sort(want)
      t.eq(started, want)
    end)
  end,

  ["a failed Metals install says why, and the next Scala buffer tries again"] = function(t)
    local M = require("ach.managed")
    local runs, notes, finish = 0, {}, nil
    tidy(function()
      local buf = named(t.tmpdir() .. "/A.scala", "scala")
      with({
        { M, "metals_program", t.tmpdir() .. "/metals/metals" },
        { vim.fn, "executable", only({ coursier = true }) },
        {
          vim,
          "notify",
          function(msg, level) notes[#notes + 1] = { msg, level } end,
        },
        {
          vim,
          "system",
          function(_, _, on_exit)
            runs = runs + 1
            finish = on_exit
            return {}
          end,
        },
      }, function()
        M.start(buf, entry("scala"))
        finish({ code = 1, stdout = "", stderr = "Resolving metals\nError: download failed\n" })
        t.ok(vim.wait(1000, function() return #notes == 2 end), "a second message")
        t.eq(notes[2], { "Metals did not install: Error: download failed", vim.log.levels.ERROR })
        M.start(buf, entry("scala"))
        t.eq(runs, 2, "the next Scala buffer tries again")
        finish({ code = 1, stdout = "", stderr = "" })
        vim.wait(1000, function() return #notes == 4 end)
      end)
    end)
  end,

  ["a new Scala file gets Metals when it is first written"] = function(t)
    local M = require("ach.managed")
    local program = t.tmpdir() .. "/metals"
    local found, started, runs = { coursier = true }, 0, 0
    tidy(function()
      local buf = named(t.tmpdir() .. "/New.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only(found) },
        {
          vim,
          "system",
          function()
            runs = runs + 1
            return {}
          end,
        },
        { vim, "notify", function() end },
        {
          require("ach.lsp"),
          "capabilities",
          function() return {} end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function() return { settings = {} } end,
            initialize_or_attach = function() started = started + 1 end,
          },
        },
      }, function()
        vim.api.nvim_exec_autocmds("BufWritePost", { group = "ach_managed", buffer = buf })
        t.eq({ started, runs }, { 0, 0 }, "a save does not install Metals")
        found[program] = true
        vim.api.nvim_exec_autocmds("BufWritePost", { group = "ach_managed", buffer = buf })
        t.eq(started, 1, "the first save once Metals is there starts it")
      end)
    end)
  end,

  ["Lean enables lean.nvim's server once lean is installed"] = function(t)
    local M = require("ach.managed")
    local enabled = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.lean", "lean")
      with({
        { vim.fn, "executable", only({ lean = true }) },
        { package.loaded, "lean", {} },
        {
          vim.lsp,
          "enable",
          function(name) enabled[#enabled + 1] = name end,
        },
      }, function() M.start(buf, entry("lean")) end)
      t.eq(enabled, { "leanls" })
    end)
  end,

  ["each starter waits quietly while its program is missing"] = function(t)
    local M = require("ach.managed")
    local asked, notes, runs = {}, 0, 0
    local function ask(name)
      return function() asked[#asked + 1] = name end
    end
    tidy(function()
      local bufs = {
        rust = named(t.tmpdir() .. "/main.rs", "rust"),
        haskell = named(t.tmpdir() .. "/Main.hs", "haskell"),
        java = named(t.tmpdir() .. "/Main.java", "java"),
        scala = named(t.tmpdir() .. "/Main.scala", "scala"),
        lean = named(t.tmpdir() .. "/Main.lean", "lean"),
      }
      with({
        { M, "metals_program", t.tmpdir() .. "/metals" },
        { vim.fn, "executable", only({}) },
        {
          vim,
          "notify",
          function() notes = notes + 1 end,
        },
        {
          vim,
          "system",
          function()
            runs = runs + 1
            return {}
          end,
        },
        { vim.lsp, "enable", ask("leanls") },
        { package.loaded, "rustaceanvim.lsp", { start = ask("rust-analyzer") } },
        { package.loaded, "haskell-tools", { lsp = { start = ask("haskell-language-server") } } },
        { package.loaded, "jdtls", { start_or_attach = ask("jdtls") } },
        { package.loaded, "metals", { initialize_or_attach = ask("metals") } },
      }, function()
        for ft, buf in pairs(bufs) do
          M.start(buf, entry(ft))
        end
      end)
      t.eq({ asked, notes, runs }, { {}, 0, 0 })
    end)
  end,

  ["a Lean buffer gets lean.nvim's keys, each with an icon"] = function(t)
    local M, I = require("ach.managed"), require("ach.icons")
    local groups = {}
    tidy(function()
      local buf
      with({
        {
          package.loaded,
          "which-key",
          {
            add = function(spec) vim.list_extend(groups, spec) end,
          },
        },
      }, function() buf = named(t.tmpdir() .. "/Main.lean", "lean") end)
      local lua = named(t.tmpdir() .. "/main.lua", "lua")
      t.eq(#M.lean, 15, "lean.nvim's fifteen suggested keys")
      local bad = {}
      vim.api.nvim_buf_call(buf, function()
        for _, k in ipairs(M.lean) do
          local map = vim.fn.maparg(vim.g.maplocalleader .. k[1], "n", false, true)
          if map.buffer ~= 1 or map.desc ~= k[3] then
            bad[#bad + 1] = k[1] .. " is not set in the Lean buffer"
          end
          if not I.key(k[3]) then
            bad[#bad + 1] = k[3] .. " has no icon"
          end
        end
      end)
      t.eq(bad, {})
      vim.api.nvim_buf_call(
        lua,
        function() t.eq(vim.fn.maparg(vim.g.maplocalleader .. "i", "n"), "", "no Lean keys in a Lua buffer") end
      )
      t.ok(I.group("diff pins"), "the diff pins group has an icon")
      t.eq(groups, { { "<localleader>d", group = "diff pins", icon = I.group("diff pins"), buffer = buf } })
    end)
  end,
}
