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
  return vim.env.TERM_PROGRAM == "ghostty" or term:find("ghostty", 1, true) ~= nil or term:find("kitty", 1, true) ~= nil
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
