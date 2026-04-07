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
   `formatting.lua`, `linting.lua`, and `treesitter.lua` (`auto_install = true`).

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

```
ACH-NEOVIM/
├── install.sh              one-shot installer (Homebrew, Neovim, claude CLI)
├── uninstall.sh            removes ~/.config/nvim and Neovim state dirs
├── README.md               user-facing docs
├── CLAUDE.md               this file
├── LICENSE                 MIT
└── nvim/
    ├── init.lua            entry point: options → keymaps → autocmds → lazy
    └── lua/
        ├── config/
        │   ├── icons.lua       central Nerd Font glyph table (M.ui, M.git, ...)
        │   ├── lazy.lua        bootstraps lazy.nvim, imports lua/plugins/*
        │   ├── options.lua     vim.opt defaults (leader, folds, splits, ...)
        │   ├── keymaps.lua     non-plugin keymaps (motions, windows, buffers)
        │   └── autocmds.lua    augroups (yank flash, big-file, prose mode, ...)
        └── plugins/
            ├── ai.lua          coder/claudecode.nvim integration
            ├── coding.lua      blink.cmp, mini.pairs/surround/ai, lazydev, ts-comments, ts-autotag
            ├── colorscheme.lua tokyonight + deep-ocean palette + every highlight override
            ├── editor.lua      which-key, fzf-lua, flash, todo-comments, trouble, grug-far
            ├── formatting.lua  conform.nvim + on-demand mason installer
            ├── git.lua         gitsigns, diffview, git-conflict, snacks lazygit/gitbrowse
            ├── linting.lua     nvim-lint + on-demand mason installer + debounced dispatcher
            ├── lsp.lua         mason + nvim-lspconfig + on-demand vim.lsp.enable
            ├── lualine.lua     lualine with custom ocean theme
            ├── terminal.lua    toggleterm + named language REPLs
            ├── treesitter.lua  nvim-treesitter (master branch) + textobjects
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
4. After install, the module's "enable" hook (e.g. `vim.lsp.enable(name)` for
   LSPs, or just re-running `lint.try_lint()` for linters) wires the tool up.
5. **Crucially**, after wiring up, the module re-fires `FileType` for any
   already-loaded buffers whose filetype matches, so the buffer that triggered
   the install actually gets the tool attached without needing a manual
   reload.

If you add a new LSP / formatter / linter, follow this pattern. Don't add an
`ensure_installed` table.

Treesitter uses a simpler form: `ensure_installed = {}` plus
`auto_install = true`, with a separate `FileType` autocmd in
`treesitter.lua`'s config function that polls for parser availability and
fires toast notifications.

---

## Custom colorscheme — deep ocean palette

`colorscheme.lua` runs tokyonight in `night` style with the following
overrides via `on_colors`:

```
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
