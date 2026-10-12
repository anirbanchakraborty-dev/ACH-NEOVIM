-- The plugins that start five languages' servers themselves. ach.managed
-- turns each one's own start off and starts it once the server's program is
-- installed.
return {
  -- Rust and Haskell. Neither may be lazy-loaded: each does its work from an
  -- ftplugin, which must be on the runtime path before the first file of its
  -- type opens, and each loads the rest of itself only when first used.
  { "mrcjkb/rustaceanvim", version = "^9", lazy = false },
  { "mrcjkb/haskell-tools.nvim", version = "^11", lazy = false },

  -- Java and Scala, loaded when ach.managed first requires them.
  { "mfussenegger/nvim-jdtls", commit = "6e9d953f0b82bccdb834cfde0e893f3119c22592" },
  { "scalameta/nvim-metals", commit = "a4b20656bf1014404dd63bf9fd5f22fcc50fee52" },

  -- Lean, loaded as a .lean file is read or created, before its file type is
  -- set, so its own ftplugin and commands are there when the type is.
  {
    "Julian/lean.nvim",
    commit = "42186878a385ab021296e8f8024521d11a661754",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
  },
}
