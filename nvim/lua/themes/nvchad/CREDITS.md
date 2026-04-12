# NvChad Theme Credits

The theme palette files in this directory (every `*.lua` file except
`deep-ocean.lua`) are vendored verbatim from
[NvChad/base46](https://github.com/NvChad/base46) and are redistributed
under the terms of the original license included here as `LICENSE`.

## Upstream

- **Source**: <https://github.com/NvChad/base46>
- **Original author**: Ashkan Kiani (`nvim-base16.lua`, © 2019) — see
  `LICENSE` in this directory for the MIT-style terms.
- **NvChad project**: maintained by [@siduck](https://github.com/siduck)
  and [contributors](https://github.com/NvChad/NvChad/graphs/contributors).
- **base16 spec**: the `base_16` palette slots follow the
  [base16 specification](https://github.com/chriskempson/base16) — see
  `base16-LICENSE` in this directory for the upstream MIT terms.

## Per-theme authorship

Many theme files include an in-file comment crediting the **original**
scheme they were derived from (e.g. `onedark.lua` credits
<https://github.com/one-dark>, `tokyonight.lua` credits
<https://github.com/tiagovla/tokyonight.nvim>, etc.). Those header
comments are preserved verbatim and remain the authoritative attribution
for each palette.

If you are a theme author listed in any of those headers and would like
a correction or removal, please open an issue on the ACH-NEOVIM repo.

## How the files are consumed

ACH-NEOVIM does NOT run NvChad's highlight-generator (`base46`). The
palette files are treated as pure data: the loader in `themes/init.lua`
reads each file's `M.base_30` / `M.base_16` / `M.type` fields and adapts
them into a tokyonight `on_colors` override. The `require("base46")`
call at the bottom of every vendored file is intercepted by
`themes/base46_shim.lua`, which is a no-op that returns the palette
unchanged.

This keeps the vendored files bit-identical to upstream so future
updates from NvChad/base46 can be applied as a straight copy.

## Local additions

- `deep-ocean.lua` is NOT from NvChad/base46 — it is ACH-NEOVIM's own
  signature palette, authored in the same file format so the loader can
  treat it uniformly alongside the vendored themes.
