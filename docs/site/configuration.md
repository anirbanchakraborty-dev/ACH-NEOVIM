Everything that makes ACH-NEOVIM what it is lives in plain Lua files in the repository. These are the places I change most, and how I change them.

### The layout

```text
~/.config/nvim
├── init.lua           checks the Neovim version, then loads lua/ach
├── lazy-lock.json     the commit of every plugin
├── mason-lock.json    the version of every Mason package
├── lua/ach/           options, keys, autocommands, the language table, and the logic behind each feature
│   └── plugins/       the plugin specs, one file per area
├── snippets/          my own snippets
├── ghostty/           Ghostty's settings
├── docs/              the key card, the list of languages, and the hand-written parts of this page
├── scripts/           check, update and docs
└── tests/             the test suite
```

### Options, keymaps and autocommands

Editor options live in `lua/ach/options.lua`, keys that belong to no plugin in `lua/ach/keymaps.lua`, and autocommands, the small actions Neovim runs when something happens, such as opening a file or saving one, in `lua/ach/autocmds.lua`. Keys that belong to a plugin live in that plugin's spec, under `keys`.

### Adding a plugin

A plugin is a file in `lua/ach/plugins/` that returns its spec, because lazy.nvim imports every file in that folder. The Full Spec tabs in the Plugins section below are real specs to copy from. Then:

- Give every key a `desc`, and give that description a line in `M.keys` in `lua/ach/icons.lua`. The test suite fails a key without one, since that line is what draws its icon in the menus.
- Give the plugin an entry in `lua/ach/docs.lua`, with its category and one sentence saying what it does. The test suite fails a plugin in `lazy-lock.json` without one.
- Start Neovim once, so lazy.nvim installs the plugin and records its commit in `lazy-lock.json`.
- If the plugin adds keys, run `scripts/check --keymaps`. Then run `scripts/check`, and commit the new file, `lazy-lock.json`, `lua/ach/icons.lua`, `lua/ach/docs.lua` and `docs/site/keymaps.json` together.

### Adding a language

Every language is one entry in `M.languages` in `lua/ach/languages.lua`, under its name. The entry lists the file types it covers in `ft`, the Tree-sitter parsers in `ts`, the language servers in `lsp`, the formatters in `fmt`, the linters in `lint`, any other Mason packages it needs in `mason`, and `harper = true` when Harper should check its grammar. The Entry tab of each language in the Languages section below is that language's real entry, and CMake's uses every one of these fields. Settings for a server go in `M.settings` in `lua/ach/servers.lua`, under the server's name, and show in the language's Options tab.

Then run `scripts/check`, and `scripts/check --full`, which installs the new language's tools, tests them, adds their versions to `mason-lock.json` and rewrites the list of languages in `docs/languages.md`. Commit all of it together.

### Settings for one project

Neovim reads a file called `.nvim.lua` in the folder it starts in, because ACH-NEOVIM turns on Neovim's `exrc` option. Neovim asks before it runs such a file the first time, and again whenever the file changes, so a repository you clone cannot run code on you just by shipping one. A LaTeX project can use it to give `Space c b` its own build command:

```lua
require("ach.latex").build_with(function(main)
  return { "make", "pdf" }, vim.fs.dirname(main)
end)
```

The function receives the main file's path and returns the command and the folder to run it in. Returning nothing falls back to latexmk.

<Callout type="warning">

Do not edit the configuration's own files for one project's needs. Put them in that project's `.nvim.lua`, where they stay with the project and never get in the way of an update.

</Callout>

### Updates and the lock files

`lazy-lock.json` holds the commit of every plugin and `mason-lock.json` the version of every Mason package, so two Macs on the same commit of this repository run the same code.

- `scripts/update --list` shows what an update would move: the new commits of each plugin and the newer release of each Mason package. It changes nothing.
- `scripts/update` updates every plugin and Mason package, runs `scripts/check --full`, and commits both lock files when it passes. When it fails, it puts the lock files back and makes what is installed match them again.
- `scripts/update --restore` does only that second part. Run it on a second Mac after a `git pull` brings new lock files.
- Inside Neovim, `:AchMasonUpdate` updates every installed Mason package and moves its pin, and `:AchMasonLock` pins a package installed by hand from the `:Mason` window.

<Callout type="warning">

Do not edit `lazy-lock.json` or `mason-lock.json` by hand. Update through `scripts/update` and the two commands above, so the lock files always describe what is really installed.

</Callout>
