# Languages

Written by `scripts/check --full`, which installs what each language needs, short of anything from Homebrew or Xcode, and tries each layer on that language's sample in `tests/fixtures/samples.lua`. A cell names the tools that worked. `none` means the configuration names no tool for that layer, `not working` names a tool that was installed and failed its check, `waiting` names one waiting on a runtime or a Homebrew or Xcode program that is missing on this Mac, and `check failed` means the language's check did not finish. Server covers the servers that take the sample's file type, and Grammar is Harper. A language with no formatter listed may still be formatted by its server, which this table does not measure.

Measured on 2026-10-12 with Neovim 0.12.6.

| Language | Tree-sitter | Server | Formatter | Linter | Grammar |
| --- | --- | --- | --- | --- | --- |
| angular | angular | angularls, tailwindcss | prettier | none | none |
| ansible | yaml | ansiblels | none | none | none |
| asm | asm | asm_lsp | none | none | none |
| astro | astro | astro, tailwindcss | none | none | none |
| awk | awk | awk_ls | none | none | none |
| bsv | bsv | none | none | none | none |
| c | c | clangd | clang_format | none | harper_ls |
| clojure | clojure | clojure_lsp | none | none | harper_ls |
| cmake | cmake | neocmake | gersemi | cmakelint | harper_ls |
| css | css | cssls, tailwindcss | prettier | none | none |
| csv | csv | none | none | none | none |
| dart | dart | waiting: dartls | waiting: dart_format | none | harper_ls |
| devicetree | devicetree | none | none | none | none |
| docker | dockerfile | dockerls | none | hadolint | none |
| dot | dot | dotls | none | none | none |
| dotnet | c_sharp | csharp_ls | csharpier | none | harper_ls |
| elixir | elixir | elixirls | none | none | harper_ls |
| elm | elm | elmls | elm_format | none | none |
| ember | glimmer | ember | prettier | none | none |
| erlang | erlang | elp | none | none | none |
| firrtl | firrtl | none | none | none | none |
| fish | fish | waiting: fish_lsp | waiting: fish_indent | none | none |
| fortran | fortran | fortls | none | none | none |
| git | gitcommit | none | none | none | harper_ls |
| gleam | gleam | waiting: gleam | waiting: gleam | none | harper_ls |
| glsl | glsl | glsl_analyzer | none | none | none |
| go | go | gopls | goimports, gofumpt | golangcilint | harper_ls |
| graphql | graphql | graphql | prettier | none | none |
| groovy | groovy | groovyls | none | none | harper_ls |
| haskell | haskell | waiting: haskell-tools.nvim | waiting: fourmolu | waiting: hlint | waiting: harper_ls |
| helm | helm | helm_ls | none | none | none |
| hlsl | hlsl | slangd | none | none | none |
| html | html | html, emmet_language_server, tailwindcss | prettier | none | harper_ls |
| ini | ini | none | none | none | none |
| java | java | jdtls | none | none | harper_ls |
| jq | jq | none | none | none | none |
| json | json | jsonls | prettier | none | none |
| julia | julia | waiting: julials | none | none | none |
| just | just | just | none | none | none |
| kconfig | kconfig | none | none | none | none |
| kotlin | kotlin | kotlin_language_server | ktlint | ktlint | harper_ls |
| lean | none | waiting: leanls | none | none | none |
| linker | linkerscript | none | none | none | none |
| llvm | llvm | none | none | none | none |
| lua | lua | lua_ls | stylua | none | harper_ls |
| make | make | autotools_ls | none | none | none |
| markdown | markdown | marksman | prettier, markdownlint-cli2 | markdownlint-cli2 | harper_ls |
| meson | meson | mesonlsp | none | none | none |
| mlir | mlir | mlir_lsp_server | none | none | none |
| ninja | ninja | none | none | none | none |
| nix | nix | waiting: nil_ls | waiting: nixfmt | statix | waiting: harper_ls |
| nushell | nu | waiting: nushell | none | none | none |
| ocaml | ocaml | waiting: ocamllsp | waiting: ocamlformat | none | none |
| perl | perl | perlnavigator | none | none | none |
| php | php | waiting: intelephense | waiting: php_cs_fixer | waiting: phpcs | waiting: harper_ls |
| powershell | powershell | waiting: powershell_es | none | none | none |
| prisma | prisma | prismals | none | none | none |
| proto | proto | buf_ls | buf | none | none |
| python | python | basedpyright, ruff | ruff_format | none | harper_ls |
| r | r | r_language_server | none | none | none |
| rego | rego | regols, regal | none | none | none |
| ruby | ruby | ruby_lsp, rubocop | rubocop | none | harper_ls |
| rust | rust | rust-analyzer | none | none | harper_ls |
| scala | scala | metals | none | none | harper_ls |
| sh | bash | bashls | shfmt | none | harper_ls |
| solidity | solidity | solidity_ls | none | none | harper_ls |
| sql | sql | none | sqlfluff | sqlfluff | none |
| starlark | starlark | starpls | buildifier | none | none |
| svelte | svelte | svelte, tailwindcss | none | none | none |
| swift | swift | sourcekit | none | none | harper_ls |
| systemverilog | systemverilog | verible | verible | none | none |
| tablegen | tablegen | tblgen_lsp_server | none | none | none |
| tcl | tcl | tclsp | none | tclint | none |
| terraform | terraform | terraformls | none | tflint | none |
| tex | latex | texlab | none | none | harper_ls |
| text | none | none | none | none | harper_ls |
| thrift | thrift | thriftls | none | none | none |
| toml | toml | taplo | taplo | none | harper_ls |
| twig | twig | twiggy_language_server | none | none | none |
| typescript | typescript | vtsls, eslint, tailwindcss | prettier | none | harper_ls |
| typst | typst | tinymist | typstyle | none | harper_ls |
| veryl | veryl | veryl_ls | none | none | none |
| vhdl | vhdl | vhdl_ls | none | none | none |
| vim | vim | vimls | none | none | none |
| vue | vue | vue_ls, vtsls, tailwindcss | prettier | none | none |
| wgsl | wgsl | wgsl_analyzer | none | none | none |
| xml | xml | lemminx | none | none | none |
| yaml | yaml | yamlls | prettier | none | none |
| zig | zig | waiting: zls | none | none | waiting: harper_ls |

## Waiting on an install

The full run never installs from Homebrew or Xcode, so each command below stays waiting until it is run by hand, or, for a Homebrew command, until a file of one of its languages is opened in Neovim and the offer to install it is accepted. A tool waiting on one of them is not a failure.

- `brew install dart-sdk`, for dart
- `brew install elan-init && elan default stable`, for lean
- `brew install fish`, for fish
- `brew install ghcup && ghcup install ghc --set recommended`, for haskell
- `brew install gleam`, for gleam
- `brew install julia`, for julia
- `brew install nixfmt`, for nix
- `brew install nushell`, for nushell
- `brew install opam && opam init -n -y`, for ocaml
- `brew install php`, for php
- `brew install powershell`, for powershell
- `brew install zig`, for zig
- `curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh`, for nix
