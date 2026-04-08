# ACH-NEOVIM — Notes for AI Assistants

This file is the guide an AI assistant should read first when working in this
repo. It is intentionally short. The code is the source of truth — these notes
exist only for things that are non-obvious, easy to get wrong, or that the
author cares about beyond what code can express.

---

## What this repo is

A personal Neovim configuration for macOS, structured around lazy.nvim. One
script (`install.sh`) bootstraps Homebrew, the latest stable Neovim, and the
Claude Code CLI. Plugins, LSP servers, treesitter parsers, formatters, and
linters all install on demand the first time they are needed — there is no
manual setup pass.

Targets the latest stable Neovim (currently 0.12.x). Tested only on macOS with
zsh and iTerm2 / MesloLGS NF.

---

## Hard rules

These are non-negotiable. Violating them is a regression.

1. **Author attribution.** The repo author is Anirban. **Never** add
   `Co-Authored-By: Claude`, `Generated with Claude Code`, or any other AI
   attribution to commits, PRs, files, headers, or docs. No exceptions, even
   for substantial AI-driven edits.

2. **Central icons.** Every Nerd Font glyph used anywhere in the config lives
   in `nvim/lua/config/icons.lua`. Plugin files reference them as
   `icons.<group>.<name>` (e.g. `icons.git.branch`, `icons.diagnostics.Error`).
   Hardcoding a glyph in a plugin file is a regression — add it to icons.lua
   first under the appropriate group, then reference it.

3. **No `ensure_installed`.** Treesitter parsers, mason packages (LSPs,
   formatters, linters), and any other "install up front" mechanism is
   forbidden. Everything must install on demand the first time the relevant
   filetype is opened. The reference implementations are in `lsp.lua`,
   `formatting.lua`, `linting.lua`, and `treesitter.lua` (a custom FileType
   autocmd that calls `require("nvim-treesitter").install({lang})` and
   re-fires FileType for waiting buffers — see the "nvim-treesitter `main`
   branch" section below).

4. **Every keymap needs a `desc`**, and every keymap that should appear in
   which-key needs an icon spec entry sourced from `icons.lua`. The pattern
   is: define the binding in the plugin's `keys = {}`, then add a parallel
   `which-key.nvim` spec block in the same file (see `editor.lua` and
   `terminal.lua` for the canonical layout). Group entries also get icons.

5. **No emojis.** Anywhere. Not in code, not in comments, not in docs, not in
   commit messages, not in notifier toasts. Use Nerd Font glyphs from
   `icons.lua` for visual markers.

6. **Don't add code I didn't ask for.** No speculative refactors, no
   "while I'm here" cleanups, no defensive error handling for cases that
   can't happen, no extra docstrings on functions you didn't touch.

---

## Repository layout

```text
ACH-NEOVIM/
├── install.sh              one-shot installer (Homebrew, Neovim, claude CLI)
├── uninstall.sh            removes ~/.config/nvim and Neovim state dirs
├── README.md               user-facing docs
├── CLAUDE.md               this file
├── LICENSE                 MIT
├── stylua.toml             stylua config (Spaces, indent_width=2, column=120, sort_requires)
├── .markdownlint.json      markdownlint rules (MD013/MD033 disabled)
└── nvim/
    ├── init.lua            entry point: options → keymaps → autocmds → lazy
    └── lua/
        ├── config/
        │   ├── icons.lua            central Nerd Font glyph table (M.ui, M.git, ...)
        │   ├── lazy.lua             bootstraps lazy.nvim, imports lua/plugins/*
        │   ├── options.lua          vim.opt defaults (leader, folds, splits, ...)
        │   ├── keymaps.lua          non-plugin keymaps (motions, windows, buffers)
        │   ├── autocmds.lua         augroups (yank flash, big-file, prose mode, ...)
        │   └── tailwind_colors.lua  Tailwind v3 palette data module (mini.hipatterns)
        └── plugins/
            ├── ai.lua          coder/claudecode.nvim integration
            ├── coding.lua      blink.cmp, mini.pairs/surround/ai, lazydev, ts-comments, ts-autotag
            ├── colorscheme.lua tokyonight + deep-ocean palette + every highlight override
            ├── editor.lua      which-key, fzf-lua, flash, todo-comments, trouble, grug-far
            ├── formatting.lua  conform.nvim + on-demand mason installer
            ├── git.lua         gitsigns, diffview, git-conflict, snacks lazygit/gitbrowse
            ├── lang.lua        render-markdown, markdown-preview, vimtex, venv-selector
            ├── linting.lua     nvim-lint + on-demand mason installer + debounced dispatcher
            ├── lsp.lua         mason + nvim-lspconfig + on-demand vim.lsp.enable + SchemaStore + clangd_extensions
            ├── lualine.lua     lualine with custom ocean theme
            ├── terminal.lua    toggleterm + named language REPLs
            ├── treesitter.lua  nvim-treesitter (main branch) + textobjects (main) + treesitter-context
            ├── ui.lua          snacks (dashboard/notifier/lazygit/indent/...), noice, bufferline, mini.icons, rainbow-delimiters, colorizer
            └── util.lua        persistence (sessions), vim-sleuth, snacks scratch/notifier keys
```

---

## Plugin manager / loading model

- **lazy.nvim** with auto-import from `lua/plugins/`. Each file returns a
  table of plugin specs.
- **`opts_extend = { "spec" }`** is used heavily so multiple files can each
  contribute to the same plugin's spec without overwriting. The most common
  case is which-key: every plugin file owns its own keymaps and registers a
  parallel which-key spec block in the same file rather than centralizing
  which-key bindings.
- **`optional = true`** is set on all the secondary which-key blocks so they
  don't pull which-key in if the user removed the primary spec.
- **Lazy-loading triggers.** Plugins use `event`, `cmd`, `keys`, or `ft` to
  defer loading until actually needed. `lazy = false` is reserved for
  colorscheme (priority 1000) and snacks (priority 1000, owns the dashboard
  on startup).

---

## On-demand install pattern

This is the project's signature pattern, used by `lsp.lua`, `formatting.lua`,
and `linting.lua`. It looks like:

1. Module-level table mapping `<tool name> -> <mason package>`. `nil` values
   mean the tool is system-provided (e.g. `swift_format` from Xcode, `perltidy`
   from cpan/brew) and mason should not try to install it.
2. A `FileType` autocmd that, when fired, looks up every tool registered for
   that filetype and calls `ensure_<tool>(name)`.
3. `ensure_<tool>` calls `mason-registry.refresh(cb)` (the registry is
   lazy-loaded — without `refresh` cold-start `has_package` lookups silently
   return false), then installs the package via `pkg:install():once("closed", ...)`
   with toast notifications via `vim.notify` for both start and finish.
4. **Cross-installer race guard.** Before calling `pkg:install()`, the
   installer checks `pkg:is_installing()` and if true, attaches a
   `:once("closed", on_done)` listener to the existing handle via
   `pkg:get_install_handle():if_present(...)` instead of calling install
   itself. This handles the case where the same mason package is targeted
   by two installers simultaneously (e.g. `ruff` is both an LSP server in
   `lsp.lua` and a formatter in `formatting.lua` — opening a Python file
   cold fires both autocmds, both reach `ensure_<tool>` for the same `ruff`
   package, and the second one would otherwise hit mason's internal
   `assert(not self:is_installing(), "Package is already installing.")`
   in `mason-core/package/init.lua:123`). The on_done callback fires
   exactly once per closer regardless of which installer kicked it off
   and re-checks `pkg:is_installed()` to decide success vs failure.
   See lsp.lua's installer for the canonical comment block; formatting.lua
   and linting.lua both reference it.
5. After install, the module's "enable" hook (e.g. `vim.lsp.enable(name)` for
   LSPs, or just re-running `lint.try_lint()` for linters) wires the tool up.
6. **Crucially**, after wiring up, the module re-fires `FileType` for any
   already-loaded buffers whose filetype matches, so the buffer that triggered
   the install actually gets the tool attached without needing a manual
   reload.

If you add a new LSP / formatter / linter, follow this pattern. Don't add an
`ensure_installed` table. The race guard in step 4 must be preserved on every
new installer site — it's the difference between a clean cold-start and a
toast spam of `Package is already installing.` errors the first time the
user opens a file in a new language.

Treesitter on the `main` branch uses a different installer because the new
install API (`require("nvim-treesitter").install({lang})`) returns an
`async.Task` instead of going through mason. See the
"nvim-treesitter `main` branch" section below for the details.

---

## Repo-root tooling configs

Two small config files at the repo root pin the formatter / linter behavior
so the codebase stays consistent regardless of which version of stylua /
markdownlint a contributor (or `:Format`) happens to invoke. Both are
borrowed verbatim from LazyVim's repo and tuned to ACH-NEOVIM's conventions.

**`stylua.toml`** — pins stylua to 2-space indentation, 120-column width,
and `sort_requires.enabled = true`. Without this file, stylua's default
config is **tabs, 4-wide** which silently reformats every saved Lua file
in the wrong direction relative to the project's predominant convention
(2-space spaces in 14 of 19 files at adoption time). The format-on-save
path in `formatting.lua` chains every Lua save through stylua, so
without this pin a single save would corrupt the file. The
`sort_requires` block reorders consecutive `local x = require("...")`
lines alphabetically, which is mostly cosmetic but makes diffs cleaner
when adding a new require.

Stylua's table-with-function-literal heuristic forces compact
`keys = { { "lhs", function() ... end, desc = "..." } }` entries to
**expand** to multi-line form on every reformat. There is no stylua
option to disable this; the only opt-out is a `-- stylua: ignore`
marker above the table (LazyVim sprinkles these throughout their core
plugin files). ACH-NEOVIM does NOT use these markers — the convention
is to write keymap tables in expanded form from the start. If you
import a snippet from LazyVim that uses compact form, expand it on
adoption rather than carrying the marker over.

**`.markdownlint.json`** — disables `MD013` (line length) and `MD033`
(no inline HTML). Without this, opening `CLAUDE.md` or `README.md`
would surface a barrage of warnings on every wrapped line. The file
uses the `.markdownlint.json` filename (not `.markdownlint-cli2.yaml`
like LazyVim) because the project uses BOTH `markdownlint` (the CLI,
via nvim-lint in `linting.lua`) and `markdownlint-cli2` (the conditional
formatter via conform in `formatting.lua`); the former only reads
`.markdownlint.{json,yaml,yml}`, the latter falls back to it. A single
`.markdownlint.json` covers both tools.

If you ever need to override either config for a specific file (e.g.,
allow inline HTML in a single doc), use the per-file syntax that each
tool supports (`<!-- markdownlint-disable MD033 -->` for markdown,
`-- stylua: ignore start/end` for Lua) rather than tweaking the
top-level config file.

---

## Custom colorscheme — deep ocean palette

`colorscheme.lua` runs tokyonight in `night` style with the following
overrides via `on_colors`:

```text
bg            #011628   deep navy editor background
bg_dark       #011423   floats / sidebars / popups / statusline
bg_highlight  #143652   cursorline, pmenu selection, visual highlight
bg_search     #0A64AC   search match background
bg_visual     #275378   visual selection background
fg            #CBE0F0   primary text
fg_dark       #B4D0E9   sidebar text
fg_gutter     #627E97   line numbers / dim text
border        #547998   window separators / float borders
```

`on_highlights` then overrides ~80+ highlight groups: floats, fzf-lua,
pmenu, search, telescope (fallback), lazy/mason UI, which-key (with custom
icon color classes mapped to `WhichKeyIconAzure/Blue/Cyan/Green/...`),
diagnostic virtual text (RGB-tinted backgrounds), gitsigns, lualine
statuslines, snacks dashboard / notifier / indent, noice, trouble, diffview
(every panel and status indicator), and git-conflict (RGB-tinted regions).

When you add a new plugin that has its own UI (floats, panels, headers),
add the matching highlight overrides here. The convention is: backgrounds
use `bg_dark`, accent backgrounds use `bg_search` or `bg_hl`, borders use
`border`, dim text uses `#627E97`.

---

## Important non-obvious things

### Claude Code integration (`plugins/ai.lua`)

- The plugin is `coder/claudecode.nvim`. It needs the **`claude` CLI on
  PATH**, which install.sh handles via the official native installer
  (`curl -fsSL https://claude.ai/install.sh | bash`).
- The native installer drops the binary at `~/.local/bin/claude` but does
  **not** modify PATH on its own. install.sh appends the export to
  `~/.zshrc` and prepends to the script's own PATH so the verification
  step works.
- `ai.lua` resolves the binary defensively: prefers `claude` on PATH, falls
  back to `~/.local/bin/claude` via `terminal_cmd` when PATH lookup fails.
  Without this fallback, opening Neovim from a terminal session that
  predates the PATH update gets exit 127 ("command not found").
- The snacks split is themed via `snacks_win_opts.wo.winhighlight` to remap
  `Normal` → `NormalFloat` so the panel's `bg_dark` separates visually
  from the editor's `bg`.

### `winhighlight` for snacks splits

When adding a new snacks-backed split panel that should look distinct from
the editor, set `snacks_win_opts.wo.winhighlight` to remap `Normal`,
`NormalNC`, `EndOfBuffer`, and `SignColumn` to `NormalFloat`. Without this
the split inherits the editor's `bg` and looks like one mashed pane.

### `vim.lsp` native client, not nvim-lspconfig's setup pattern

`lsp.lua` uses the Neovim 0.11+ native flow: `vim.lsp.config(name, ...)` to
register per-server overrides, then `vim.lsp.enable(name)` to start the
server (and only after the mason package is confirmed installed).
`nvim-lspconfig` is included only because it ships default `lsp/<name>.lua`
config files on the runtimepath that the native flow merges over.

### blink.cmp wires capabilities into every LSP

`coding.lua` lists `blink.cmp` as a dependency of `lsp.lua` so blink loads
first, and `lsp.lua` calls `blink.get_lsp_capabilities()` and merges the
result into `vim.lsp.config("*", { capabilities = ... })`. This way every
LSP server, present and future, learns about snippet/resolve support
without per-server boilerplate.

### Treesitter folds via FileType autocmd

`autocmds.lua` has a `TreesitterFolds` group that swaps the buffer-local
`foldmethod` to `expr` + `vim.treesitter.foldexpr()` whenever a parser is
available for the current filetype. Files without a parser fall back to
the global `foldmethod = "indent"` set in `options.lua`.

### Big files downgrade

`autocmds.lua`'s `BigFile` group disables syntax, treesitter, undofile,
and swapfile for buffers > 1.5 MiB. This is a hard limit; tune it there
if files near that boundary become a problem.

### Bufferline owns buffer cycling

`<S-h>` / `<S-l>` and `[b` / `]b` are owned by bufferline.nvim in `ui.lua`,
not by `keymaps.lua`. They cycle in bufferline's display order (which can
be reordered via `[B` / `]B`) rather than the raw buffer list. Don't add
parallel definitions.

### Snacks owns most `<leader>u*` toggles

Line numbers, relativenumber, wrap, spell, diagnostics, color column, and
inlay hints are all bound via `Snacks.toggle.*():map(...)` in `ui.lua`'s
config function. Only `<leader>uf` (Format on Save) lives in `keymaps.lua`
because conform's `disable_autoformat` flag has no snacks built-in.

### mini.icons replaces nvim-web-devicons via package.preload

`ui.lua` registers a `package.preload["nvim-web-devicons"]` shim so any
plugin that does `require("nvim-web-devicons")` transparently gets
mini.icons' compat layer. lualine, fzf-lua, bufferline, etc. all keep
working with no nvim-web-devicons install. Don't add nvim-web-devicons
back as a dependency.

The `file = { ... }` opts table also carries a small block of
JavaScript / TypeScript project file glyphs (`tsconfig.json`,
`package.json`, `.eslintrc.js`, `.prettierrc`, `yarn.lock`,
`.node-version`, `.yarnrc.yml`) borrowed verbatim from LazyVim's
`extras/lang/typescript/init.lua`. Without these, the file picker /
lualine / bufferline render the generic JSON icon for every config
file in a TS project, which is technically correct but visually
identical to every other JSON file in the tree. The overrides give
each one a recognizable per-tool glyph so they stand out in a crowded
explorer. Add the TypeScript ones near the bottom of the same `file`
table whenever a new tool emerges.

### `M.kinds` mirrors LazyVim verbatim — prefer MDI over codicons

Every entry in `M.kinds` (the LSP completion-kind icon table) lives in
`config/icons.lua` and mirrors LazyVim's `icons.kinds` table verbatim:
Material Design Icons (`nf-md-*`, U+F0xxx range) for Snippet, Variable,
Boolean, Constant, Number, Struct, Function, Method, Namespace, Codeium,
TabNine; codicons (`nf-cod-*`, U+EAxx–U+EBFF range) for the rest.

This isn't aesthetic — it's a workaround for a real macOS font issue:
codicons in the U+EB60+ range (especially `nf-cod-symbol_snippet` U+EB66)
can render as `.notdef` tofu in iTerm2 even when `fontTools` confirms the
codepoint exists in the active `.ttf`. macOS's font daemon serves stale
cmap data. The fix at the data layer is `sudo atsutil databases -remove
&& killall -HUP fontd` plus a Cmd-Q iTerm2 restart, but the defensive fix
at the code layer is to use MDI codepoints for the kinds that are most
visible. **If you add a new entry to `M.kinds`, prefer MDI.**

Every value in `M.kinds` ends with a trailing space (e.g. `"󱄽 "`). This
is intentional: blink.cmp's `nerd_font_variant = "mono"` mode does not
add an icon-label gap, so the spacing has to live in the icon string
itself. Consumers that want a tight glyph (e.g., `editor.lua`'s parameter
which-key entries) can `vim.trim()` the value.

### blink.cmp v1.10.2 + Neovim 0.12.1 incompat

`coding.lua` disables `treesitter_highlighting` on both
`completion.documentation` and `signature.window`, and comments out
`menu.draw.treesitter = { "lsp" }`. All three changes are workarounds for
a v1.10.2 bug where `vim.treesitter.get_range` is called from
`blink.cmp/lib/window/docs.lua:108` and errors with "attempt to call
method 'range' (a nil value)" on Neovim 0.12.1. The fix is on `main` but
not in any tagged release as of 2026-04-07. When v1.10.3 ships, revert
all three (they're all comment-marked with `v1.10.2`). Tracked in detail
in the `project_pending_blink_cmp_1_10_3` memory.

### Plugin-owned LSP keymaps (`<leader>cr`, `<leader>cs`)

`<leader>cr` (rename) and `<leader>cs` (symbol view) look like vanilla
LSP buf-local keymaps but they're actually owned by **plugins**, not the
`LspAttach` handler in `lsp.lua`. If you grep for them in the `LspAttach`
callback you won't find them — they're deliberately removed.

- **`<leader>cr`** is owned by `inc-rename.nvim` (declared in `lsp.lua`
  outside the LspAttach block). It's an `expr` keymap that drops you
  into the cmdline with `:IncRename <cword>` pre-filled, and every
  keystroke previews the rename across every reference visibly. The
  binding requires `cmd = "IncRename"` lazy-loading which fires the
  first time the expr returns the command string. There's also a
  `presets.inc_rename = true` opt extension on noice.nvim in `lsp.lua`
  so noice's cmdline popup formats the live preview consistently.

- **`<leader>cs`** is owned by `outline.nvim` (declared in `editor.lua`).
  Replaced the old `vim.lsp.buf.document_symbol` binding which dumped to
  the quickfix list — outline's persistent sidebar tree is much better
  UX and the icon set is sourced from `M.kinds`. For ad-hoc fuzzy symbol
  jumping you still have `:FzfLua lsp_document_symbols` (no keybind by
  design — the outline sidebar covers the persistent case and fzf-lua
  covers the ad-hoc case).

If you re-add either of these into `LspAttach`, you'll create a silent
duplicate-keymap conflict where lazy.nvim's plugin keys win on first
press but the LspAttach version overrides on subsequent buffer reads.
Don't.

### `<leader>r` is refactor, not run/build

CLAUDE.md and earlier README versions reserved `<leader>r` as a "Run /
Build" placeholder, but the keymaps were never implemented. The prefix
is now owned by `refactoring.nvim` in `coding.lua` (`rs` pick, `rE`
extract function, `rv` extract variable, `ri` inline, etc.). Build /
run / test now live under **`<leader>o`** via `overseer.nvim` in
`util.lua` (`oo` Run, `ow` Task List, `ot` Action, `oq` Quick Action,
`oi` Info). Don't conflate the two prefixes when adding new keymaps.

### LSP codelens, organize imports, rename file, vue inlay-hints exclude

Four small patterns borrowed from LazyVim's main `lua/lazyvim/plugins/lsp/init.lua`
that fill specific gaps in the LspAttach block:

**`<leader>cc` (Run Codelens)** — gated on the client supporting
`textDocument/codeLens`. Bound in normal + visual mode. The buffer
also gets `vim.lsp.codelens.enable(true, { bufnr = bufnr })` called
once on attach -- this is the **0.12+ stateful API** that registers
the buffer with Neovim's codelens decoration provider, which then
manages refresh/re-fetch internally. There is **no** manual refresh
autocmd or `<leader>cC` binding -- they're not needed because the
decoration provider handles it.

The old API (`vim.lsp.codelens.refresh({ bufnr = N })` called from
`BufEnter` / `CursorHold` / `InsertLeave` autocmds) is **deprecated**
in 0.12 and emits a warning if called -- see
`vim/lsp/codelens.lua`'s `M.refresh` body, which now just yells about
the deprecation and forwards to `M.enable`. If a future change to
this file accidentally re-introduces the manual refresh pattern, the
deprecation toast will be the canary.

This is what makes gopls's full codelens set (`gc_details`,
`generate`, `regenerate_cgo`, `run_govulncheck`, `test`, `tidy`,
`upgrade_dependency`, `vendor`) actually invokable -- before this,
gopls was advertising the lenses but there was no keymap to fire them.

**`<leader>co` (Organize Imports)** — directly fires the
`source.organizeImports` LSP code action via `vim.lsp.buf.code_action`
with `apply = true`. Wrapped in `pcall` so a buffer where the LSP
doesn't expose this action silently no-ops instead of erroring. For TS
this removes unused imports + sorts them; for Python (via pyright) it
sorts imports; etc. Faster path than going through the `<leader>ca`
menu for an operation that's done dozens of times per session.

**`<leader>cR` (Rename File)** — declared as a **top-level** snacks
keys spec, NOT in LspAttach. This is intentional: `Snacks.rename
.rename_file()` works on any buffer regardless of LSP attachment. When
an LSP IS attached, the rename also fires `workspace/willRenameFiles`
and `workspace/didRenameFiles` so the LSP can update imports across
the workspace before/after the file moves. For TS this means renaming
`Foo.tsx` -> `Bar.tsx` automatically updates every
`import Foo from "./Foo"` in the project.

The snacks.rename module is a utility module (lives at
`snacks/rename.lua`) and does not need explicit `enabled = true` in
ui.lua's snacks opts -- it's auto-loaded when accessed via
`Snacks.rename`.

**Vue inlay hints exclude** — the existing `inlay_hint.enable(true,
{bufnr})` call in LspAttach now also checks `vim.bo[bufnr].filetype ~=
"vue"`. Vue's inlay hints (from `vue_ls` / Volar, declared in lsp.lua's
servers table) are notoriously noisy -- they show parameter names on
every prop binding and slow down rendering on large templates. LazyVim
has the same exclude in its main lsp/init.lua (`exclude = { "vue" }`
on the `inlay_hints` opts table). One-line fix.

### ts_ls TypeScript settings + `<leader>cM` / `<leader>cD` keymaps

The `ts_ls` server entry in `lsp.lua` carries a duplicated
`settings.typescript` and `settings.javascript` block borrowed from
LazyVim's `extras/lang/typescript/vtsls.lua`. The same `typescript.*` keys work
for both `vtsls` and `ts_ls` because both servers wrap the same
upstream tsserver and forward these keys verbatim. The four enabled
features:

- **`inlayHints`**: parameter names (`literals` only — full mode is
  too noisy on call sites that already pass named props), parameter
  types, return types, enum member values, property declaration
  types. `variableTypes` is OFF because it duplicates what hover
  already shows on the LHS identifier.
- **`updateImportsOnFileMove = "always"`**: when a TS file is renamed
  via `<leader>cR` (Snacks.rename.rename_file) the LSP rewrites every
  import path that pointed to the old name. Without this the LSP
  prompts on every rename which is a papercut.
- **`suggest.completeFunctionCalls`**: when accepting a function from
  completion, ts_ls inserts the full signature with parameter
  placeholders (mirrors blink.cmp's auto_brackets but with real
  parameter names from the type signature).
- The same settings table is duplicated for `javascript` so JS files
  get the same hints + behavior; ts_ls reads both keys.

Two **buffer-local keymaps** are bound inside `LspAttach` gated on
`client.name == "ts_ls"`:

- **`<leader>cM` (Add Missing Imports TS)**: fires the
  `source.addMissingImports.ts` code action with `apply = true`. Same
  pattern as `<leader>co` (Organize Imports) but with the TS-specific
  command name. Wrapped in `pcall` so a buffer where the action isn't
  available silently no-ops.
- **`<leader>cD` (Fix All Diagnostics TS)**: fires the
  `source.fixAll.ts` code action. The TS equivalent of `tsc --noEmit`
  with auto-fix. Faster than going through the `<leader>ca` menu when
  the same operation runs dozens of times per session.

The which-key icons for both live in the global which-key block in
`lsp.lua` (alongside `<leader>cR`/`<leader>cc`/etc.) so the icons
register globally — which-key handles the filetype filtering at
render time by checking whether the buffer-local keymap is bound.

### Octo (GitHub) lives in `git.lua`, picker is hardcoded to fzf-lua

`pwntester/octo.nvim` is declared in `git.lua` next to the other git
plugins (gitsigns, diffview, git-conflict, lazygit, gitbrowse). Borrowed
from LazyVim's `extras/util/octo.lua` with three deviations:

1. **Picker hardcoded to `"fzf-lua"`** instead of LazyVim's runtime
   `LazyVim.has_extra("editor.fzf")` check. We know which picker we
   ship — no need for the auto-detect block.
2. **No snacks-disabling block.** LazyVim's spec disables its own
   `<leader>gi/gI/gp/gP` snacks bindings before octo binds them, but
   ACH-NEOVIM doesn't bind those keys to snacks in the first place
   (the only `<leader>g*` snacks bindings here are `gg`/`gG` for
   lazygit and `gB` for gitbrowse, none of which collide).
3. **Single spec entry** instead of LazyVim's two-spec layered setup.
   We collapse the picker config + the markdown treesitter register +
   the ExitPre autocmd into one `config = function()` body.

The **`vim.treesitter.language.register("markdown", "octo")` call** is
critical: octo's PR/issue body buffers use the `octo` filetype (not
`markdown`), and treesitter doesn't have an `octo` parser. Registering
markdown as the parser for octo buffers makes them render with proper
markdown syntax highlighting (bold/italic/code fences/etc.).

The **`ExitPre` autocmd** sets `buftype = ""` on every open octo buffer
right before nvim quits so persistence.nvim sessions can save them as
regular file buffers. Without this, octo's `acwrite` buftype gets
serialized into the session file and the next session restore tries to
re-fetch the URL — which fails if the user is offline or unauthenticated.

**Auth setup is out of scope.** Octo authenticates via the `gh` CLI;
the user must run `gh auth login` once before first use. `install.sh`
does NOT set this up automatically because it's an interactive flow.

The keymap surface adds:

- Six top-level entry points under `<leader>g`: `gi`/`gI` (issues),
  `gp`/`gP` (PRs), `gr` (repos), `gS` (search). Bound globally.
- Twelve `<localleader>*` group labels filtered with `ft = "octo"` so
  they only appear in which-key when the cursor is inside an octo
  buffer. They're labels for octo's own internal mappings (assignee,
  comment, label, react, review, etc.) — the actions themselves are
  bound by octo.nvim's mappings module, not by us.
- Two `@` and `#` insert-mode remaps that fire `<C-x><C-o>` (omni
  completion) so typing `@` or `#` in an octo buffer triggers the
  user/issue/PR completion popup. Also filtered with `ft = "octo"`.

### mini.hipatterns is Tailwind-only; colorizer keeps hex/rgb/hsl

`nvim-mini/mini.hipatterns` lives in `ui.lua` right after the
nvim-colorizer block. Both plugins coexist with **zero overlap**:

- **nvim-colorizer** handles `#RRGGBB`, `#RRGGBBAA`, `rgb()`, `hsl()`,
  and CSS named colors. This is the user's existing setup and stays
  unchanged.
- **mini.hipatterns** is configured with **only the `tailwind`
  highlighter** — the LazyVim default `hex_color` and `shorthand`
  highlighters are deliberately omitted to avoid duplicating
  colorizer's job. mini.hipatterns is here purely for Tailwind class
  highlighting (`bg-blue-500`, `text-emerald-300`, etc.).

The **Tailwind palette data** lives in
`nvim/lua/config/tailwind_colors.lua` as a pure data module returning
a `{ palette_name = { [shade] = "RRGGBB" } }` table. Borrowed verbatim
from LazyVim's inlined `M.colors` table (~270 lines). Split out into
its own file because static color data has no business living in a
plugin spec file — it's reusable, never edited, and bloats `ui.lua`
unnecessarily if inlined.

The **highlight cache** (`tailwind_hl`) is reset on `ColorScheme`
events via the `ACHHipatternsTailwindReset` augroup so switching
colorschemes doesn't leave stale highlight groups around. Each cache
entry is keyed by the highlight group name
(`MiniHipatternsTailwindblue500`, etc.) and gets its bg + fg pair
recomputed against the new colorscheme.

The **fg shade picker** is the contrast trick from LazyVim:

- shade `500` → fg uses shade `950` (dark fg on mid bg)
- shade `<500` → fg uses shade `900` (dark fg on light bg)
- shade `>500` → fg uses shade `100` (light fg on dark bg)

This guarantees the class name text stays readable on its colored
background regardless of which Tailwind shade was used.

If you want to also highlight `text-` and other prefixes besides `bg-`,
the pattern is broad enough to catch any `prefix-color-shade` form
(`%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]`). The `tailwind_ft`
allowlist gates which filetypes the highlighter activates in — extend
it if you adopt a new web framework filetype.

**vim-startuptime** also lives in `util.lua` and is unremarkable: lazy
on `:StartupTime`, `tries = 10` for stable averages. No keymaps, no
which-key entries — it's a one-shot diagnostic command.

### edgy.nvim window manager + bufferline offset patch

`folke/edgy.nvim` (declared in `ui.lua` right after the bufferline spec)
auto-organizes sidebar windows into edge groups: bottom for terminals,
trouble, qf, help, noice; right for outline and grug-far. The trouble
and snacks_terminal entries are added to all four edges via a loop with
a `vim.w[win].trouble.position` / `snacks_win.position` filter so each
window lands wherever it was opened. The neo-tree, telescope, and
neotest blocks from LazyVim's `extras/ui/edgy.lua` are deliberately
omitted -- the user uses snacks explorer, fzf-lua, and has deferred
neotest.

The `keys = {}` table inside edgy's opts sets buffer-local
`<C-arrow>` resize bindings that operate on edgy's layout groups
(`win:resize("width", N)`) instead of the single window. The user's
global `<C-arrow>` resize bindings in `keymaps.lua` still apply
in non-edgy windows -- the edgy versions only fire when the cursor is
inside an edgy pane.

The companion **bufferline offset patch** (a separate spec entry for
`akinsho/bufferline.nvim` with `optional = true` so it doesn't pull in
bufferline if removed) monkey-patches `bufferline.offset.Offset.get`
to render a "Sidebar" placeholder + width when an edgy left/right pane
is open but bufferline's own `offsets[]` table doesn't have a matching
filetype. Without this patch, opening an edgy explorer or outline pane
would let the bufferline tabs spill over the sidebar area instead of
being offset cleanly.

The patch is wrapped in an `Offset.edgy` re-entry guard so it only
applies once per nvim session. The `opts = function() ... end`
intentionally returns nothing -- it's a side-effect-only patch, and
lazy.nvim's plugin module preserves the existing accumulated opts when
an opts function returns nil. **Do not change this to `function(_, opts)
return opts end`** -- it would be a no-op but adds confusion.

The LazyVim original uses a nested `and/or` chain to compute the
sidebar text and width. Our copy restructures it as an explicit
if/elseif chain so lua_ls can infer the result type cleanly (`string`
instead of `string | false`). Behavior is identical.

### nvim-treesitter-context lives in `treesitter.lua`, not `ui.lua`

`nvim-treesitter/nvim-treesitter-context` (sticky function/class header
when scrolling past a definition) is declared as a sibling spec in
`treesitter.lua` rather than `ui.lua`. It's a treesitter sub-plugin
and conceptually belongs next to its parent. `mode = "cursor"` makes
the pinned context follow the cursor (not the topmost visible line),
which works better with cursor-based navigation (`}`/`{`, `[c`/`]c`).
`max_lines = 3` caps the pinned area so deeply-nested scopes don't
take over the screen.

Toggleable via `<leader>ut` through the snacks toggle pattern. The
toggle hook reaches into `tsc.enabled()` / `tsc.enable()` /
`tsc.disable()` directly because treesitter-context doesn't expose a
`Snacks.toggle.option`-compatible getter/setter shape -- same approach
used for render-markdown.nvim's snacks toggle in `lang.lua`.

### nvim-treesitter `main` branch (and what's gone with it)

`treesitter.lua` runs nvim-treesitter on the **`main` branch**, NOT
master. Main is a complete, intentionally incompatible rewrite of the
plugin that delegates every runtime feature to Neovim 0.12+'s built-in
treesitter API. The plugin's job is now limited to:

1. Maintaining the parser table (name → URL + revision) shipped in
   `lua/nvim-treesitter/parsers.lua`.
2. Installing / updating / uninstalling parsers via an async API
   (`require("nvim-treesitter").install({...})`).
3. Providing the indent expression
   (`require("nvim-treesitter").indentexpr()`).
4. Shipping bundled queries (highlights/injections/folds/locals) under
   `queries/<lang>/` on the runtimepath.

Highlighting, folds, incremental selection, and textobjects are NOT
enabled by the plugin. They're wired in three different places:

- **Highlighting + folds**: `autocmds.lua`'s `TreesitterFolds` group
  (already there, was added long before the migration). It calls
  `vim.treesitter.start(args.buf)` on every FileType event and sets
  `foldmethod = "expr"` + `foldexpr = vim.treesitter.foldexpr()` if
  the parser is available. Parser-aware: silently no-ops if no parser.

- **Indentation**: per-buffer in `treesitter.lua`'s install autocmd by
  setting `vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
  Marked **experimental** in upstream README — if a parser ships
  buggy indent rules, the per-filetype escape is to clear `indentexpr`
  in an `ftplugin/<lang>.lua` or via a FileType autocmd.

- **Incremental selection**: a small node-stack helper at the bottom
  of `treesitter.lua`'s config function, bound to `<C-Space>` (init in
  normal mode, grow in visual mode) and `<BS>` (shrink in visual mode).
  Mirrors the master branch's `init_selection` / `node_decremental` UX
  exactly. State is per-buffer, cleared on visual→normal mode change
  via a `ModeChanged` autocmd so the next press starts fresh.

The on-demand install autocmd pattern looks like the LSP installer in
`lsp.lua`: a FileType autocmd consults a cached installed-parsers set,
fires `require("nvim-treesitter").install({lang})` for any missing
parser, and on completion enables treesitter for every loaded buffer
that matches. Cache is refreshed after each successful install. The
install function returns an `async.Task` whose `:await(callback)`
method takes a plain callback and **does not** require an async
coroutine context — that's the entry point we use; **do not** wrap it
in `task:wait()` because that blocks the editor.

The textobjects plugin is also on its own `main` branch with a brand-
new API: instead of declaring `textobjects.select.keymaps` in opts you
call `require("nvim-treesitter-textobjects.select").select_textobject(
"@function.outer", "textobjects")` from a keymap callback. The
"textobjects" second argument is the query group name (file:
`queries/<lang>/textobjects.scm`). Same shape for `move.goto_*` and
`swap.swap_*`. The init hook sets `vim.g.no_plugin_maps = true` per
upstream README to disable Neovim's built-in ftplugin keymaps that
would otherwise collide with custom textobjects.

**IMPORTANT**: nvim-treesitter main does NOT support lazy-loading per
its README. Both spec entries are `lazy = false`. Startup cost is
small because the rewrite is much leaner than master. Do NOT add
`event = ...` or `cmd = ...` triggers to either spec.

**Default install_dir**: `vim.fn.stdpath('data') .. '/site'`
(`~/.local/share/nvim/site/`), which is already on Neovim's runtime
path by default. Parsers go to `site/parser/<lang>.so`, queries to
`site/queries/<lang>/`. Because the install path is different from
master's `lazy/nvim-treesitter/parser/`, the migration intentionally
re-installs every parser the user touches. Cold-start cost is ~3-5s
per missing parser, exactly once per filetype, identical to master's
`auto_install` UX.

**The ~150-line directive override block that lived here on master is
GONE**. It was a workaround for nvim-treesitter master shipping query
files written for the pre-0.12 single-node `match[capture]` contract;
main's queries are written for the 0.12+ array contract directly, so
there's nothing to patch. If you ever see a `attempt to call a method
'range' (a nil value)` toast again, it means a query file regressed
upstream — file an issue, do NOT re-add the override.

If you need to roll back to master for any reason, change `branch =
"main"` to `branch = "master"` on both spec entries, set `lazy = true`
plus the old `event = { "BufReadPost", "BufNewFile" }` triggers, and
re-add the directive override block (the old commit history shows the
exact code). But there is no good reason to do this in 2026 — main
is the active development line and master only receives security
fixes.

### neoconf.nvim must run before `vim.lsp.config()` calls

`folke/neoconf.nvim` is declared as a `lazy = true` dependency of
nvim-lspconfig in `lsp.lua`. It auto-merges per-project LSP overrides
from `.neoconf.json` and `.vscode/settings.json` (it translates VS Code
keys like `eslint.workingDirectories`, `typescript.tsdk`,
`json.schemas`, `yaml.schemas`, etc. into the equivalent LSP server
settings) into the LSP config when each server attaches. This is
useful for monorepos and for cloning JS/TS projects that ship a
`.vscode/settings.json` with their own LSP customizations.

**Critical ordering:** `require("neoconf").setup({})` MUST run BEFORE
any `vim.lsp.config()` calls. neoconf installs its hooks on the LSP
attach chain at `setup()` time; if a `vim.lsp.config()` call lands
first, that server's overrides are registered before neoconf can wire
itself in, and the per-project overrides silently lose the race.
That's why the `pcall(function() require("neoconf").setup({}) end)` in
`lsp.lua` lives at the top of the config function, right after the
`vim.filetype.add` block and BEFORE the `vim.lsp.config("*", ...)`
default block. The `pcall` is for graceful degradation if neoconf
isn't installed yet.

The plugin still ships a `cmd = "Neoconf"` user command for inspecting
the merged config — `:Neoconf` opens a picker showing every settings
file neoconf found and the resulting merged values.

### ESLint is an LSP, not a linter

ESLint runs as the **`eslint` LSP** (`vscode-eslint-language-server` /
mason package `eslint-lsp`), declared in `lsp.lua`'s servers table. It
is **not** registered as an `nvim-lint` linter — `eslint_d` was removed
from `linting.lua` when the LSP took over. Running both would
double-count every issue and waste cycles.

The LSP setup carries two non-default settings borrowed from LazyVim's
`extras/linting/eslint.lua`:

- **`workingDirectories = { mode = "auto" }`** — lets the eslint LSP
  find the nearest `.eslintrc` in subfolders instead of always looking
  at the project root. Critical for monorepos.
- **`format = true`** — enables eslint's `source.fixAll.eslint` code
  action, which is the LSP equivalent of `eslint --fix`.

**Auto-fix on save is wired through conform's `format_on_save`
callback** (in `formatting.lua`), NOT through a separate
`BufWritePre` autocmd. The callback first checks for an attached
eslint client on the buffer and runs `vim.lsp.buf.code_action` with
`only = { "source.fixAll.eslint" }, apply = true` BEFORE returning the
prettier formatter list. The order matters: eslint fixes first
(unused vars, missing semicolons, broken patterns), then prettier
reformats so prettier has the final word on cosmetics. This is the
canonical "eslint --fix && prettier" pipeline. The eslint code action
call is wrapped in `pcall` so a failed fix-all (syntax error, eslint
not yet ready) never blocks the prettier save path.

Disabling format-on-save via `g:disable_autoformat` /
`b:disable_autoformat` ALSO disables the eslint fix-all step, since
both run inside the same `format_on_save` callback. There's no
separate gate for the eslint half.

If you ever want to invoke fix-all manually outside of save, the LSP
also exposes the standard code action menu via `<leader>ca` -- pick
"Fix all eslint problems".

### `vim.filetype.add` block in `lsp.lua`

`lsp.lua`'s config function opens with a `vim.filetype.add({...})` block
that registers extensions Neovim doesn't ship built-in mappings for, or
where the LSP / treesitter parser expects a specific filetype name. This
includes `.astro`, `.gleam`, `.nu`, `.prisma`, `.rego`, `.sol`, `.svelte`,
`.thrift`, `.typ`, `.twig`, `.tf`/`.tfvars`/`.hcl`, `.tpl`, plus pattern-
based helm template detection (`templates/*.tpl`, `helmfile*.yaml`) and
Bazel filename mappings.

This must run **before** any of the on-demand server entries register
their FileType autocmds — that's why it lives at the top of the config
function rather than being a late `init` block. Adding a redundant
mapping here is harmless: `ft.add` only sets the value if no existing
rule matches first.

### SchemaStore.nvim is loaded lazily via `before_init`

`b0o/SchemaStore.nvim` is declared as a `lazy = true` dependency of
`nvim-lspconfig` in `lsp.lua`. The actual `require("schemastore")` call
happens inside the **`before_init`** hook of `jsonls` and `yamlls` —
not at top level. This keeps SchemaStore out of the startup path
entirely; it loads only when the first json/yaml file actually opens.
Both hooks are wrapped in `pcall` so a missing schemastore module
silently degrades to vanilla jsonls/yamlls instead of crashing.

`yamlls` additionally injects `foldingRange.lineFoldingOnly = true` into
its `capabilities` because yamlls itself doesn't advertise that
capability and you'd otherwise get no folding at all in YAML buffers.

### gopls semanticTokensProvider workaround (`golang/go#54531`)

`gopls`'s server entry has an `on_attach` callback that re-injects
`semanticTokensProvider` from the client capabilities if the server
forgets to advertise it. This is a known gopls regression: even with
`semanticTokens = true` in settings, the server sometimes drops the
capability on initial registration, breaking treesitter+semantic-token
highlighting in the same buffer. The workaround copies the token types
and modifiers from `client.config.capabilities.textDocument.semanticTokens`
into a synthetic `semanticTokensProvider` table on the client. Borrowed
from LazyVim's `extras/lang/go.lua`.

### Ruff hover disabled in `LspAttach`

The `LspAttach` callback in `lsp.lua` checks `client.name == "ruff"` and
sets `client.server_capabilities.hoverProvider = false`. This is because
ruff and pyright both attach to Python buffers; both serve
`textDocument/hover`; ruff's hover payload is one-line and inferior to
pyright's. Without this disable, ruff sometimes wins the hover race and
the user sees the wrong (worse) docs. Pyright still owns hover/definition/
references; ruff still owns diagnostics and the formatter (via conform).

### Conditional markdown formatters in `formatting.lua`

`markdown-toc` and `markdownlint-cli2` are listed in `formatters_by_ft.markdown`
but each has a `condition` callback in the `formatters` block that gates
when they actually run:

- **`markdown-toc`** only fires if the buffer contains a `<!-- toc -->`
  marker (scanned via `nvim_buf_get_lines`). Without this gate, conform
  would generate a TOC in every markdown file on save, including blog
  posts and READMEs that don't want one.
- **`markdownlint-cli2`** only fires if there are existing markdownlint
  diagnostics on the buffer (`vim.diagnostic.get(ctx.buf)` filtered by
  `source == "markdownlint"`). So nvim-lint surfaces the lint, the user
  opts into auto-fixing by saving, and clean files pay zero cost.

Same `condition` pattern as the prettier `prettier_has_parser` gate
above. Both are borrowed from LazyVim's `extras/lang/markdown.lua`.

### `clangd_extensions.nvim` is ft-loaded, not LSP-attached

`p00f/clangd_extensions.nvim` lives as its own plugin spec in `lsp.lua`
with `ft = { "c", "cpp", "objc", "objcpp" }`. It does NOT load via
`LspAttach` and does NOT depend on clangd being installed first.
That's intentional: the extensions plugin provides AST viewer + AST
inlay hints + memory usage display via its own user commands, all of
which work regardless of whether clangd has attached yet.

The `<leader>ch` (Switch Source/Header) keymap is owned by this plugin's
`keys = {}`, but the **icon** for it lives in the global which-key spec
block in `lsp.lua` (alongside `<leader>cf`/`<leader>cr`/etc.) so the
which-key tree shows the icon even before clangd_extensions has loaded.

### `lang.lua` is for language plugins that aren't LSP/formatter/linter

Four plugins live here, each lazy-loaded by filetype so they cost
nothing at startup:

- **`render-markdown.nvim`** — inline markdown rendering. Snacks toggle
  on `<leader>um`. The toggle hook reaches into `render-markdown.state`
  and calls `enable()`/`disable()` rather than using the built-in
  `Snacks.toggle` getter pattern, because render-markdown's setter
  doesn't expose the simple "give me a get/set callback" shape.
- **`markdown-preview.nvim`** — browser preview. Heavy: ships a node/yarn
  build step the first time it loads. Bound to `<leader>cp` (markdown
  ft only, so it doesn't pollute the global which-key tree).
- **`vimtex`** — full LaTeX editing environment. **Cannot be lazy-loaded**
  (`lazy = false`) because inverse search needs vimtex's servername
  registered at startup. The `init` function disables vimtex's `K`
  mapping so it doesn't collide with our LSP hover binding (texlab
  handles hover). Localleader `\l` is the vimtex group prefix.
- **`venv-selector.nvim`** (regexp branch) — Python virtualenv picker.
  `<leader>cv`, ft = python only. Pulls in `nvim-dap` and `nvim-dap-python`
  as dependencies — those are listed only as deps, not configured
  separately, so DAP itself stays unconfigured (consistent with the
  `project_deferred_dap` plan). When DAP eventually gets adopted, the
  binaries are already cloned.

### outline.nvim trims trailing spaces from `M.kinds`

`editor.lua`'s outline spec sources its per-kind icons from
`icons.kinds` but calls `:gsub("%s+$", "")` on every value before
passing it to outline. This is required because `M.kinds` entries all
end with a trailing space (intentional, see the `M.kinds` section
above) and outline renders the glyph followed by its own spacing — the
extra space would create a visual double-gap in the sidebar tree. Any
new outline-style consumer of `M.kinds` should do the same trim.

---

## Git workflow notes

- `main` is the only long-lived branch.
- Commits follow short imperative subject + optional body. See `git log` for
  the project's tone.
- Never use `--amend` on commits that are already pushed.
- Never use `--no-verify` to skip hooks.
- Never include AI attribution in commit messages or PR descriptions.

---

## When in doubt

- **Read the actual file** rather than trusting this document. If something
  here disagrees with the code, the code wins. Update this file in the same
  commit.
- **Check `editor.lua` and `terminal.lua`** for the canonical patterns —
  plugin spec layout, which-key spec entries, lazy-loading triggers, icon
  references. Mirror them.
- **Don't add `ensure_installed`.** Don't hardcode glyphs. Don't add Claude
  attribution. The three things this repo cares about most.
