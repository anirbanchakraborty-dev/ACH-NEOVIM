-- Central icon definitions for ACH-NEOVIM

local M = {}

-- ── UI
M.ui = {
  find_file = "󰈞", -- nf-md-file_search
  new_file = "", -- nf-cod-new_file
  find_text = "󰍉", -- nf-md-magnify
  recent = "󰋚", -- nf-md-history
  config = "", -- nf-seti-config
  lazy = "󰏖", -- nf-md-package_variant
  quit = "󰗽", -- nf-md-exit_to_app
  startup = "󱐌", -- nf-md-lightning_bolt
  close = "󰅖", -- nf-md-close
  lock = "󰌾", -- nf-md-lock
  unlock = "󰌿", -- nf-md-lock_open
  menu = "󰍜", -- nf-md-menu
  check = "󰄬", -- nf-md-check
  checkbox = "󰄵", -- nf-md-checkbox_marked
  checkbox_blank = "󰄱", -- nf-md-checkbox_blank_outline
  radio_on = "󰐾", -- nf-md-radiobox_marked
  radio_off = "󰐽", -- nf-md-radiobox_blank
  pin = "󰐃", -- nf-md-pin
  bookmark = "󰃀", -- nf-md-bookmark
  bell = "󰂞", -- nf-md-bell
  calendar = "󰃭", -- nf-md-calendar
  clipboard = "󰅌", -- nf-md-clipboard_text
  download = "󰇚", -- nf-md-download
  upload = "󰕒", -- nf-md-upload
  refresh = "󰑓", -- nf-md-refresh
  undo = "󰕌", -- nf-md-undo
  redo = "󰑎", -- nf-md-redo
  filter = "󰈶", -- nf-md-filter
  sort = "󰒺", -- nf-md-sort
  expand = "", -- nf-cod-chevron_down
  collapse = "", -- nf-cod-chevron_right
  telescope = "", -- nf-cod-telescope
  dashboard = "󰕮", -- nf-md-view_dashboard
  terminal = "", -- nf-cod-terminal
  split_h = "󰤼", -- nf-md-arrow_split_horizontal (was missing)
  split_v = "󰤻", -- nf-md-arrow_split_vertical
  maximize = "󰊓", -- nf-md-window_maximize
  minimize = "󰊔", -- nf-md-window_minimize
  restore = "󰦛", -- nf-md-window_restore
  search = "", -- nf-cod-search
  replace = "󰛔", -- nf-md-find_replace
  eye = "󰈈", -- nf-md-eye
  eye_off = "󰈉", -- nf-md-eye_off
  link = "󰌹", -- nf-md-link
  unlink = "󰌺", -- nf-md-link_off
  plug = "󰐱", -- nf-md-power_plug
  plug_off = "󰐲", -- nf-md-power_plug_off
  palette = "󰏘", -- nf-md-palette
  pencil = "󰏫", -- nf-md-pencil
  trash = "󰩹", -- nf-md-trash_can
  save = "󰆓", -- nf-md-content_save
  home = "󰋜", -- nf-md-home
  folder_open = "󰝰", -- nf-md-folder_open
  folder_closed = "󰉋", -- nf-md-folder
  tree = "", -- nf-cod-list_tree
  indent = "󰉶", -- nf-md-format_indent_increase
  wrap = "󰖶", -- nf-md-wrap
  zoom_in = "󰐕", -- nf-md-magnify_plus
  zoom_out = "󰐖", -- nf-md-magnify_minus
  help = "󰋖", -- nf-md-help_circle
  info = "󰋽", -- nf-md-information
  lightbulb = "󰌵", -- nf-md-lightbulb
  rocket = "󰑣", -- nf-md-rocket_launch
  bug = "", -- nf-cod-bug
  wand = "󰁨", -- nf-md-auto_fix
  star = "󰓎", -- nf-md-star
  star_outline = "󰓏", -- nf-md-star_outline
  fire = "󰈸", -- nf-md-fire
  snow = "󰖘", -- nf-md-snowflake
  moon = "󰽥", -- nf-md-moon_waning_crescent
  sun = "󰖨", -- nf-md-white_balance_sunny
  key = "󰌆", -- nf-md-key
  shield = "󰒃", -- nf-md-shield_check
  globe = "󰖟", -- nf-md-web
  cloud = "󰅟", -- nf-md-cloud
  tag = "󰓹", -- nf-md-tag
  code = "", -- nf-cod-code
  debug = "", -- nf-cod-debug
  play = "󰐊", -- nf-md-play
  pause = "󰏤", -- nf-md-pause
  stop = "󰓛", -- nf-md-stop
  record = "󰑋", -- nf-md-record
  skip_next = "󰒭", -- nf-md-skip_next
  skip_prev = "󰒮", -- nf-md-skip_previous
}

-- ── Diagnostics
M.diagnostics = {
  Error = "", -- nf-cod-error
  Warn = "", -- nf-cod-warning
  Info = "", -- nf-cod-info
  Hint = "󰌵", -- nf-md-lightbulb
  Ok = "", -- nf-cod-check
}

-- ── Git
M.git = {
  branch = "", -- nf-cod-git_branch
  added = "", -- nf-cod-diff_added
  modified = "", -- nf-cod-diff_modified
  removed = "", -- nf-cod-diff_removed
  ignored = "󰈅", -- nf-md-file_hidden
  renamed = "󰁕", -- nf-md-arrow_right_bold
  untracked = "󰞋", -- nf-md-help_circle_outline
  conflict = "", -- nf-dev-git_compare
  staged = "󰄬", -- nf-md-check
  unstaged = "󰐊", -- nf-md-play (dot would also work)
  log = "", -- nf-cod-list_tree
  commit = "", -- nf-cod-git_commit
  merge = "", -- nf-cod-git_merge
  pull_request = "", -- nf-cod-git_pull_request
  stash = "󰏗", -- nf-md-package_variant_closed
  tag = "󰓹", -- nf-md-tag
  diff = "", -- nf-cod-diff
  repo = "", -- nf-cod-repo
  fork = "", -- nf-cod-repo_forked
  clone = "", -- nf-cod-repo_clone
  star = "", -- nf-cod-star_full
  issue_open = "", -- nf-cod-issues
  issue_closed = "", -- nf-cod-issue_closed
  action = "", -- nf-cod-play_circle
  github = "", -- nf-dev-github_badge
  gitlab = "", -- nf-dev-gitlab
  bitbucket = "", -- nf-dev-bitbucket
}

-- ── DAP (Debug Adapter Protocol)
M.dap = {
  Stopped = "󰁕", -- nf-md-arrow_right_bold
  Breakpoint = "", -- nf-cod-debug_breakpoint
  BreakpointCondition = "", -- nf-cod-debug_breakpoint_conditional
  BreakpointRejected = "", -- nf-cod-debug_breakpoint_unsupported
  LogPoint = "󰛿", -- nf-md-message_text
  Play = "", -- nf-cod-debug_start
  Pause = "", -- nf-cod-debug_pause
  StepInto = "", -- nf-cod-debug_step_into
  StepOver = "", -- nf-cod-debug_step_over
  StepOut = "", -- nf-cod-debug_step_out
  StepBack = "", -- nf-cod-debug_step_back
  Restart = "", -- nf-cod-debug_restart
  Terminate = "", -- nf-cod-debug_stop
  Disconnect = "", -- nf-cod-debug_disconnect
  Console = "", -- nf-cod-debug_console
  StackFrame = "", -- nf-cod-debug_stackframe
  StackFrameActive = "", -- nf-cod-debug_stackframe_active
  Thread = "󰓦", -- nf-md-swap_vertical (thread context)
  Watch = "󰂥", -- nf-md-binoculars (watch expression)
  Variable = "", -- nf-cod-symbol_variable (variables pane)
}

-- ── LSP Completion Kinds
-- Mirrors LazyVim's icons.kinds verbatim. Their picks (MDI for Snippet,
-- Variable, Boolean, Constant, Number, Struct, Function, Method, Namespace,
-- Codeium, TabNine; codicons for the rest) avoid a class of font-cache
-- bugs where certain codicons in the U+EB60+ range render as empty boxes
-- in iTerm2 + macOS even when fontTools confirms the codepoint exists in
-- the file. Trailing space on every value is intentional: blink.cmp's
-- mono spacing doesn't add its own icon/label gap, so the space lives in
-- the glyph string itself.
M.kinds = {
  Array = " ",
  Boolean = "󰨹 ",
  Class = " ",
  Codeium = "󰘦 ",
  Color = " ",
  Control = " ",
  Collapsed = " ",
  Constant = "󰏿 ",
  Constructor = " ",
  Copilot = " ",
  Enum = " ",
  EnumMember = " ",
  Event = " ",
  Field = " ",
  File = " ",
  Folder = " ",
  Function = "󰊕 ",
  Interface = " ",
  Key = " ",
  Keyword = " ",
  Method = "󰊕 ",
  Module = " ",
  Namespace = "󰦮 ",
  Null = "󰟢 ",
  Number = "󰎠 ",
  Object = " ",
  Operator = " ",
  Package = " ",
  Property = " ",
  Reference = " ",
  Snippet = "󱄽 ",
  String = " ",
  Struct = "󰆭 ",
  Supermaven = " ",
  TabNine = "󰏚 ",
  Text = " ",
  TypeParameter = " ",
  Unit = " ",
  Value = " ",
  Variable = "󰀫 ",

  -- Tree / UI helper (not an LSP kind, used by file explorers and inline
  -- expanders that read from this same table).
  Expanded = " ",
}

-- ── LSP Specific Signs
M.lsp = {
  server_installed = "󰄬", -- nf-md-check
  server_pending = "󰑐", -- nf-md-timer_sand
  server_uninstalled = "󰅖", -- nf-md-close
  code_action = "󰌵", -- nf-md-lightbulb
  code_lens = "󰜎", -- nf-md-glasses
  references = "", -- nf-cod-references
  definition = "", -- nf-cod-symbol_method
  declaration = "", -- nf-cod-go_to_file
  implementation = "", -- nf-cod-symbol_interface
  type_definition = "", -- nf-cod-symbol_class
  hover = "󰋖", -- nf-md-help_circle
  signature = "󰊕", -- nf-md-function
  rename = "󰑕", -- nf-md-rename_box
  format = "󰉣", -- nf-md-format_align_left
  incoming_calls = "󰏷", -- nf-md-phone_incoming
  outgoing_calls = "󰏻", -- nf-md-phone_outgoing
  document_symbol = "", -- nf-cod-symbol_file
  workspace_symbol = "", -- nf-cod-symbol_class
  diagnostic = "", -- nf-cod-bug
  folding_range = "", -- nf-cod-fold
}

-- ── Finder / Picker
M.find = {
  file = "󰈞", -- nf-md-file_search
  buffer = "󰈔", -- nf-md-file_document
  help = "󰋖", -- nf-md-help_circle
  grep = "󰍉", -- nf-md-magnify
  keymap = "󰌌", -- nf-md-keyboard
  cmd_hist = "󰋚", -- nf-md-history
  cmd = "", -- nf-cod-terminal
  resume = "󰑓", -- nf-md-refresh
  colorscheme = "󰏘", -- nf-md-palette
  marks = "󰃀", -- nf-md-bookmark
  registers = "󰅌", -- nf-md-clipboard_text
  man = "󰗚", -- nf-md-book_open_page_variant
  diagnostic = "", -- nf-cod-bug
  lsp_symbols = "", -- nf-cod-symbol_class
  git_files = "", -- nf-cod-git_branch
  git_commits = "", -- nf-cod-git_commit
  git_status = "", -- nf-cod-diff
  treesitter = "", -- nf-cod-list_tree
  quickfix = "", -- nf-cod-tasklist
  loclist = "󰍒", -- nf-md-map_marker_multiple
  spell = "󰓆", -- nf-md-spellcheck
  notify = "󰂞", -- nf-md-bell
}

-- ── Operating Systems
M.os = {
  mac = "", -- nf-dev-apple
  windows = "󰍲", -- nf-md-microsoft_windows
  linux = "", -- nf-dev-linux
  ubuntu = "", -- nf-dev-ubuntu
  fedora = "", -- nf-dev-fedora
  debian = "", -- nf-dev-debian
  arch = "󰣇", -- nf-md-arch
  centos = "", -- nf-dev-centos
  redhat = "", -- nf-dev-redhat
  freebsd = "", -- nf-dev-freebsd
  android = "", -- nf-dev-android
  ios = "", -- nf-dev-apple
  chrome_os = "", -- nf-dev-chrome
  nixos = "", -- nf-dev-nixos
  raspbian = "", -- nf-dev-raspberry_pi
}

-- ── Filetypes / Languages (comprehensive)
M.filetypes = {
  -- GitHub / Octo
  octo = "",
  gh = "",
  ["markdown.gh"] = "",

  -- Systems languages
  c = "", -- nf-seti-c
  cpp = "", -- nf-seti-cpp
  rust = "", -- nf-dev-rust
  go = "", -- nf-seti-go
  zig = "", -- nf-seti-zig
  nim = "", -- nf-seti-nim
  d = "", -- nf-seti-d
  asm = "", -- assembly

  -- JVM languages
  java = "", -- nf-dev-java
  kotlin = "", -- nf-seti-kotlin
  scala = "", -- nf-seti-scala
  groovy = "", -- nf-dev-groovy
  clojure = "", -- nf-dev-clojure

  -- .NET / Microsoft
  cs = "󰌛", -- nf-md-language_csharp
  fsharp = "", -- nf-dev-fsharp
  vb = "󰛥", -- nf-md-language_visual_basic

  -- Web frontend
  html = "", -- nf-seti-html
  css = "", -- nf-seti-css
  scss = "", -- nf-seti-sass
  sass = "", -- nf-seti-sass
  less = "", -- nf-seti-less
  javascript = "", -- nf-seti-javascript
  javascriptreact = "", -- nf-seti-react
  typescript = "", -- nf-seti-typescript
  typescriptreact = "", -- nf-seti-react
  vue = "", -- nf-seti-vue
  svelte = "", -- nf-seti-svelte
  astro = "", -- astro
  angular = "", -- nf-seti-angular

  -- Scripting
  python = "", -- nf-seti-python
  ruby = "", -- nf-seti-ruby
  perl = "", -- nf-seti-perl
  php = "", -- nf-seti-php
  lua = "", -- nf-seti-lua
  r = "󰟔", -- nf-md-language_r
  julia = "", -- nf-seti-julia
  elixir = "", -- nf-seti-elixir
  erlang = "", -- nf-dev-erlang
  haskell = "", -- nf-seti-haskell
  ocaml = "", -- nf-seti-ocaml

  -- Shell
  sh = "", -- nf-cod-terminal_bash
  bash = "",
  zsh = "",
  fish = "",
  powershell = "󰨊", -- nf-md-powershell

  -- Data / Config
  json = "", -- nf-seti-json
  jsonc = "",
  json5 = "",
  yaml = "", -- nf-seti-yml
  yml = "",
  toml = "", -- nf-seti-toml
  xml = "󰗀", -- nf-md-xml
  csv = "", -- nf-seti-csv
  tsv = "",
  ini = "", -- nf-seti-config
  conf = "",
  env = "", -- nf-seti-config
  dotenv = "",
  properties = "",

  -- Markup / Docs
  markdown = "", -- nf-dev-markdown
  mdx = "",
  tex = "", -- nf-seti-tex
  latex = "",
  rst = "󰊄", -- nf-md-alpha_r_box
  org = "", -- nf-seti-org
  typst = "󰊄", -- placeholder
  asciidoc = "",

  -- DevOps / Infra
  dockerfile = "󰡨", -- nf-md-docker
  docker = "󰡨",
  ["docker-compose"] = "󰡨",
  terraform = "󱁢", -- nf-md-terraform
  tf = "󱁢",
  hcl = "󱁢",
  nix = "", -- nf-dev-nixos
  vagrant = "⍱",
  ansible = "",
  puppet = "",
  helm = "󰠳",
  kubernetes = "󰠳", -- nf-md-kubernetes

  -- Build / Make
  make = "", -- nf-seti-makefile
  makefile = "",
  cmake = "",
  just = "",

  -- Data / Query
  sql = "", -- nf-dev-database
  graphql = "", -- nf-seti-graphql
  prisma = "",
  proto = "󰒓", -- protobuf

  -- Hardware / Embedded
  systemverilog = "󰍛", -- nf-md-memory
  verilog = "󰍛",
  vhdl = "󰍛",
  sv = "󰍛",

  -- Mobile
  swift = "", -- nf-seti-swift
  dart = "", -- nf-seti-dart
  objectivec = "", -- nf-dev-apple

  -- Functional
  lisp = "",
  scheme = "λ",
  racket = "λ",
  commonlisp = "λ",
  fennel = "",

  -- Misc languages
  awk = "",
  sed = "",
  vim = "", -- nf-dev-vim
  vimdoc = "",
  help = "󰋖",

  -- Config files (specific)
  gitconfig = "",
  gitignore = "",
  gitattributes = "",
  editorconfig = "",
  eslint = "󰱺", -- nf-md-eslint
  prettier = "",
  stylelint = "",
  webpack = "󰜫", -- nf-md-webpack
  vite = "",
  rollup = "",
  babel = "",
  tsconfig = "",
  packagejson = "",

  -- Binary / Compiled
  obj = "",
  bin = "",
  exe = "",
  dll = "",
  so = "",

  -- Media
  image = "󰋩", -- nf-md-image
  png = "󰋩",
  jpg = "󰋩",
  jpeg = "󰋩",
  gif = "󰋩",
  svg = "󰜡", -- nf-md-svg
  webp = "󰋩",
  ico = "󰋩",
  video = "󰕧", -- nf-md-video
  mp4 = "󰕧",
  mkv = "󰕧",
  audio = "󰎆", -- nf-md-music
  mp3 = "󰎆",
  flac = "󰎆",
  wav = "󰎆",
  font = "", -- nf-seti-font
  ttf = "",
  otf = "",
  woff = "",

  -- Archives
  zip = "", -- nf-oct-file_zip
  tar = "",
  gz = "",
  bz2 = "",
  xz = "",
  ["7z"] = "",
  rar = "",

  -- Documents
  pdf = "", -- nf-seti-pdf
  doc = "󰈬", -- nf-md-file_word
  docx = "󰈬",
  xls = "󰈛", -- nf-md-file_excel
  xlsx = "󰈛",
  ppt = "󰈧", -- nf-md-file_powerpoint
  pptx = "󰈧",
  txt = "󰈙", -- nf-md-file_document
  log = "󰷐", -- nf-md-text_long

  -- Lock files
  lock = "󰌾", -- nf-md-lock
  ["package-lock"] = "󰌾",
  ["yarn.lock"] = "󰌾",
  ["Cargo.lock"] = "󰌾",
  ["Gemfile.lock"] = "󰌾",
}

-- ── Statusline
M.statusline = {
  error = "", -- nf-cod-error
  warn = "", -- nf-cod-warning
  info = "", -- nf-cod-info
  hint = "󰌵", -- nf-md-lightbulb
  ok = "", -- nf-cod-check
  spinner = "󰑣", -- nf-md-rocket_launch
  readonly = "󰌾", -- nf-md-lock
  modified = "󰏫", -- nf-md-pencil
  clock = "󰥔", -- nf-md-clock
  line = "", -- nf-cod-symbol_numeric
  col = "󰠵", -- nf-md-table_column
  encoding = "", -- nf-cod-file_code
  fileformat = "", -- nf-seti-config
  branch = "", -- nf-cod-git_branch
  diff_add = "", -- nf-cod-diff_added
  diff_mod = "", -- nf-cod-diff_modified
  diff_rem = "", -- nf-cod-diff_removed
  lsp_active = "", -- nf-cod-pulse
  copilot = "", -- nf-cod-copilot
  macro = "󰑋", -- nf-md-record
  search = "󰍉", -- nf-md-magnify
  lazy = "󰏖", -- nf-md-package_variant
  mason = "", -- nf-cod-tools
}

-- ── Borders / Separators / Misc
M.misc = {
  dots = "󰇘",
  circle = "",
  circle_filled = "",
  diamond = "◆",
  square = "■",
  empty = "󰧣",
  chevron_right = "",
  chevron_left = "",
  arrow_right = "",
  arrow_left = "",
  arrow_up = "",
  arrow_down = "",
  triangle_up = "▲",
  triangle_down = "▼",
  separator = "│",
  separator_fat = "┃",
  pipe = "│",
  slash = "/",
  backslash = "\\",
  ellipsis = "…",
  tilde = "~",
  bullet = "•",
  dash = "─",
  double_dash = "══",
  bar_left = "▎",
  bar_right = "▕",
}

-- ── Borders (window / float)
M.border = {
  rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  square = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  double = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  thick = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
  none = { "", "", "", "", "", "", "", "" },
}

-- ── Dev Tools / Services
M.devtools = {
  -- Editors / IDEs
  vim = "", -- nf-dev-vim
  neovim = "", -- nf-seti-favicon
  vscode = "󰨞", -- nf-md-microsoft_visual_studio_code
  intellij = "",
  emacs = "",

  -- Version control
  git = "", -- nf-dev-git
  github = "", -- nf-dev-github_badge
  gitlab = "", -- nf-dev-gitlab
  bitbucket = "", -- nf-dev-bitbucket

  -- Package managers
  npm = "", -- nf-dev-npm
  yarn = "",
  pnpm = "",
  pip = "", -- nf-seti-python
  cargo = "", -- nf-dev-rust
  gem = "", -- nf-seti-ruby
  brew = "🍺",
  pacman = "󰣇", -- nf-md-arch

  -- Runtimes / Platforms
  nodejs = "󰎙", -- nf-md-nodejs
  deno = "",
  bun = "",

  -- Containers / Cloud
  docker = "󰡨", -- nf-md-docker
  kubernetes = "󰠳",
  terraform = "󱁢",
  aws = "󰸏", -- nf-md-aws
  azure = "󰠅", -- nf-md-microsoft_azure
  gcp = "󰊭", -- nf-md-google_cloud

  -- CI/CD
  github_actions = "", -- nf-cod-play_circle
  jenkins = "",
  circleci = "",

  -- Databases
  database = "", -- nf-dev-database
  mysql = "", -- nf-dev-mysql
  postgres = "", -- nf-dev-postgresql
  mongodb = "",
  redis = "", -- nf-dev-redis
  sqlite = "",
  firebase = "", -- nf-dev-firebase

  -- Monitoring / Logging
  grafana = "",
  prometheus = "",

  -- Communication
  slack = "󰒱", -- nf-md-slack
  discord = "󰙯", -- nf-md-discord
  teams = "󰊻",

  -- Testing
  test = "󰙨", -- nf-md-test_tube
  jest = "",
  pytest = "",
  vitest = "",

  -- Misc tools
  regex = "󰑑", -- nf-md-regex
  terminal = "", -- nf-cod-terminal
  ssh = "󰣀", -- nf-md-ssh
  api = "󰒍", -- nf-md-api
}

-- ── AI / Claude
M.ai = {
  claude = "✺", -- Anthropic Claude
  chat = "", -- nf-cod-comment_discussion
  send = "", -- nf-cod-send (paper plane)
  focus = "", -- nf-cod-target
  resume = "", -- nf-cod-debug_continue
  continue = "", -- nf-cod-debug_start
  model = "", -- nf-cod-settings_gear
  add_buf = "", -- nf-cod-new_file
  accept = "", -- nf-cod-check
  deny = "", -- nf-cod-close
  diff = "", -- nf-cod-diff
}

-- ── Neovim Plugin Ecosystem
M.plugins = {
  lazy = "󰏖", -- nf-md-package_variant
  mason = "", -- nf-cod-tools
  treesitter = "", -- nf-cod-list_tree
  telescope = "", -- nf-cod-telescope
  lsp = "", -- nf-cod-pulse
  cmp = "󰄴", -- nf-md-check_box
  dap = "", -- nf-cod-debug
  lint = "󰁨", -- nf-md-auto_fix
  format = "󰉣", -- nf-md-format_align_left
  snippet = "", -- nf-cod-symbol_snippet
  keybind = "󰌌", -- nf-md-keyboard
  colorscheme = "󰏘", -- nf-md-palette
  statusline = "󰍜", -- nf-md-menu
  tabline = "󰓩", -- nf-md-tab
  explorer = "", -- nf-cod-files
  git_signs = "", -- nf-cod-git_branch
  notify = "󰂞", -- nf-md-bell
  which_key = "󰌌", -- nf-md-keyboard
  mini = "󰟒",
  noice = "󰍡", -- nf-md-message
  trouble = "", -- nf-cod-warning
  todo = "", -- nf-cod-checklist
  outline = "", -- nf-cod-symbol_class
}

return M
