-- Language runtimes Mason cannot install. setup() puts Homebrew's Java on
-- the path, because macOS ships /usr/bin/java as a stub that only offers to
-- install Java, and Java, Kotlin, Groovy and Scala tools all look for a real
-- one. It also adds the folders a shell profile would, so Neovim started from
-- the Dock finds the same programs as Neovim started from a terminal. check()
-- says whether a runtime works, asking once per session.
local M = {}

M.kegs = { "/opt/homebrew/opt/openjdk@21", "/opt/homebrew/opt/openjdk" }

-- Homebrew's Ruby is keg-only: it is not linked into /opt/homebrew/bin, so
-- without this the path finds macOS's own Ruby 2.6, which ruby-lsp cannot run
-- on. It goes first so it wins over /usr/bin/ruby.
M.first = { "/opt/homebrew/opt/ruby/bin" }

-- Toolchain managers install into folders of their own: rustup (keg-only in
-- Homebrew) and the programs cargo builds, ghcup for Haskell, elan for Lean,
-- and opam for OCaml, whose `opam init -n` makes a switch named default and
-- leaves the shell's startup files alone. Homebrew's LLVM is keg-only too, and
-- its folder holds mlir-lsp-server and tblgen-lsp-server. They go last, so a
-- program Homebrew also provides is still found in Homebrew first, and LLVM's
-- clang never stands in front of Apple's. Each is added only once it exists,
-- and setup() runs again after every Homebrew install, so a folder that
-- install made is on the path straight away.
M.last = {
  "/opt/homebrew/opt/rustup/bin",
  "~/.cargo/bin",
  "~/.ghcup/bin",
  "~/.elan/bin",
  "~/.opam/default/bin",
  "/opt/homebrew/opt/llvm/bin",
}

local function on_path(dir)
  for _, d in ipairs(vim.split(vim.env.PATH or "", ":", { plain = true })) do
    if d ~= "" and vim.fs.normalize(d) == dir then
      return true
    end
  end
  return false
end

-- Adds each folder that exists and is not already on the path. Folders added
-- to the front go in reverse, so the list's first entry ends up first.
local function add(dirs, front)
  local from, to, step = 1, #dirs, 1
  if front then
    from, to, step = #dirs, 1, -1
  end
  for i = from, to, step do
    local dir = vim.fs.normalize(dirs[i])
    if vim.fn.isdirectory(dir) == 1 and not on_path(dir) then
      vim.env.PATH = front and (dir .. ":" .. vim.env.PATH) or (vim.env.PATH .. ":" .. dir)
    end
  end
end

local function java(kegs)
  if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
    return nil
  end
  for _, keg in ipairs(kegs) do
    local home = keg .. "/libexec/openjdk.jdk/Contents/Home"
    if vim.uv.fs_stat(home .. "/bin/java") then
      vim.env.JAVA_HOME = home
      vim.env.PATH = home .. "/bin:" .. vim.env.PATH
      return home
    end
  end
  return nil
end

-- opts: { java = kegs, first = folders, last = folders }, each defaulting to
-- the lists above. Returns the JDK's home when it set one.
function M.setup(opts)
  opts = opts or {}
  add(opts.first or M.first, true)
  add(opts.last or M.last, false)
  return java(opts.java or M.kegs)
end

-- Runs argv and reports whether it exited 0. A program that is not on the
-- path is false at once, since vim.system raises for it.
function M.probe(argv, cb)
  if vim.fn.executable(argv[1]) ~= 1 then
    return cb(false)
  end
  local ok = pcall(vim.system, argv, { text = true, timeout = 10000 }, function(result)
    vim.schedule(function() cb(result.code == 0) end)
  end)
  if not ok then
    cb(false)
  end
end

local results, waiting = {}, {}

function M.check(runtime, cb)
  local name = runtime.name
  if results[name] ~= nil then
    return cb(results[name])
  end
  if waiting[name] then
    table.insert(waiting[name], cb)
    return
  end
  waiting[name] = { cb }
  M.probe(runtime.check, function(ok)
    results[name] = ok
    local list = waiting[name]
    waiting[name] = nil
    for _, f in ipairs(list) do
      f(ok)
    end
  end)
end

-- Forgets what check found for the runtime named name, as once Homebrew has
-- installed it, or for every runtime when name is nil.
function M.reset(name)
  if name then
    results[name] = nil
  else
    results, waiting = {}, {}
  end
end

return M
