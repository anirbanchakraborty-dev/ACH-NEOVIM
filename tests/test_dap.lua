-- The debugger. Every plugin it talks to is a stand-in in package.loaded,
-- so no test loads nvim-dap, its interface or a language's plugin, and no
-- test starts a debug adapter.
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

-- A stand-in for nvim-dap, holding the tables setup() writes into.
local function fake_dap()
  return {
    adapters = {},
    configurations = {},
    providers = { configs = {} },
    listeners = { before = { attach = {}, launch = {}, event_terminated = {}, event_exited = {} } },
  }
end

-- The stand-ins setup() needs, each noting in got what it was given.
local function stand_ins(dap, got)
  return {
    { package.loaded, "dap", dap },
    {
      package.loaded,
      "mason-nvim-dap",
      {
        setup = function(opts)
          got.mason = opts
          got.c_before_mason = dap.configurations.c
        end,
        default_setup = function() end,
      },
    },
    {
      package.loaded,
      "dap-python",
      {
        setup = function(path) got.python = path end,
      },
    },
    {
      package.loaded,
      "dapui",
      {
        setup = function(opts) got.ui = opts end,
        open = function() got.opened = (got.opened or 0) + 1 end,
        close = function() got.closed = (got.closed or 0) + 1 end,
      },
    },
    {
      package.loaded,
      "nvim-dap-virtual-text",
      {
        setup = function(opts) got.virtual_text = opts end,
      },
    },
  }
end

local function names(configurations)
  return vim.tbl_map(function(c) return c.name end, configurations or {})
end

-- The action of the debug key whose left-hand side is lhs.
local function action(lhs)
  for _, k in ipairs(require("ach.dap").keys) do
    if k[1] == lhs then
      return k[2]
    end
  end
  error("no debug key " .. lhs)
end

return {
  ["the breakpoint signs draw their icons"] = function(t)
    local D, I = require("ach.dap"), require("ach.icons")
    D.define_signs()
    t.eq(vim.tbl_count(D.signs), 5, "every sign nvim-dap draws")
    for name, s in pairs(D.signs) do
      local def = vim.fn.sign_getdefined(name)[1]
      t.ok(def ~= nil, name .. " is defined")
      t.eq(vim.trim(def.text), I.get(s[1]), name .. "'s icon")
      t.eq(def.texthl, s[2], name .. "'s colour")
    end
    t.eq(vim.fn.sign_getdefined("DapStopped")[1].linehl, "DapStoppedLine", "the stopped line is marked across")
    t.ok(next(vim.api.nvim_get_hl(0, { name = "DapStoppedLine" })) ~= nil, "the stopped line has a colour")
  end,

  ["Mason's adapters are set up, except those something else sets up"] = function(t)
    local D = require("ach.dap")
    local given = {}
    with({
      {
        package.loaded,
        "mason-nvim-dap",
        {
          default_setup = function(config) given[#given + 1] = config.name end,
        },
      },
    }, function()
      local handlers = D.handlers()
      -- mason-nvim-dap calls an adapter's own handler, or the default when it has none.
      for _, name in ipairs({
        "delve",
        "python",
        "kotlin",
        "codelldb",
        "javadbg",
        "coreclr",
        "javatest",
        "php",
        "haskell",
        "js",
      }) do
        local handler = handlers[name] or handlers[1]
        handler({ name = name })
      end
    end)
    t.eq(given, { "delve", "kotlin", "coreclr", "php" })
    local skipped = vim.tbl_keys(D.skip)
    table.sort(skipped)
    t.eq(skipped, { "codelldb", "haskell", "javadbg", "javatest", "js", "python" })
  end,

  ["setup writes the adapters and launch choices this module owns"] = function(t)
    local D = require("ach.dap")
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function() D.setup() end)
    t.eq(dap.adapters.lldb, { type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb" })
    for _, ft in ipairs({ "c", "cpp", "objc", "objcpp", "swift", "zig" }) do
      t.eq(names(dap.configurations[ft]), { "Launch a Program", "Attach to a Running Program" }, ft)
      t.eq(dap.configurations[ft][1].type, "lldb", ft .. " debugs through lldb-dap")
    end
    local js = dap.adapters["pwa-node"]
    t.eq(js.executable, { command = D.bin .. "/js-debug-adapter", args = { "${port}", "127.0.0.1" } })
    t.eq(js.host, "127.0.0.1", "the adapter and the editor meet on the loopback address")
    for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact" }) do
      t.eq(names(dap.configurations[ft]), { "Launch This File", "Attach to a Running Node" }, ft)
    end
    t.eq(got.python, D.bin .. "/debugpy-adapter", "nvim-dap-python runs Mason's debugpy")
    t.eq(
      vim.tbl_map(function(c) return c.metals.runType end, dap.configurations.scala),
      { "runOrTestFile", "testTarget" }
    )
    t.eq(dap.providers.configs["ach.haskell"], D.haskell_configs)
    t.ok("ach.haskell" < "dap.global", "nvim-dap asks the Haskell provider before it reads dap.configurations")
    t.eq(got.mason.automatic_installation, false, "mason-nvim-dap installs nothing itself")
    t.eq(got.mason.ensure_installed, {})
    t.eq(type(got.mason.handlers[1]), "function")
    t.ok(got.virtual_text ~= nil, "values are drawn beside the code")
  end,

  ["a launch.json that names node reaches js-debug as pwa-node"] = function(t)
    local dap, got = fake_dap(), {}
    local reached, config = nil, { type = "node", request = "launch", name = "From launch.json" }
    with(stand_ins(dap, got), function()
      require("ach.dap").setup()
      dap.adapters.node(function(adapter) reached = adapter end, config)
    end)
    t.eq(reached, dap.adapters["pwa-node"])
    t.eq(config.type, "pwa-node")
  end,

  ["Mason's launch choices are added to these, not replaced by them"] = function(t)
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function() require("ach.dap").setup() end)
    t.ok(got.c_before_mason ~= nil, "the C launch choices exist before mason-nvim-dap extends them")
  end,

  ["the debug interface opens as a session starts and closes as it ends"] = function(t)
    local I = require("ach.icons")
    local dap, got = fake_dap(), {}
    with(stand_ins(dap, got), function()
      require("ach.dap").setup()
      dap.listeners.before.launch.ach()
      dap.listeners.before.attach.ach()
      dap.listeners.before.event_terminated.ach()
      dap.listeners.before.event_exited.ach()
    end)
    t.eq({ got.opened, got.closed }, { 2, 2 })
    t.eq(got.ui.controls.icons.play, I.get("dap.continue"), "the interface's buttons come from the icon database")
    t.eq(got.ui.controls.icons.terminate, I.get("dap.terminate"))
  end,

  ["the Haskell provider leaves other files alone, and says once how to get hdb"] = function(t)
    local D = require("ach.dap")
    local notes, searched = {}, 0
    tidy(function()
      local lua = named(t.tmpdir() .. "/init.lua", "lua")
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      with({
        { vim.fn, "executable", only({}) },
        {
          vim,
          "notify_once",
          function(msg, level) notes[#notes + 1] = { msg, level } end,
        },
        {
          package.loaded,
          "haskell-tools",
          {
            dap = {
              discover_configurations = function() searched = searched + 1 end,
            },
          },
        },
      }, function()
        t.eq(D.haskell_configs(lua), {}, "a Lua file")
        t.eq(D.haskell_configs(hs), {}, "a Haskell file without hdb")
      end)
    end)
    t.eq(notes, { { D.hdb_missing, vim.log.levels.WARN } })
    t.eq(searched, 0)
    t.ok(D.hdb_missing:find("well-typed/haskell-debugger", 1, true) ~= nil, "the message says where hdb comes from")
  end,

  ["with hdb, the Haskell provider fills in the project's launch choices"] = function(t)
    local D = require("ach.dap")
    local asked = {}
    tidy(function()
      local hs = named(t.tmpdir() .. "/Main.hs", "haskell")
      with(
        {
          { vim.fn, "executable", only({ hdb = true }) },
          {
            package.loaded,
            "haskell-tools",
            {
              dap = {
                discover_configurations = function(buf) asked[#asked + 1] = buf end,
              },
            },
          },
        },
        function()
          t.eq(D.haskell_configs(hs), {}, "the search fills dap.configurations.haskell, which dap.global reads")
        end
      )
      t.eq(asked, { hs })
    end)
  end,

  ["haskell-tools does not search for launch choices as a file opens"] = function(t)
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "dap", "auto_discover"), false)
    t.eq(vim.tbl_get(vim.g.haskell_tools or {}, "hls", "auto_attach"), false, "its own start stays off")
  end,

  ["Java's debugger is registered, with hot code replace, before jdtls starts"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local share = t.tmpdir()
    local jar = share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
    vim.fn.mkdir(vim.fs.dirname(jar), "p")
    vim.fn.writefile({}, jar)
    local order, opts = {}, nil
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.java", "java")
      with({
        { M, "share", share },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function() return {} end,
        },
        {
          package.loaded,
          "jdtls.dap",
          {
            setup_dap = function(o)
              order[#order + 1] = "debugger"
              opts = o
            end,
          },
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function() order[#order + 1] = "jdtls" end,
          },
        },
      }, function() M.start(buf, entry("java")) end)
    end)
    t.eq(order, { "debugger", "jdtls" })
    t.eq(opts, { hotcodereplace = "auto" })
  end,

  ["without the debug jar, jdtls starts with no debugger registered"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local order = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.java", "java")
      with({
        { M, "share", t.tmpdir() },
        { vim.fn, "executable", only({ jdtls = true }) },
        {
          L,
          "capabilities",
          function() return {} end,
        },
        {
          package.loaded,
          "jdtls.dap",
          {
            setup_dap = function() order[#order + 1] = "debugger" end,
          },
        },
        {
          package.loaded,
          "jdtls",
          {
            start_or_attach = function() order[#order + 1] = "jdtls" end,
          },
        },
      }, function() M.start(buf, entry("java")) end)
    end)
    t.eq(order, { "jdtls" })
  end,

  ["Metals registers Scala's debugger as it attaches"] = function(t)
    local M, L = require("ach.managed"), require("ach.lsp")
    local program = t.tmpdir() .. "/metals"
    local config, registered = nil, 0
    tidy(function()
      local buf = named(t.tmpdir() .. "/Main.scala", "scala")
      with({
        { M, "metals_program", program },
        { vim.fn, "executable", only({ [program] = true }) },
        {
          L,
          "capabilities",
          function() return {} end,
        },
        {
          package.loaded,
          "metals",
          {
            bare_config = function() return {} end,
            initialize_or_attach = function(c) config = c end,
            setup_dap = function() registered = registered + 1 end,
          },
        },
      }, function()
        M.start(buf, entry("scala"))
        t.eq(type(config and config.on_attach), "function", "the Metals configuration has an on_attach")
        config.on_attach({}, buf)
      end)
    end)
    t.eq(registered, 1)
  end,

  ["starting with arguments asks for them, offering the current ones"] = function(t)
    local D = require("ach.dap")
    local asked
    local original = { type = "python", request = "launch", name = "File", args = { "--fast", "in.txt" } }
    with({
      {
        vim.fn,
        "input",
        function(prompt, default)
          asked = { prompt, default }
          return "--slow out.txt"
        end,
      },
      {
        package.loaded,
        "dap.utils",
        {
          splitstr = function(s) return vim.split(s, " ") end,
        },
      },
    }, function()
      local config = D.ask_args(original)
      t.eq(original.args, { "--fast", "in.txt" }, "the configuration itself is left alone")
      t.eq(config.args(), { "--slow", "out.txt" })
    end)
    t.eq(asked, { "Run with arguments: ", "--fast in.txt" })
  end,

  ["Java's arguments stay one string"] = function(t)
    local D = require("ach.dap")
    local offered
    with({
      {
        vim.fn,
        "input",
        function(_, default)
          offered = default
          return "a b"
        end,
      },
    }, function()
      local config = D.ask_args({
        type = "java",
        args = function() return "x y" end,
      })
      t.eq(config.args(), "a b")
    end)
    t.eq(offered, "x y", "a configuration's arguments may be a function")
  end,

  ["debugging a test goes to the language's own runner"] = function(t)
    local D = require("ach.dap")
    local ran = {}
    local function note(what)
      return function(arg) ran[#ran + 1] = arg and (what .. " " .. arg) or what end
    end
    tidy(function()
      local files = {
        { "python", named(t.tmpdir() .. "/test_app.py", "python") },
        { "java", named(t.tmpdir() .. "/AppTest.java", "java") },
        { "rust", named(t.tmpdir() .. "/lib.rs", "rust") },
      }
      with({
        { package.loaded, "dap-python", { test_method = note("python method"), test_class = note("python class") } },
        { package.loaded, "jdtls.dap", { test_nearest_method = note("java method"), test_class = note("java class") } },
        { vim.cmd, "RustLsp", note("RustLsp") },
      }, function()
        for _, f in ipairs(files) do
          vim.api.nvim_buf_call(f[2], function()
            D.debug_test("method")
            D.debug_test("class")
          end)
        end
      end)
    end)
    t.eq(ran, { "python method", "python class", "java method", "java class", "RustLsp debug", "RustLsp debuggables" })
  end,

  ["a file type with no test debugging says so"] = function(t)
    local D = require("ach.dap")
    local notes = {}
    tidy(function()
      local buf = named(t.tmpdir() .. "/main.go", "go")
      with({
        {
          vim,
          "notify",
          function(msg, level) notes[#notes + 1] = { msg, level } end,
        },
      }, function()
        vim.api.nvim_buf_call(buf, function() D.debug_test("method") end)
      end)
    end)
    t.eq(#notes, 1)
    t.eq(notes[1][2], vim.log.levels.WARN)
    t.ok(notes[1][1]:find("go", 1, true) ~= nil, "the message names the file type: " .. tostring(notes[1][1]))
  end,

  ["a cancelled prompt sets no breakpoint"] = function(t)
    local set = {}
    ---@type string?
    local answer = ""
    with({
      {
        vim.fn,
        "input",
        function()
          if answer == nil then
            error("Keyboard interrupt")
          end
          return answer
        end,
      },
      {
        package.loaded,
        "dap",
        {
          set_breakpoint = function(...) set[#set + 1] = { ... } end,
        },
      },
    }, function()
      action("<leader>dB")()
      action("<leader>dL")()
      answer = nil
      action("<leader>dB")()
      action("<leader>dL")()
      answer = "i > 3"
      action("<leader>dB")()
      action("<leader>dL")()
    end)
    t.eq(set, { { "i > 3" }, { nil, nil, "i > 3" } }, "only the answered prompts set a breakpoint")
  end,

  ["every debug key is under <leader>d, once, with its own icon"] = function(t)
    local D, I = require("ach.dap"), require("ach.icons")
    local seen, bad = {}, {}
    for _, k in ipairs(D.keys) do
      if not vim.startswith(k[1], "<leader>d") then
        bad[#bad + 1] = k[1] .. " is outside <leader>d"
      end
      if seen[k[1]] then
        bad[#bad + 1] = k[1] .. " is set twice"
      end
      seen[k[1]] = true
      local icon = I.key(k[3])
      if not (icon and icon.icon) then
        bad[#bad + 1] = k[3] .. " has no icon"
      end
    end
    t.eq(bad, {})
    t.eq(#D.keys, 23)
    local spec = require("ach.plugins.dap")[1]
    t.eq(#spec.keys(), #D.keys, "each key loads nvim-dap")
  end,

  ["every debugger plugin is pinned"] = function(t)
    local spec = require("ach.plugins.dap")[1]
    local loose = {}
    for _, p in ipairs(vim.list_extend({ spec }, spec.dependencies)) do
      if not (p.commit or p.version) then
        loose[#loose + 1] = p[1]
      end
    end
    t.eq(loose, {})
    t.eq(#spec.dependencies, 5)
  end,
}
