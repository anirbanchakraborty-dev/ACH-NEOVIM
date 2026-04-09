# ACH-NEOVIM

A personal Neovim configuration for macOS. Built around lazy.nvim with a
custom deep-ocean tokyonight palette, on-demand tooling, and zero manual
setup. Run one script and the editor is ready.

---

## Highlights

- **One-command install.** `./install.sh` provisions Homebrew, the latest
  stable Neovim, and the Claude Code CLI. Re-run any time — every step is
  idempotent and only touches what is missing.
- **On-demand everything.** No `ensure_installed` lists. The first time you
  open a Python file, pyright + ruff are installed and attached. The first
  time you open a Go file, gopls + gofumpt arrive. Treesitter parsers,
  formatters, and linters all follow the same pattern.
- **Native LSP client.** Uses Neovim 0.11+'s `vim.lsp.config` /
  `vim.lsp.enable` flow with `nvim-lspconfig` providing the default per-server
  configs. blink.cmp's capabilities are merged into every server
  automatically. **45+ languages supported** out of the box across web,
  systems, JVM, .NET, infra/data, and niche languages — all installed
  on demand the first time you open a file in that language.
- **Schema-aware JSON / YAML.** `b0o/SchemaStore.nvim` is wired into both
  `jsonls` and `yamlls` via `before_init` hooks, giving completion +
  validation for `package.json`, `tsconfig.json`, GitHub Actions, GitLab
  CI, Kubernetes manifests, docker-compose, and 1200+ other schemas
  with no manual setup. Lazy-loaded so it costs zero startup time.
- **Per-project LSP overrides.** `folke/neoconf.nvim` auto-merges
  `.neoconf.json` and `.vscode/settings.json` from the project root
  into the LSP config when each server attaches. Translates VS Code
  settings keys (`eslint.workingDirectories`, `typescript.tsdk`,
  `json.schemas`, etc.) into the equivalent LSP server settings, so
  cloning a JS/TS project that ships shared editor settings just works.
- **Format + lint pipeline.** `conform.nvim` handles format-on-save with a
  prettierd → prettier fallback chain for web files, gated by a
  `prettier --file-info` parser check so prettier silently falls back to
  the LSP formatter on filetypes it can't parse. `nvim-lint` runs
  external linters (shellcheck, markdownlint, hadolint, yamllint,
  golangci-lint, ansible-lint, tflint, sqlfluff, solhint, cmakelint) via a
  debounced dispatcher and feeds results into `vim.diagnostic`. ESLint
  diagnostics + auto-fix-on-save come from the **eslint LSP** (real-time,
  with code actions) rather than the standalone `eslint_d` linter; the
  LSP's `source.fixAll.eslint` is invoked from conform's `format_on_save`
  callback right before prettier so eslint fixes lint issues and prettier
  has the final word on cosmetic formatting. Markdown
  picks up two **conditional** formatters: `markdown-toc` only fires on
  buffers with a `<!-- toc -->` marker, `markdownlint-cli2` only fires
  when there are existing markdownlint diagnostics.
- **Claude Code integration.** `coder/claudecode.nvim` ships claude inside
  Neovim as a snacks-themed split with native diff review and selection
  tracking. The CLI is installed automatically by `install.sh`.
- **Deep ocean palette.** A custom tokyonight override (`#011628` background,
  `#011423` floats, `#0A64AC` search) themed across every plugin's UI:
  fzf-lua, lazy, mason, which-key, snacks, noice, trouble, diffview, and
  git-conflict.
- **Central icon table.** Every Nerd Font glyph used in the config lives in
  `nvim/lua/config/icons.lua`. Plugin files reference them by name —
  there's exactly one place to swap a glyph.
- **Curated keymaps.** Every binding has a description, every which-key entry
  has an icon. Discoverable by holding `<Space>` on any prefix.
- **Polished UI.** snacks.dashboard on startup, snacks.notifier for toasts,
  snacks.indent rainbow guides, bufferline tabs with diagnostics, lualine
  with a custom ocean theme, noice floating cmdline, rainbow-delimiters,
  inline color preview, snacks.explorer file tree, and a flash-style
  2-character jump motion.
- **Productivity tools.** Yank ring with history cycling (`yanky.nvim`),
  per-project file marks (`harpoon2`), live in-buffer LSP rename preview
  (`inc-rename.nvim`), treesitter docstring generator (`neogen`), real
  refactoring operations like extract function / inline variable
  (`refactoring.nvim`), task runner with template auto-discovery
  (`overseer.nvim`), persistent symbol outline sidebar (`outline.nvim`),
  and supercharged `<C-a>` / `<C-x>` for booleans, dates, hex colors,
  weekdays, and language-specific keywords (`dial.nvim`).
- **Language extras.** Inline markdown rendering with live conceal
  (`render-markdown.nvim`, `<leader>um`), browser markdown preview
  (`markdown-preview.nvim`, `<leader>cp`), full LaTeX environment with
  forward/inverse search (`vimtex`), Python virtualenv picker
  (`venv-selector.nvim`, `<leader>cv`), and clangd extras (AST viewer,
  inlay hints, source/header switch via `<leader>ch`) from
  `clangd_extensions.nvim`.
- **Treesitter on `main` branch.** Runs nvim-treesitter's main branch
  (the complete rewrite that delegates highlighting / folds /
  incremental selection to Neovim 0.12+'s built-in treesitter API).
  Parsers install on demand via the new async install API the first
  time you open a file in that language. Highlighting + folds wire up
  through `autocmds.lua`'s `TreesitterFolds` group; experimental
  treesitter indent (`vim.bo.indentexpr`) is enabled per buffer in
  `treesitter.lua`'s install autocmd. Incremental selection
  (`<C-Space>` to grow, `<BS>` to shrink) is preserved by a small
  in-config node-stack helper since main dropped the master branch's
  `incremental_selection` module. Textobjects also runs from
  `nvim-treesitter-textobjects` main branch with the new keymap-driven
  `select.select_textobject` / `move.goto_*` API.
- **Sticky scope header.** `nvim-treesitter-context` pins the current
  function/class/method signature to the top of the buffer when you
  scroll past its definition. Cursor-mode tracking with a 3-line cap
  so deeply-nested scopes never take over the screen. Toggle with
  `<leader>ut`.
- **GitHub inside nvim.** `pwntester/octo.nvim` lists/searches issues
  and PRs (`<leader>gi`/`<leader>gI`/`<leader>gp`/`<leader>gP`), browses
  repos (`<leader>gr`), and runs full-text search (`<leader>gS`). PR
  review (line comments, threads, reactions, merge) all happens in
  buffers using fzf-lua as the picker. Authenticates via the `gh` CLI —
  run `gh auth login` once before first use.
- **Tailwind class highlighting.** `mini.hipatterns` renders Tailwind
  utility class names like `bg-blue-500` or `text-emerald-300` with the
  actual color inline (background tint + contrasting fg). Works in
  html / css / js / ts / vue / svelte / astro / handlebars / twig /
  postcss. The Tailwind palette lives in `config/tailwind_colors.lua`
  as a pure data module. Coexists with `nvim-colorizer` (which still
  handles hex / rgb / hsl / CSS named colors) — zero overlap.
- **Sidebar layout manager.** `folke/edgy.nvim` corrals Trouble,
  Outline, Grug Far, terminals (toggleterm + snacks), quickfix, help,
  and noice into edge groups (bottom + right). Resize panes with
  `<C-arrow>` inside an edgy window. A companion bufferline patch
  reserves a "Sidebar" offset so the bufferline tabs stay visible
  when an explorer or outline pane is open. Toggle with `<leader>ue`,
  pick a window with `<leader>uE`.

---

## Installation

```bash
git clone https://github.com/anirbanchakraborty-dev/ACH-NEOVIM.git
cd ACH-NEOVIM
./install.sh
```

`install.sh` will:

1. Install **Homebrew** if it isn't already on the system.
2. Install or upgrade **Neovim** to the latest stable release (validated
   against the GitHub releases API).
3. Install the **Claude Code CLI** via the official native installer
   (`~/.local/bin/claude`, auto-updates in the background) and append the
   PATH export to `~/.zshrc` if it isn't already there.
4. Symlink `nvim/` to `~/.config/nvim` (any existing config is moved to a
   timestamped backup).

The script is idempotent — re-running it skips anything already in place.

### Optional: SystemVerilog / Verilog toolchain

If you do hardware design, add the `--with-hdl` flag to also install
the open-source HDL toolchain via Homebrew:

```bash
./install.sh --with-hdl
```

That pulls in **verible** (LSP, formatter, lint engine), **verilator**
(linter + simulator), **icarus-verilog** (`iverilog` + `vvp` simulator
pair), **yosys** (synthesis), **surfer** (waveform viewer), and
**netlistsvg** (yosys-JSON → SVG schematic renderer). The config wires
all six into the editor — see [Hardware / HDL](#hardware--hdl) below
for the full feature list.

Skip the flag on machines that aren't doing hardware work — none of
these tools are needed for the rest of the editor stack.

After install, launch `nvim`. lazy.nvim bootstraps itself, downloads every
plugin, and shows the dashboard. Open a file in any supported language and
the matching LSP server / formatter / linter installs in the background.

---

## Requirements

- **macOS** (Apple Silicon or Intel)
- **Git**
- **iTerm2** (or any terminal) with a **Nerd Font** — MesloLGS NF, JetBrains
  Mono Nerd, FiraCode Nerd, etc. are all supported.
- **Internet connection** for initial Homebrew, Neovim, plugin, and tool
  downloads.

---

## Languages

LSP, formatting, and linting are wired up out of the box for the languages
below. Everything installs on demand the first time you open a file in
that language — there is no manual setup pass and no `ensure_installed`
list.

### Core stack (used daily)

| Language        | LSP                              | Formatter                          | Linter         |
|-----------------|----------------------------------|------------------------------------|----------------|
| Lua             | lua_ls                           | stylua                             | —              |
| Python          | pyright + ruff (hover disabled)  | ruff (organize+fmt)                | ruff (LSP)     |
| TypeScript / JS | ts_ls + eslint (LSP)             | prettierd / prettier + eslint fix  | eslint (LSP)   |
| HTML / CSS      | html + emmet, cssls              | prettierd / prettier               | —              |
| JSON / YAML     | jsonls / yamlls + SchemaStore    | prettierd / prettier               | yamllint       |
| Markdown        | marksman                         | prettier + markdown-toc + mdlint   | markdownlint   |
| Bash / Zsh      | bashls                           | shfmt                              | shellcheck     |
| C / C++         | clangd + clangd_extensions       | clang-format                       | —              |
| Go              | gopls (full inlay hints)         | goimports + gofumpt                | golangci-lint  |
| LaTeX / BibTeX  | texlab + vimtex                  | latexindent / bibtex-tidy          | —              |
| Ruby            | ruby-lsp                         | rubocop                            | —              |
| Perl            | perlnavigator                    | perltidy (system)                  | —              |
| Swift           | sourcekit-lsp (Xcode)            | swift-format (Xcode)               | —              |
| R               | languageserver (R)               | —                                  | —              |
| Dockerfile      | —                                | —                                  | hadolint       |

### Web

| Language     | LSP                         | Formatter | Notes                                           |
|--------------|-----------------------------|-----------|-------------------------------------------------|
| Angular      | angularls                   | prettier  |                                                 |
| Astro        | astro-language-server       | prettier  |                                                 |
| Svelte       | svelte-language-server      | prettier  |                                                 |
| Vue          | vue_ls (Volar)              | prettier  | standalone Volar                                |
| Tailwind CSS | tailwindcss-language-server | —         | attaches across html/css/js/ts/vue/svelte/astro |
| Ember        | ember-language-server       | prettier  |                                                 |
| Prisma       | prismals                    | prettier  |                                                 |
| Twig         | twiggy_language_server      | —         |                                                 |

### Systems / Compiled

| Language | LSP                            | Formatter             | Notes                       |
|----------|--------------------------------|-----------------------|-----------------------------|
| Rust     | rust_analyzer (clippy on save) | rustfmt (system)      |                             |
| Zig      | zls                            | zig fmt (system)      |                             |
| Nix      | nil_ls                         | alejandra             |                             |
| Haskell  | haskell-language-server (HLS)  | ormolu                | heavy install (~2 GB)       |
| OCaml    | ocaml-lsp                      | ocamlformat (opam)    |                             |
| Clojure  | clojure-lsp                    | zprint                |                             |
| Erlang   | erlang-ls                      | erlfmt                |                             |
| Elixir   | elixir-ls                      | mix format (system)   |                             |
| Gleam    | gleam (system)                 | gleam format (system) | bundled with `gleam` binary |
| Dart     | dart language-server (system)  | dart format (system)  | bundled with Dart SDK       |
| C# / VB  | omnisharp                      | csharpier             |                             |
| Kotlin   | kotlin-language-server         | ktlint                |                             |
| Scala    | metals                         | scalafmt              |                             |
| Java     | jdtls                          | google-java-format    | basic install — see notes   |
| PHP      | intelephense                   | php-cs-fixer / pint   |                             |

### Infra / Data

| Language     | LSP                                          | Formatter           | Linter        |
|--------------|----------------------------------------------|---------------------|---------------|
| Ansible      | ansible-language-server                      | —                   | ansible-lint  |
| CMake        | cmake-language-server                        | cmake-format        | cmakelint     |
| Helm         | helm-ls                                      | —                   | —             |
| Terraform    | terraform-ls                                 | terraform fmt       | tflint        |
| TOML         | taplo                                        | taplo               | —             |
| SQL          | sqls                                         | sqlfluff            | sqlfluff      |
| Solidity     | solidity_ls_nomicfoundation                  | forge fmt (system)  | solhint       |
| Rego (OPA)   | regal                                        | —                   | —             |
| Thrift       | — (treesitter only)                          | —                   | —             |

### Niche

| Language | LSP                                 | Formatter  | Notes             |
|----------|-------------------------------------|------------|-------------------|
| Lean     | leanls (system, via elan)           | —          |                   |
| Julia    | julials (system, LanguageServer.jl) | —          | first-run is slow |
| Nushell  | — (treesitter only)                 | —          |                   |
| Elm      | elm-language-server                 | elm-format |                   |
| Typst    | tinymist                            | typstyle   |                   |

### Hardware / HDL

SystemVerilog / Verilog support is opt-in via `./install.sh --with-hdl`,
which adds the open-source toolchain via Homebrew. Once the binaries are
on PATH, the editor stack wires up automatically the first time you open
an `.sv` / `.svh` / `.v` / `.vh` file.

| Language       | LSP                              | Formatter              | Linter               |
|----------------|----------------------------------|------------------------|----------------------|
| SystemVerilog  | svlangserver + verible           | verible-verilog-format | verilator            |
| Verilog        | svlangserver + verible           | verible-verilog-format | verilator            |

**Two LSPs attach in tandem.** `svlangserver` (mason-installed via npm)
owns cross-file navigation: `gd`, `gr`, `K` (hover), completion, and
workspace symbol search. Its `systemverilog.build_index` workspace
command fires automatically on first attach so the symbol table is
ready before you press a key. `verible` (system, via brew) owns
diagnostics + document outline; its `definitionProvider` /
`referencesProvider` / `renameProvider` are explicitly disabled in
`LspAttach` because cross-file resolution is broken in the current
verible release (verified empirically — advertises the capabilities
but returns empty cross-file). `.rules.verible_lint` files at the
project root are auto-picked up via `--rules_config_search`.

**Verilator linter is project-aware.** `nvim-lint` runs `verilator
-sv -Wall --language 1800-2017 -Wno-MULTITOP --bbox-sys --bbox-unsup
--lint-only` on every save, and a small file-local resolver in
`linting.lua` walks up from the buffer to find a `*.f` filelist at the
project root and appends `-f <filelist>` to the args. This is what lets
verilator resolve cross-folder `import pkg::*;` references via the
filelist's `-I` directives without enumerating every `.sv` file in
the linter config. Buffers that aren't inside a project with a `*.f`
filelist silently fall back to single-file lint mode.

**`run.sh` integration.** The config detects a `run.sh` script at the
project root (any shell script with that name wrapping the common HDL
workflow commands — lint / fmt / sim / wave / synth / schematic / clean)
and exposes its subcommands two ways:

- **Direct keymaps** under `<leader>R*`, filetype-gated to
  systemverilog/verilog: `Rl` lint, `Rf` fmt, `Rs` simulate (picker),
  `Ra` sim:all, `Rw` open waveform (picker), `Ry` synthesize (picker),
  `RS` schematic (picker), `Rc` check tools, `Rk` clean. Each runs
  `./run.sh <sub>` in a snacks float terminal rooted at the script's
  directory.
- **Overseer template** that surfaces every run.sh subcommand under
  `<leader>oo` with an enum picker. Gated by both filetype and run.sh
  presence so it doesn't pollute non-SV projects.

The pickers for `Rs` / `Rw` / `Ry` / `RS` glob the conventional SV
project layout (`tb/**/tb_*.sv` for testbenches, `build/*.vcd` for
waveforms, `rtl/**/*.sv` for modules). Projects that diverge from this
layout can still use the Overseer template (which takes a free-form
target string) or plain `:term ./run.sh <cmd>`.

**What gets installed by `--with-hdl`:**

| Tool             | Brew formula     | Role                                          |
|------------------|------------------|-----------------------------------------------|
| `verible`        | verible          | LSP + formatter + lint engine                 |
| `verilator`      | verilator        | Linter + simulator                            |
| `iverilog`/`vvp` | icarus-verilog   | Behavioral simulator                          |
| `yosys`          | yosys            | Synthesis (used by `<leader>Ry`)              |
| `surfer`         | surfer           | Waveform viewer (used by `<leader>Rw`)        |
| `netlistsvg`     | netlistsvg       | Schematic renderer (used by `<leader>RS`)     |

`netlistsvg` pulls in `node` + `npm` transitively, which mason then
uses to install `svlangserver` (`@imc-trading/svlangserver`) on the
first `.sv` file open. The treesitter `systemverilog` parser also
installs on demand via the standard nvim-treesitter on-demand path —
no manual setup needed.

Treesitter parsers install on demand for any filetype that has one.

Heavy LSPs (HLS at ~2 GB, jdtls, metals) and language toolchains (vimtex's
preview viewer, Foundry's `forge` for Solidity, Dart SDK, Gleam, R, etc.)
are installed only when you actually open a file in that language. The
on-demand installer toasts every install start and finish, so you'll see
it coming. Anything marked **system** above is provided by the language's
own toolchain rather than mason.

---

## Repository layout

```text
ACH-NEOVIM/
├── install.sh
├── uninstall.sh
├── README.md
├── CLAUDE.md                         notes for AI assistants working on this repo
├── LICENSE
└── nvim/
    ├── init.lua                      entry point
    └── lua/
        ├── config/
        │   ├── icons.lua             central Nerd Font glyph table
        │   ├── lazy.lua              lazy.nvim bootstrap
        │   ├── options.lua           vim.opt defaults
        │   ├── keymaps.lua           non-plugin keymaps
        │   └── autocmds.lua          augroups (yank flash, big-file, prose mode, ...)
        └── plugins/
            ├── ai.lua                Claude Code (coder/claudecode.nvim)
            ├── coding.lua            blink.cmp, mini.pairs/surround/ai, lazydev, ts-comments
            ├── colorscheme.lua       tokyonight + deep ocean palette
            ├── editor.lua            which-key, fzf-lua, flash, todo-comments, trouble, grug-far
            ├── formatting.lua        conform.nvim + on-demand mason installer
            ├── git.lua               gitsigns, diffview, git-conflict, lazygit
            ├── lang.lua              render-markdown, markdown-preview, vimtex, venv-selector
            ├── linting.lua           nvim-lint + on-demand mason installer
            ├── lsp.lua               mason + native vim.lsp client + SchemaStore + neoconf + clangd_extensions
            ├── lualine.lua           statusline (custom ocean theme)
            ├── terminal.lua          toggleterm + language REPLs
            ├── treesitter.lua        nvim-treesitter (main branch, on-demand install) + textobjects + context
            ├── ui.lua                snacks, noice, bufferline, mini.icons, rainbow, colorizer
            └── util.lua              persistence sessions, vim-sleuth, scratch
```

---

## Keymap quick reference

Leader is `<Space>`. Holding leader pops up which-key with every binding
labelled and iconned. The headline groups:

| Prefix                  | Group                    |
|-------------------------|--------------------------|
| `<leader>a`             | AI / Claude              |
| `<leader>b`             | Buffer                   |
| `<leader>c`             | Code (LSP)               |
| `<leader>e`             | Explorer (root)          |
| `<leader>f`             | File / Find              |
| `<leader>g`             | Git                      |
| `<leader>gh`            | Git Hunks                |
| `<leader>gx`            | Git Conflicts            |
| `<leader>h`             | Harpoon Quick Menu       |
| `<leader>l`             | Lazy                     |
| `<leader>m`             | Mason                    |
| `<leader>o`             | Overseer (Tasks)         |
| `<leader>p`             | Yank History             |
| `<leader>q`             | Session                  |
| `<leader>r`             | Refactor                 |
| `<leader>s`             | Search                   |
| `<leader>sn`            | Noice messages           |
| `<leader>t`             | Terminal / REPLs         |
| `<leader>u`             | UI toggles               |
| `<leader>w`             | Window                   |
| `<leader>x`             | Diagnostics / Trouble    |
| `<leader>1`–`<leader>9` | Harpoon jump to file 1–9 |

A few standalone bindings worth knowing:

- `<C-/>` — toggle floating terminal
- `<C-a>` / `<C-x>` — increment / decrement (booleans, dates, hex, weekdays, ...)
- `<C-h/j/k/l>` — window navigation
- `<S-h>` / `<S-l>` — previous / next buffer (bufferline order)
- `<A-j>` / `<A-k>` — move line(s) down / up
- `s` / `S` — flash jump / treesitter jump
- `<C-Space>` — init / grow node selection (treesitter incremental select)
- `<BS>` — shrink node selection (in visual mode, after `<C-Space>`)
- `]f` / `[f` — next / previous function (treesitter textobjects)
- `]c` / `[c` — next / previous class
- `]a` / `[a` — next / previous parameter
- `af` / `if`, `ac` / `ic`, `aa` / `ia` — function / class / parameter textobjects
- `]d` / `[d` — next / previous diagnostic (any severity)
- `]e` / `[e` — next / previous error (severity-filtered)
- `]h` / `[h` — next / previous git hunk
- `]y` / `[y` — cycle yank history (after a paste)
- `gco` / `gcO` — add comment line below / above
- `gsa` / `gsd` / `gsr` — surround add / delete / replace
- `<leader>cn` — generate annotations (neogen)
- `<leader>cr` — rename symbol with live preview (inc-rename)
- `<leader>cR` — rename file with workspace import propagation (snacks)
- `<leader>cs` — toggle symbol outline sidebar
- `<leader>cc` — run LSP codelens at cursor (auto-refresh handled by Neovim)
- `<leader>co` — organize imports (LSP `source.organizeImports`)
- `<leader>cM` — add missing TS imports (`source.addMissingImports.ts`, ts_ls only)
- `<leader>cD` — fix all TS diagnostics (`source.fixAll.ts`, ts_ls only)
- `<leader>ch` — switch C/C++ source/header (clangd)
- `<leader>cp` — markdown preview in browser (markdown-preview.nvim)
- `<leader>cv` — pick a Python virtualenv (venv-selector)
- `<leader>um` — toggle inline markdown rendering (render-markdown)
- `<leader>ut` — toggle sticky scope header (treesitter-context)
- `<leader>ue` / `<leader>uE` — edgy toggle / select window
- `<leader>gi` / `<leader>gI` — list / search GitHub issues (octo)
- `<leader>gp` / `<leader>gP` — list / search GitHub PRs (octo)
- `<leader>gr` — list GitHub repos (octo)
- `<leader>gS` — full-text GitHub search (octo)
- `:StartupTime` — profile Neovim startup (vim-startuptime, runs 10 trials)
- `K` — LSP hover docs

---

## Customization

- **Add a plugin.** Create a new file in `nvim/lua/plugins/` returning a
  table of lazy.nvim specs. lazy auto-imports it. If the plugin has keymaps,
  follow the pattern in `terminal.lua`: define `keys = {}` on the plugin
  spec, then add a parallel `which-key.nvim` spec block in the same file
  with icons sourced from `config/icons.lua`.
- **Change the palette.** Edit `colorscheme.lua`. The `on_colors` callback
  defines the deep-ocean colors; `on_highlights` overrides every plugin's
  themed groups.
- **Add an LSP / formatter / linter.** Add an entry to the `servers` table
  in `lsp.lua` (or `formatter_to_mason` / `linter_to_mason` in
  `formatting.lua` / `linting.lua`). The on-demand installer will pick it
  up the next time you open a matching filetype. Do **not** add an
  `ensure_installed` list.
- **Tweak icons.** Every glyph lives in `nvim/lua/config/icons.lua`. Change
  it once and it propagates everywhere.

See [CLAUDE.md](CLAUDE.md) for the deeper architecture notes and the
project's hard rules.

---

## Uninstall

```bash
./uninstall.sh
```

Removes the symlink at `~/.config/nvim` and Neovim's data / state / cache
directories. Your repo clone stays intact. Re-run `install.sh` to set
everything back up.

---

## License

[MIT](LICENSE) © Anirban Chakraborty
