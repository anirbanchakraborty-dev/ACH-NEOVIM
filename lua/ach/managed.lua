-- Rust, Haskell, Java, Scala and Lean, whose servers are started by a plugin
-- of their own rather than by vim.lsp.enable. Each plugin's automatic start
-- is off, and the installer calls M.start once a buffer's packages are in
-- place, so each server starts after its program exists, and only once.
local M = {}

-- The name each plugin gives its client.
M.clients = {
  rustaceanvim = "rust-analyzer",
  ["haskell-tools.nvim"] = "haskell-tools.nvim",
  ["nvim-jdtls"] = "jdtls",
  ["nvim-metals"] = "metals",
  ["lean.nvim"] = "leanls",
}

-- Where Mason keeps the files its packages share with other programs, such
-- as the jars jdtls loads.
M.share = vim.fn.stdpath("data") .. "/mason/share"

-- Metals, installed by Coursier into the data folder.
M.metals_program = vim.fn.stdpath("data") .. "/metals/metals"

-- lean.nvim's suggested keys, after the local leader: key, command,
-- description.
M.lean = {
  { "i", "LeanInfoviewToggle", "Lean Infoview" },
  { "<Tab>", "LeanGotoInfoview", "Go to Infoview" },
  { "v", "LeanInfoviewViewOptions", "Infoview Options" },
  { "x", "LeanInfoviewAddPin", "Add Pin" },
  { "c", "LeanInfoviewClearPins", "Clear Pins" },
  { "p", "LeanInfoviewPinTogglePause", "Pause Pins" },
  { "dx", "LeanInfoviewSetDiffPin", "Set Diff Pin" },
  { "dc", "LeanInfoviewClearDiffPin", "Clear Diff Pins" },
  { "dd", "LeanInfoviewToggleAutoDiffPin", "Auto Diff" },
  { "dt", "LeanInfoviewToggleNoClearAutoDiffPin", "Auto Diff, Clearing Pins" },
  { "w", "LeanInfoviewEnableWidgets", "Enable Widgets" },
  { "W", "LeanInfoviewDisableWidgets", "Disable Widgets" },
  { "s", "LeanInfoviewAcceptSuggestion", "Accept Suggestion" },
  { "\\", "LeanAbbreviationsReverseLookup", "How to Type This Symbol" },
  { "r", "LeanRestartFile", "Restart Lean for This File" },
}

-- True when any of the programs is on the path.
local function executable(...)
  for _, name in ipairs({ ... }) do
    if vim.fn.executable(name) == 1 then
      return true
    end
  end
  return false
end

-- Runs fn with buf as the current buffer, for the plugins that attach to
-- whichever buffer is current, then puts the old one back.
local function in_buffer(buf, fn) vim.api.nvim_buf_call(buf, fn) end

-- A Java project's root: the nearest folder holding a build wrapper or a
-- repository, so a multi-module build is one project; failing that, the
-- nearest build file; failing that, the file's own folder.
function M.jdtls_root(buf)
  return vim.fs.root(buf, { "gradlew", "mvnw", ".git" })
    or vim.fs.root(buf, { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" })
    or vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
end

-- The test runner jar and the coverage agent sit beside java-test's bundles
-- but are not bundles themselves; jdtls refuses to load them.
local not_bundles = {
  ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
  ["jacocoagent.jar"] = true,
}

-- The jars jdtls loads as plugins: the debug adapter's and java-test's, each
-- when Mason has installed it.
function M.jdtls_bundles()
  local bundles = {}
  local debug = M.share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
  if vim.uv.fs_stat(debug) then
    bundles[1] = debug
  end
  local jars = vim.fn.glob(M.share .. "/java-test/*.jar", true, true)
  table.sort(jars)
  for _, jar in ipairs(jars) do
    if not not_bundles[vim.fs.basename(jar)] then
      bundles[#bundles + 1] = jar
    end
  end
  return bundles
end

-- jdtls's configuration for buf. Its workspace data goes in the cache, in a
-- folder named for the project and a hash of its full path, so two projects
-- with the same folder name keep separate indexes. Lombok is loaded as an
-- agent when Mason has it, so its generated methods resolve.
function M.jdtls_config(buf)
  local root = M.jdtls_root(buf)
  local data = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
  local cmd = { "jdtls" }
  local lombok = M.share .. "/jdtls/lombok.jar"
  if vim.uv.fs_stat(lombok) then
    cmd[#cmd + 1] = "--jvm-arg=-javaagent:" .. lombok
  end
  vim.list_extend(cmd, { "-data", data })
  return {
    cmd = cmd,
    root_dir = root,
    capabilities = require("ach.lsp").capabilities(),
    init_options = { bundles = M.jdtls_bundles() },
  }
end

local installing = false

-- Installs Metals with Coursier, then starts it in every loaded Scala buffer.
-- One install at a time; a Scala buffer opened meanwhile waits for it. With
-- Coursier missing it does nothing, since the installer's runtime check has
-- already said how to install it.
local function install_metals()
  if installing or vim.fn.executable("coursier") ~= 1 then
    return
  end
  installing = true
  vim.notify("Installing Metals for Scala; it starts when the install finishes")
  local cmd = { "coursier", "install", "--install-dir", vim.fs.dirname(M.metals_program), "metals" }
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      installing = false
      if res.code ~= 0 then
        local lines = vim.split(vim.trim(res.stderr or ""), "\n")
        vim.notify("Metals did not install: " .. lines[#lines], vim.log.levels.ERROR)
        return
      end
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local e = vim.api.nvim_buf_is_loaded(b) and require("ach.lang").for_ft(vim.bo[b].filetype)
        if e and e.managed == "nvim-metals" then
          M.start(b, e, { install = false })
        end
      end
    end)
  end)
end

local starters = {
  rustaceanvim = function(buf)
    if executable("rust-analyzer") then
      require("rustaceanvim.lsp").start(buf)
    end
  end,

  ["haskell-tools.nvim"] = function(buf)
    if executable("haskell-language-server-wrapper", "haskell-language-server") then
      in_buffer(buf, function() require("haskell-tools").lsp.start(buf) end)
    end
  end,

  -- The debugger is registered first, so it keeps hot code replace; see
  -- ach.dap.java.
  ["nvim-jdtls"] = function(buf)
    if executable("jdtls") then
      require("ach.dap").java()
      require("jdtls").start_or_attach(M.jdtls_config(buf), nil, { bufnr = buf })
    end
  end,

  ["nvim-metals"] = function(buf, opts)
    if vim.fn.executable(M.metals_program) == 1 then
      local metals = require("metals")
      local config = metals.bare_config()
      config.settings = { metalsBinaryPath = M.metals_program }
      config.capabilities = require("ach.lsp").capabilities()
      config.on_attach = function() metals.setup_dap() end
      in_buffer(buf, function() metals.initialize_or_attach(config) end)
    elseif opts.install ~= false then
      install_metals()
    end
  end,

  -- Requiring lean loads lean.nvim, if a .lean file has not already, which
  -- puts its lsp/leanls.lua on the runtime path.
  ["lean.nvim"] = function()
    if executable("lean") then
      require("lean")
      vim.lsp.enable("leanls")
    end
  end,
}

-- Starts the server of buf's managed language, unless buf is not a file or
-- already has that client. A missing Metals is installed first, unless
-- opts.install is false.
function M.start(buf, entry, opts)
  local start = starters[entry.managed]
  if not start or not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return
  end
  if #vim.lsp.get_clients({ bufnr = buf, name = M.clients[entry.managed] }) > 0 then
    return
  end
  start(buf, opts or {})
end

-- Sets the Lean keys in buf, and names the diff-pin keys for which-key.
function M.lean_keys(buf)
  for _, k in ipairs(M.lean) do
    vim.keymap.set("n", "<localleader>" .. k[1], "<Cmd>" .. k[2] .. "<CR>", { buffer = buf, desc = k[3] })
  end
  require("which-key").add({
    { "<localleader>d", group = "diff pins", icon = require("ach.icons").group("diff pins"), buffer = buf },
  })
end

local did_setup = false

-- Turns off each plugin's own start before any of them loads, and creates
-- the hooks for Lean's keys and for a Scala file's first write.
function M.setup()
  if did_setup then
    return
  end
  did_setup = true
  vim.g.rustaceanvim = {
    server = {
      auto_attach = false,
      default_settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
    },
  }
  -- haskell-tools' search for launch choices runs when debugging starts,
  -- through ach.dap's provider, rather than as each file opens.
  vim.g.haskell_tools = { hls = { auto_attach = false }, dap = { auto_discover = false } }
  vim.g.lean_config = { lsp = { enable = false } }

  local group = vim.api.nvim_create_augroup("ach_managed", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "lean",
    callback = function(ev) M.lean_keys(ev.buf) end,
  })
  -- nvim-metals attaches only to a file that is on disk, so a new Scala file
  -- gets Metals when it is first written. A save never installs it; opening
  -- the file already tried.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local e = require("ach.lang").for_ft(vim.bo[ev.buf].filetype)
      if e and e.managed == "nvim-metals" then
        M.start(ev.buf, e, { install = false })
      end
    end,
  })
end

return M
