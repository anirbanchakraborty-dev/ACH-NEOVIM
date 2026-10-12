-- mason-lock.json: the version of every Mason package, so a second Mac
-- installs what this one has. A package's line is added the first time it
-- installs, and an existing line changes only under :AchMasonUpdate. Lines
-- for packages not installed on this Mac are kept, since another Mac may use
-- them. Every function that writes runs on the main loop.
local M = {}

M.path = vim.g.ach_root .. "/mason-lock.json"

function M.read(path)
  local f = io.open(path or M.path)
  if not f then
    return {}
  end
  local text = f:read("*a")
  f:close()
  local ok, lock = pcall(vim.json.decode, text)
  return ok and type(lock) == "table" and lock or {}
end

-- One package to a line, sorted, so a diff shows exactly what moved.
function M.encode(lock)
  local names = vim.tbl_keys(lock)
  if #names == 0 then
    return "{}\n"
  end
  table.sort(names)
  local lines = {}
  for _, name in ipairs(names) do
    lines[#lines + 1] = ("  %s: %s"):format(vim.json.encode(name), vim.json.encode(lock[name]))
  end
  return "{\n" .. table.concat(lines, ",\n") .. "\n}\n"
end

function M.write(lock, path)
  local f = assert(io.open(path or M.path, "w"))
  f:write(M.encode(lock))
  f:close()
end

-- Installs a package at its pinned version, or at the latest when it has no
-- pin, and pins what Mason installed. done(ok, err) runs on the main loop.
function M.install(name, done)
  local pkg = require("mason-registry").get_package(name)
  local function finish(ok, err)
    vim.schedule(function() done(ok, err) end)
  end
  -- Installed from the :Mason window a moment ago: wait for that install
  -- rather than start a second, which mason.nvim refuses.
  if pkg:is_installing() then
    local succeeded, failed
    succeeded = function()
      pkg:off("install:failed", failed)
      finish(true)
    end
    failed = function(err)
      pkg:off("install:success", succeeded)
      finish(false, tostring(err))
    end
    pkg:once("install:success", succeeded)
    pkg:once("install:failed", failed)
    return
  end
  local pinned = M.read()[name]
  pkg:install({ version = pinned }, function(ok, result)
    vim.schedule(function()
      if ok and not pinned then
        local lock = M.read()
        lock[name] = pkg:get_installed_version()
        M.write(lock)
      end
      done(ok, not ok and tostring(result) or nil)
    end)
  end)
end

-- Writes the installed version of each installed package into the lock,
-- over an existing line only when overwrite is set. Returns the names whose
-- line was added or changed.
local function pin(overwrite)
  local lock, touched = M.read(), {}
  for _, pkg in ipairs(require("mason-registry").get_installed_packages()) do
    local version = pkg:get_installed_version()
    if version and lock[pkg.name] ~= version and (overwrite or lock[pkg.name] == nil) then
      lock[pkg.name] = version
      touched[#touched + 1] = pkg.name
    end
  end
  table.sort(touched)
  M.write(lock)
  return touched
end

-- :AchMasonLock. Pins each package installed by hand from the :Mason window.
function M.adopt() return pin(false) end

-- :AchMasonUpdate. Refreshes the registry, installs the latest version of
-- every installed package that is behind, and moves each one's pin.
function M.update(done)
  local registry = require("mason-registry")
  registry.refresh(function()
    vim.schedule(function()
      local stale = {}
      for _, pkg in ipairs(registry.get_installed_packages()) do
        local latest = pkg:get_latest_version()
        if not pkg:is_installing() and pkg:get_installed_version() ~= latest then
          stale[#stale + 1] = { pkg = pkg, version = latest }
        end
      end
      local failed, remaining = {}, #stale
      local function finish()
        table.sort(failed)
        done(pin(true), failed)
      end
      if remaining == 0 then
        return finish()
      end
      for _, s in ipairs(stale) do
        s.pkg:install({ version = s.version }, function(ok)
          vim.schedule(function()
            if not ok then
              failed[#failed + 1] = s.pkg.name
            end
            remaining = remaining - 1
            if remaining == 0 then
              finish()
            end
          end)
        end)
      end
    end)
  end)
end

return M
