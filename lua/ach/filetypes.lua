-- File types Neovim 0.12 does not detect by itself, and parsers that serve
-- more than one file type. init.lua calls setup() before lazy.nvim starts, so
-- a file named on the command line is recognised when it first opens.
local M = {}

-- Extensions Neovim has no rule for. A .mli file is an OCaml interface, which
-- has its own parser; Neovim calls it plain ocaml.
M.extensions = {
  bsv = "bsv",
  hlsl = "hlsl",
  hlsli = "hlsl",
  mdx = "markdown.mdx",
  mli = "ocamlinterface",
  veryl = "veryl",
  xdc = "xdc",
}

-- File types that borrow another language's parser.
M.parsers = {
  clojure = { "edn" },
  latex = { "plaintex" },
  markdown = { "rmd", "quarto" },
  objc = { "objcpp" },
  sql = { "mysql", "plsql" },
  tcl = { "sdc", "xdc" },
}

-- A YAML file under templates/ is a Helm template only inside a chart, which
-- is a folder holding Chart.yaml. Returning nil lets Neovim carry on and call
-- it plain YAML.
local function helm(path) return vim.fs.root(path, "Chart.yaml") and "helm" or nil end

-- Patterns run before Neovim's extension rules, so these win over plain YAML.
M.patterns = {
  [".*/templates/.*%.ya?ml"] = helm,
  [".*/templates/.*%.tpl"] = helm,
  [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
  [".*/roles/.*/tasks/.*%.ya?ml"] = "yaml.ansible",
  [".*/roles/.*/handlers/.*%.ya?ml"] = "yaml.ansible",
  [".*/group_vars/.*%.ya?ml"] = "yaml.ansible",
  [".*/host_vars/.*%.ya?ml"] = "yaml.ansible",
}

-- Compose files are plain YAML to Neovim, and the compose server attaches only
-- to this file type.
M.filenames = {
  ["compose.yaml"] = "yaml.docker-compose",
  ["compose.yml"] = "yaml.docker-compose",
  ["docker-compose.yaml"] = "yaml.docker-compose",
  ["docker-compose.yml"] = "yaml.docker-compose",
}

function M.setup()
  vim.filetype.add({ extension = M.extensions, filename = M.filenames, pattern = M.patterns })
  for parser, fts in pairs(M.parsers) do
    vim.treesitter.language.register(parser, fts)
  end
end

return M
