-- Prints require("ach.lang").formulae(), one per line.
-- Usage: nvim --clean -l scripts/on_demand.lua ROOT, where ROOT is the repository.
package.path = arg[1] .. "/lua/?.lua;" .. package.path
for _, formula in ipairs(require("ach.lang").formulae()) do
  io.write(formula, "\n")
end
