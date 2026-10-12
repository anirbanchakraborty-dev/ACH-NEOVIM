-- The debugger: the signs nvim-dap draws, which adapter each language debugs
-- through and who sets it up, the launch choices this configuration writes
-- itself, and the keys under <leader>d. nvim-dap's config calls setup(); the
-- Java starter in ach.managed calls java().
local I = require("ach.icons")

local M = {}

-- Where Mason links the programs it installs.
M.bin = vim.fn.stdpath("data") .. "/mason/bin"

-- nvim-dap's signs: the icon each draws, its colour, and, for the line the
-- program is stopped on, a highlight across the whole line.
M.signs = {
  DapBreakpoint = { "dap.Breakpoint", "DiagnosticError" },
  DapBreakpointCondition = { "dap.BreakpointCondition", "DiagnosticWarn" },
  DapBreakpointRejected = { "dap.BreakpointRejected", "DiagnosticError" },
  DapLogPoint = { "dap.LogPoint", "DiagnosticInfo" },
  DapStopped = { "dap.Stopped", "DiagnosticWarn", "DapStoppedLine" },
}

-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/dap/core.lua.
-- The stopped line borrows the selection's colour unless the colour scheme
-- gives it one of its own.
function M.define_signs()
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
  for name, s in pairs(M.signs) do
    vim.fn.sign_define(name, { text = I.get(s[1]) .. " ", texthl = s[2], linehl = s[3], numhl = s[3] })
  end
end

-- Mason's debug adapters that something else sets up, and what does. Every
-- other one installed, such as Go's delve, Kotlin's, .NET's netcoredbg and
-- PHP's, gets mason-nvim-dap's own adapter and launch choices.
M.skip = {
  python = "nvim-dap-python",
  codelldb = "rustaceanvim",
  javadbg = "nvim-jdtls",
  javatest = "nvim-jdtls",
  haskell = "haskell-tools.nvim, through hdb",
  js = "this module",
}

-- mason-nvim-dap's handlers: its default setup, and a handler that does
-- nothing for each adapter in M.skip.
function M.handlers()
  local handlers = {
    function(config) require("mason-nvim-dap").default_setup(config) end,
  }
  for name in pairs(M.skip) do
    handlers[name] = function() end
  end
  return handlers
end

-- Apple's lldb-dap, from Xcode or its Command Line Tools, for the languages
-- that write the DWARF debug information LLDB reads.
M.lldb = { type = "executable", command = "xcrun", args = { "lldb-dap" }, name = "lldb" }
M.lldb_filetypes = { "c", "cpp", "objc", "objcpp", "swift", "zig" }

-- Start a program picked from the files under the working folder that can be
-- run, or attach to one already running.
function M.c_configurations()
  return {
    {
      type = "lldb",
      request = "launch",
      name = "Launch a Program",
      program = function() return require("dap.utils").pick_file() end,
      cwd = "${workspaceFolder}",
      args = {},
      stopOnEntry = false,
    },
    {
      type = "lldb",
      request = "attach",
      name = "Attach to a Running Program",
      pid = function() return require("dap.utils").pick_process() end,
    },
  }
end

-- js-debug, Microsoft's debugger for Node, from Mason. It listens on a port
-- nvim-dap picks, on the loopback address only.
function M.js_adapter()
  return {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = { command = M.bin .. "/js-debug-adapter", args = { "${port}", "127.0.0.1" } },
  }
end

-- A launch.json written for VS Code often names the older "node" type, which
-- js-debug answers as "pwa-node".
function M.node_adapter(callback, config)
  config.type = "pwa-node"
  callback(require("dap").adapters["pwa-node"])
end

M.js_filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" }

-- Run the current file under Node, or attach to a Node already running.
-- Node 23.6 and later run a TypeScript file directly.
function M.js_configurations()
  return {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch This File",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to a Running Node",
      processId = function() return require("dap.utils").pick_process() end,
      cwd = "${workspaceFolder}",
    },
  }
end

-- Metals' two ways to start: the file at the cursor, run or tested as Metals
-- sees fit, and every test in the build target.
function M.scala_configurations()
  return {
    { type = "scala", request = "launch", name = "Run or Test This File", metals = { runType = "runOrTestFile" } },
    { type = "scala", request = "launch", name = "Test This Build Target", metals = { runType = "testTarget" } },
  }
end

M.hdb_missing = "Debugging Haskell needs hdb, which Mason does not carry. Download it from "
  .. "https://github.com/well-typed/haskell-debugger/releases, put the top-level hdb on the path rather "
  .. "than bin/hdb, and install the GHC it was built with, 9.14 or later, with ghcup."

local haskell_filetypes = { haskell = true, lhaskell = true }

-- A configuration provider for nvim-dap. nvim-dap asks its providers in name
-- order, so this one runs before "dap.global" reads dap.configurations.haskell,
-- which haskell-tools' search fills from the project's executables and any
-- launch.json. It returns nothing itself.
function M.haskell_configs(bufnr)
  if not haskell_filetypes[vim.bo[bufnr].filetype] then
    return {}
  end
  if vim.fn.executable("hdb") ~= 1 then
    vim.notify_once(M.hdb_missing, vim.log.levels.WARN)
    return {}
  end
  require("haskell-tools").dap.discover_configurations(bufnr)
  return {}
end

-- Registers Java's debugger with hot code replace, which loads a changed
-- method into the running program each time its file is saved. nvim-jdtls
-- registers the debugger itself as jdtls attaches, without hot code replace,
-- and registers it only once, so this runs before jdtls starts. Without the
-- debug jar there is no debugger to register.
function M.java()
  local jar = require("ach.managed").share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
  if vim.uv.fs_stat(jar) then
    require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
  end
end

-- Adapted from LazyVim (Apache-2.0), lua/lazyvim/plugins/extras/dap/core.lua.
-- A copy of config that asks for the program's arguments as it starts,
-- offering its own. java-debug takes them as one string, every other adapter
-- as a list.
function M.ask_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  local current = type(args) == "table" and table.concat(args, " ") or args
  config = vim.deepcopy(config)
  config.args = function()
    local answer = vim.fn.expand(vim.fn.input("Run with arguments: ", current))
    if config.type == "java" then
      return answer
    end
    return require("dap.utils").splitstr(answer)
  end
  return config
end

-- How to debug the test at the cursor ("method") and every test in its class
-- ("class"), in each language that can. Rust has no classes, so its second
-- key lists everything rustaceanvim can debug.
M.tests = {
  python = {
    method = function() require("dap-python").test_method() end,
    class = function() require("dap-python").test_class() end,
  },
  java = {
    method = function() require("jdtls.dap").test_nearest_method() end,
    class = function() require("jdtls.dap").test_class() end,
  },
  rust = {
    method = function() vim.cmd.RustLsp("debug") end,
    class = function() vim.cmd.RustLsp("debuggables") end,
  },
}

function M.debug_test(kind)
  local ft = vim.bo.filetype
  local run = M.tests[ft] and M.tests[ft][kind]
  if run then
    return run()
  end
  local what = kind == "method" and "the nearest test" or "a test class"
  vim.notify(
    ("Debugging %s works in Python, Java and Rust files, not in %s"):format(what, ft == "" and "this buffer" or ft),
    vim.log.levels.WARN
  )
end

-- The answer to prompt, or nil when it is empty or was cancelled with Escape
-- or Ctrl-C.
local function ask(prompt)
  local ok, answer = pcall(vim.fn.input, prompt)
  if ok and answer ~= "" then
    return answer
  end
end

-- The debug keys: left-hand side, action, description, and the modes when
-- not just normal mode.
M.keys = {
  {
    "<leader>db",
    function() require("dap").toggle_breakpoint() end,
    "Toggle Breakpoint",
  },
  {
    "<leader>dB",
    function()
      local condition = ask("Breakpoint condition: ")
      if condition then
        require("dap").set_breakpoint(condition)
      end
    end,
    "Conditional Breakpoint",
  },
  {
    "<leader>dL",
    function()
      local message = ask("Log message: ")
      if message then
        require("dap").set_breakpoint(nil, nil, message)
      end
    end,
    "Log Point",
  },
  {
    "<leader>dc",
    function() require("dap").continue() end,
    "Start or Continue",
  },
  {
    "<leader>da",
    function() require("dap").continue({ before = M.ask_args }) end,
    "Start with Arguments",
  },
  {
    "<leader>dC",
    function() require("dap").run_to_cursor() end,
    "Run to Cursor",
  },
  {
    "<leader>dg",
    function() require("dap").goto_() end,
    "Jump to Line Without Running",
  },
  {
    "<leader>di",
    function() require("dap").step_into() end,
    "Step Into",
  },
  {
    "<leader>dO",
    function() require("dap").step_over() end,
    "Step Over",
  },
  {
    "<leader>do",
    function() require("dap").step_out() end,
    "Step Out",
  },
  {
    "<leader>dk",
    function() require("dap").up() end,
    "Frame Up",
  },
  {
    "<leader>dj",
    function() require("dap").down() end,
    "Frame Down",
  },
  {
    "<leader>dl",
    function() require("dap").run_last() end,
    "Rerun Last Debug",
  },
  {
    "<leader>dR",
    function() require("dap").restart() end,
    "Restart Debugging",
  },
  {
    "<leader>dP",
    function() require("dap").pause() end,
    "Pause Debugging",
  },
  {
    "<leader>dt",
    function() require("dap").terminate() end,
    "Stop Debugging",
  },
  {
    "<leader>dr",
    function() require("dap.repl").toggle() end,
    "Debug Console",
  },
  {
    "<leader>ds",
    function()
      local widgets = require("dap.ui.widgets")
      widgets.centered_float(widgets.sessions)
    end,
    "Debug Sessions",
  },
  {
    "<leader>dw",
    function() require("dap.ui.widgets").hover() end,
    "Inspect Value",
  },
  {
    "<leader>de",
    function() require("dapui").eval() end,
    "Evaluate Expression",
    { "n", "x" },
  },
  {
    "<leader>du",
    function() require("dapui").toggle({}) end,
    "Debug Interface",
  },
  {
    "<leader>dm",
    function() M.debug_test("method") end,
    "Debug Nearest Test",
  },
  {
    "<leader>dM",
    function() M.debug_test("class") end,
    "Debug Test Class",
  },
}

-- nvim-dap-ui, its buttons drawn from the icon database, opening as a session
-- starts and closing as it ends.
function M.ui()
  local dap, dapui = require("dap"), require("dapui")
  dapui.setup({
    controls = {
      icons = {
        pause = I.get("dap.pause"),
        play = I.get("dap.continue"),
        step_into = I.get("dap.step_into"),
        step_over = I.get("dap.step_over"),
        step_out = I.get("dap.step_out"),
        run_last = I.get("dap.run_last"),
        terminate = I.get("dap.terminate"),
      },
    },
  })
  dap.listeners.before.attach.ach = function() dapui.open() end
  dap.listeners.before.launch.ach = function() dapui.open() end
  dap.listeners.before.event_terminated.ach = function() dapui.close() end
  dap.listeners.before.event_exited.ach = function() dapui.close() end
end

-- Called once, as nvim-dap loads. This module's launch choices are written
-- before mason-nvim-dap runs, because mason-nvim-dap adds its own to each
-- file type's list rather than replacing it.
function M.setup()
  local dap = require("dap")
  M.define_signs()
  dap.adapters.lldb = M.lldb
  for _, ft in ipairs(M.lldb_filetypes) do
    dap.configurations[ft] = M.c_configurations()
  end
  dap.adapters["pwa-node"] = M.js_adapter()
  dap.adapters.node = M.node_adapter
  for _, ft in ipairs(M.js_filetypes) do
    dap.configurations[ft] = M.js_configurations()
  end
  dap.configurations.scala = M.scala_configurations()
  dap.providers.configs["ach.haskell"] = M.haskell_configs
  require("dap-python").setup(M.bin .. "/debugpy-adapter")
  require("mason-nvim-dap").setup({ automatic_installation = false, ensure_installed = {}, handlers = M.handlers() })
  M.ui()
  require("nvim-dap-virtual-text").setup({})
end

return M
