-- The icon database: every glyph ACH-NEOVIM draws, by name, and the tables that
-- give each key, which-key group, toggle and file type its icon. A glyph is a
-- Nerd Fonts 3.5.1 glyph, named in the comment beside it, or a plain Unicode
-- character where one already looks right. tests/test_icons.lua checks every
-- entry, so an icon added by hand is held to the same rules as these.
local M = {}

-- The nine colours which-key and mini.icons both draw in.
M.colors = { "azure", "blue", "cyan", "green", "grey", "orange", "purple", "red", "yellow" }

-- The named glyph tables, in the order this file defines them. A reference
-- such as "git.branch" names one glyph in one of them.
M.vocabulary = {
  "actions",
  "files",
  "buffers",
  "nav",
  "windows",
  "tabs",
  "edit",
  "code",
  "search",
  "lists",
  "diagnostics",
  "git",
  "gitsigns",
  "fold",
  "spell",
  "textobj",
  "session",
  "multicursor",
  "terminal",
  "ui",
  "claude",
  "lazy",
  "mason",
  "todo",
  "dap",
  "hardware",
  "lang",
  "kinds",
  "dashboard",
  "status",
}

-- Verbs: what a key does.
M.actions = {
  add = "\u{F0415}", -- md-plus
  add_box = "\u{F0416}", -- md-plus_box
  add_circle = "\u{F0417}", -- md-plus_circle
  remove = "\u{F0374}", -- md-minus
  remove_box = "\u{F0375}", -- md-minus_box
  remove_circle = "\u{F0376}", -- md-minus_circle
  save = "\u{F0193}", -- md-content_save
  save_all = "\u{F0194}", -- md-content_save_all
  save_edit = "\u{F0CFB}", -- md-content_save_edit
  save_off = "\u{F1643}", -- md-content_save_off
  open = "\u{F03CB}", -- md-open_in_app
  open_external = "\u{F03CC}", -- md-open_in_new
  close = "\u{F0156}", -- md-close
  close_box = "\u{F0157}", -- md-close_box
  close_all = "\u{F0C5D}", -- md-close_box_multiple
  delete = "\u{F01B4}", -- md-delete
  delete_forever = "\u{F05E8}", -- md-delete_forever
  delete_sweep = "\u{F05E9}", -- md-delete_sweep
  eraser = "\u{F01FE}", -- md-eraser
  copy = "\u{F018F}", -- md-content_copy
  paste = "\u{F0192}", -- md-content_paste
  cut = "\u{F0190}", -- md-content_cut
  duplicate = "\u{F0191}", -- md-content_duplicate
  undo = "\u{F054C}", -- md-undo
  redo = "\u{F044E}", -- md-redo
  undo_variant = "\u{F054D}", -- md-undo_variant
  edit = "\u{F03EB}", -- md-pencil
  edit_box = "\u{F03EC}", -- md-pencil_box
  edit_outline = "\u{F0CB6}", -- md-pencil_outline
  rename = "\u{F0455}", -- md-rename_box
  refresh = "\u{F0450}", -- md-refresh
  reload = "\u{F0453}", -- md-reload
  sync = "\u{F04E6}", -- md-sync
  run = "\u{F040A}", -- md-play
  run_circle = "\u{F040C}", -- md-play_circle
  stop = "\u{F04DB}", -- md-stop
  stop_circle = "\u{F0666}", -- md-stop_circle
  pause = "\u{F03E4}", -- md-pause
  pause_circle = "\u{F03E5}", -- md-pause_circle
  restart = "\u{F0709}", -- md-restart
  build = "\u{F08EA}", -- md-hammer
  wrench = "\u{F05B7}", -- md-wrench
  tools = "\u{F1064}", -- md-tools
  install = "\u{F03D4}", -- md-package_down
  update = "\u{F06B0}", -- md-update
  upgrade = "\u{F005F}", -- md-arrow_up_bold_circle
  clean = "\u{F00E2}", -- md-broom
  sort = "\u{F04BA}", -- md-sort
  sort_ascending = "\u{F04BC}", -- md-sort_ascending
  sort_descending = "\u{F04BD}", -- md-sort_descending
  sort_alphabetical = "\u{F05BD}", -- md-sort_alphabetical_ascending
  filter = "\u{F0232}", -- md-filter
  filter_off = "\u{F14EF}", -- md-filter_off
  swap = "\u{F04E1}", -- md-swap_horizontal
  swap_vertical = "\u{F04E2}", -- md-swap_vertical
  move = "\u{F01BE}", -- md-cursor_move
  drag = "\u{F01DB}", -- md-drag
  split = "\u{F00FB}", -- md-call_split
  merge = "\u{F00F8}", -- md-call_merge
  expand = "\u{F004C}", -- md-arrow_expand_all
  collapse = "\u{F0044}", -- md-arrow_collapse_all
  pin = "\u{F0403}", -- md-pin
  pin_outline = "\u{F0931}", -- md-pin_outline
  unpin = "\u{F0404}", -- md-pin_off
  star = "\u{F04CE}", -- md-star
  star_outline = "\u{F04D2}", -- md-star_outline
  bookmark = "\u{F00C0}", -- md-bookmark
  bookmark_add = "\u{F00C5}", -- md-bookmark_plus
  link = "\u{F0337}", -- md-link
  unlink = "\u{F0338}", -- md-link_off
  share = "\u{F0497}", -- md-share_variant
  download = "\u{F01DA}", -- md-download
  upload = "\u{F0552}", -- md-upload
  export = "\u{F0207}", -- md-export
  import = "\u{F02FA}", -- md-import
  lock = "\u{F033E}", -- md-lock
  unlock = "\u{F033F}", -- md-lock_open
  check = "\u{F012C}", -- md-check
  check_all = "\u{F012D}", -- md-check_all
  check_bold = "\u{F0E1E}", -- md-check_bold
  check_circle = "\u{F05E0}", -- md-check_circle
  check_circle_outline = "\u{F05E1}", -- md-check_circle_outline
  cancel = "\u{F0159}", -- md-close_circle
  cancel_outline = "\u{F015A}", -- md-close_circle_outline
  replay = "\u{F0459}", -- md-replay
  history = "\u{F02DA}", -- md-history
  select = "\u{F0485}", -- md-select
  select_all = "\u{F0486}", -- md-select_all
  select_drag = "\u{F0A6C}", -- md-select_drag
  wrap = "\u{F05B6}", -- md-wrap
  wrap_off = "\u{F0BDF}", -- md-wrap_disabled
  align_justify = "\u{F0261}", -- md-format_align_justify
  align_left = "\u{F0262}", -- md-format_align_left
  align_right = "\u{F0263}", -- md-format_align_right
  align_center = "\u{F0260}", -- md-format_align_center
  zoom_in = "\u{F034B}", -- md-magnify_plus
  zoom_out = "\u{F034A}", -- md-magnify_minus
  fullscreen = "\u{F0293}", -- md-fullscreen
  fullscreen_exit = "\u{F0294}", -- md-fullscreen_exit
  maximize = "\u{F05AF}", -- md-window_maximize
  minimize = "\u{F05B0}", -- md-window_minimize
  restore = "\u{F05B2}", -- md-window_restore
  hide = "\u{F0209}", -- md-eye_off
  show = "\u{F0208}", -- md-eye
  quit = "\u{F0A48}", -- md-exit_run
  exit = "\u{F0206}", -- md-exit_to_app
  power = "\u{F0425}", -- md-power
  login = "\u{F0342}", -- md-login
  logout = "\u{F0343}", -- md-logout
  settings = "\u{F0493}", -- md-cog
  settings_box = "\u{F0494}", -- md-cog_box
  tune = "\u{F062E}", -- md-tune
  inspect = "\u{F1276}", -- md-magnify_scan
  measure = "\u{F046D}", -- md-ruler
  calculate = "\u{F00EC}", -- md-calculator
  translate = "\u{F05CA}", -- md-translate
  transfer = "\u{F1065}", -- md-transfer
  fix = "\u{F0068}", -- md-auto_fix
  magic = "\u{F1844}", -- md-magic_staff
  test = "\u{F0668}", -- md-test_tube
  flask = "\u{F0093}", -- md-flask
  profile = "\u{F04C5}", -- md-speedometer
  benchmark = "\u{F051B}", -- md-timer_outline
  deploy = "\u{F14DE}", -- md-rocket_launch
  publish = "\u{F06A7}", -- md-publish
  record = "\u{F044B}", -- md-record_rec
  ["repeat"] = "\u{F0456}", -- md-repeat
  repeat_once = "\u{F0458}", -- md-repeat_once
  shuffle = "\u{F049D}", -- md-shuffle
  send = "\u{F048A}", -- md-send
  print = "\u{F042A}", -- md-printer
  attach = "\u{F03E2}", -- md-paperclip
  archive = "\u{F003C}", -- md-archive
  recycle = "\u{F044C}", -- md-recycle
  trash = "\u{F0A79}", -- md-trash_can
  backup = "\u{F006F}", -- md-backup_restore
  apply = "\u{F0791}", -- md-check_decagram
  increase = "\u{F0419}", -- md-plus_circle_outline
  decrease = "\u{F0377}", -- md-minus_circle_outline
  hand = "\u{F0E47}", -- md-hand_back_right
  gesture = "\u{F0741}", -- md-gesture_tap
}

-- Files, folders and the places they live.
M.files = {
  file = "\u{F0214}", -- md-file
  file_outline = "\u{F0224}", -- md-file_outline
  document = "\u{F0219}", -- md-file_document
  document_outline = "\u{F09EE}", -- md-file_document_outline
  code = "\u{F022E}", -- md-file_code
  find = "\u{F021E}", -- md-file_find
  search = "\u{F0C7C}", -- md-file_search
  tree = "\u{F0645}", -- md-file_tree
  tree_outline = "\u{F13D2}", -- md-file_tree_outline
  new = "\u{F0752}", -- md-file_plus
  move = "\u{F0AB9}", -- md-file_move
  replace = "\u{F0B32}", -- md-file_replace
  compare = "\u{F08AA}", -- md-file_compare
  restore = "\u{F0670}", -- md-file_restore
  lock = "\u{F0221}", -- md-file_lock
  hidden = "\u{F0613}", -- md-file_hidden
  file_link = "\u{F1177}", -- md-file_link
  cog = "\u{F107B}", -- md-file_cog
  check = "\u{F0216}", -- md-file_check
  edit = "\u{F11E7}", -- md-file_edit
  star = "\u{F103A}", -- md-file_star
  eye = "\u{F0DCA}", -- md-file_eye
  recent = "\u{F12E1}", -- md-file_clock
  export = "\u{F021D}", -- md-file_export
  import = "\u{F0220}", -- md-file_import
  remove = "\u{F0B98}", -- md-file_remove
  question = "\u{F086F}", -- md-file_question
  chart = "\u{F0215}", -- md-file_chart
  table = "\u{F0C7E}", -- md-file_table
  image = "\u{F021F}", -- md-file_image
  pdf = "\u{F0226}", -- md-file_pdf_box
  music = "\u{F0223}", -- md-file_music
  video = "\u{F022B}", -- md-file_video
  word = "\u{F022D}", -- md-file_word_box
  excel = "\u{F021C}", -- md-file_excel_box
  powerpoint = "\u{F0228}", -- md-file_powerpoint_box
  cad = "\u{F0EEB}", -- md-file_cad
  certificate = "\u{F1186}", -- md-file_certificate
  key = "\u{F1184}", -- md-file_key
  download = "\u{F0965}", -- md-file_download
  upload = "\u{F0A4D}", -- md-file_upload
  multiple = "\u{F0222}", -- md-file_multiple
  undo = "\u{F08DC}", -- md-file_undo
  sync = "\u{F1216}", -- md-file_sync
  alert = "\u{F0A4B}", -- md-file_alert
  copy_path = "\u{F1265}", -- md-clipboard_file
  folder = "\u{F024B}", -- md-folder
  folder_open = "\u{F0770}", -- md-folder_open
  folder_outline = "\u{F0256}", -- md-folder_outline
  folder_open_outline = "\u{F0DCF}", -- md-folder_open_outline
  folder_search = "\u{F0968}", -- md-folder_search
  folder_star = "\u{F069D}", -- md-folder_star
  folder_cog = "\u{F107F}", -- md-folder_cog
  folder_home = "\u{F10B5}", -- md-folder_home
  folder_clock = "\u{F0ABA}", -- md-folder_clock
  folder_lock = "\u{F0250}", -- md-folder_lock
  folder_network = "\u{F0870}", -- md-folder_network
  folder_sync = "\u{F0D0B}", -- md-folder_sync
  folder_zip = "\u{F06EB}", -- md-folder_zip
  folder_text = "\u{F0C82}", -- md-folder_text
  folder_wrench = "\u{F19FC}", -- md-folder_wrench
  folder_account = "\u{F024C}", -- md-folder_account
  folder_multiple = "\u{F0253}", -- md-folder_multiple
  folder_move = "\u{F0252}", -- md-folder_move
  folder_remove = "\u{F0258}", -- md-folder_remove
  folder_edit = "\u{F08DE}", -- md-folder_edit
  folder_plus = "\u{F0257}", -- md-folder_plus
  home = "\u{F02DC}", -- md-home
  database = "\u{F01BC}", -- md-database
  zip = "\u{F05C4}", -- md-zip_box
  package = "\u{F03D3}", -- md-package
  cloud = "\u{F015F}", -- md-cloud
  cloud_upload = "\u{F0167}", -- md-cloud_upload
  cloud_download = "\u{F0162}", -- md-cloud_download
  harddisk = "\u{F02CA}", -- md-harddisk
  server = "\u{F048B}", -- md-server
  library = "\u{F0331}", -- md-library
  book = "\u{F00BA}", -- md-book
  book_open = "\u{F05DA}", -- md-book_open_page_variant
  notebook = "\u{F082E}", -- md-notebook
  note = "\u{F039A}", -- md-note
  note_text = "\u{F039E}", -- md-note_text
  note_edit = "\u{F1781}", -- md-note_edit
  clipboard = "\u{F0147}", -- md-clipboard
  clipboard_text = "\u{F014D}", -- md-clipboard_text
  clipboard_list = "\u{F10D4}", -- md-clipboard_list
  clipboard_check = "\u{F014E}", -- md-clipboard_check
  clipboard_multiple = "\u{F1267}", -- md-clipboard_multiple
  scratch = "\u{F14E7}", -- md-notebook_edit
}

-- Open buffers.
M.buffers = {
  buffer = "\u{F09EE}", -- md-file_document_outline
  list = "\u{F1517}", -- md-file_document_multiple
  alternate = "\u{F0FB4}", -- md-file_swap
  delete = "\u{F0B98}", -- md-file_remove
  delete_others = "\u{F1037}", -- md-file_remove_outline
  delete_window = "\u{F0158}", -- md-close_box_outline
  new = "\u{F1A9D}", -- md-file_document_plus
  edit = "\u{F0DC8}", -- md-file_document_edit
  alert = "\u{F1A97}", -- md-file_document_alert
  check = "\u{F1A99}", -- md-file_document_check
}

-- Cursor motions, jumps and scrolling.
M.nav = {
  left = "\u{F004D}", -- md-arrow_left
  right = "\u{F0054}", -- md-arrow_right
  up = "\u{F005D}", -- md-arrow_up
  down = "\u{F0045}", -- md-arrow_down
  left_bold = "\u{F0731}", -- md-arrow_left_bold
  right_bold = "\u{F0734}", -- md-arrow_right_bold
  up_bold = "\u{F0737}", -- md-arrow_up_bold
  down_bold = "\u{F072E}", -- md-arrow_down_bold
  next = "\u{F0057}", -- md-arrow_right_bold_circle_outline
  prev = "\u{F0050}", -- md-arrow_left_bold_circle_outline
  first_line = "\u{F0795}", -- md-arrow_collapse_up
  last_line = "\u{F0792}", -- md-arrow_collapse_down
  line_start = "\u{F061F}", -- md-format_horizontal_align_left
  line_end = "\u{F0620}", -- md-format_horizontal_align_right
  line_first_char = "\u{F0262}", -- md-format_align_left
  window_top = "\u{F0755}", -- md-format_align_top
  window_middle = "\u{F0754}", -- md-format_align_middle
  window_bottom = "\u{F0753}", -- md-format_align_bottom
  view_top = "\u{F0623}", -- md-format_vertical_align_top
  view_center = "\u{F0622}", -- md-format_vertical_align_center
  view_bottom = "\u{F0621}", -- md-format_vertical_align_bottom
  view_left = "\u{F061F}", -- md-format_horizontal_align_left
  view_right = "\u{F0620}", -- md-format_horizontal_align_right
  pan_left = "\u{F0BB9}", -- md-pan_left
  pan_right = "\u{F0BBA}", -- md-pan_right
  page_up = "\u{F013F}", -- md-chevron_double_up
  page_down = "\u{F013C}", -- md-chevron_double_down
  word = "\u{F0FBA}", -- md-format_letter_starts_with
  word_end = "\u{F0FB8}", -- md-format_letter_ends_with
  char = "\u{F04FE}", -- md-target
  char_repeat = "\u{F0547}", -- md-repeat_variant
  paragraph = "\u{F027D}", -- md-format_paragraph
  match = "\u{F016A}", -- md-code_brackets
  paren = "\u{F0172}", -- md-code_parentheses
  brace = "\u{F0169}", -- md-code_braces
  angle = "\u{F016E}", -- md-code_less_than
  changes = "\u{F0DC9}", -- md-file_document_edit_outline
  last_insert = "\u{F0CB6}", -- md-pencil_outline
  jump = "\u{F01B7}", -- md-debug_step_over
  target = "\u{F04FE}", -- md-target
  crosshairs = "\u{F01A4}", -- md-crosshairs_gps
  map_marker = "\u{F034E}", -- md-map_marker
  compass = "\u{F018B}", -- md-compass
  flash = "\u{F0241}", -- md-flash
  flash_auto = "\u{F0242}", -- md-flash_auto
  flash_select = "\u{F0F82}", -- md-select_group
  flash_remote = "\u{F0454}", -- md-remote
  flash_search = "\u{F1A7E}", -- md-text_search_variant
  grow = "\u{F0616}", -- md-arrow_expand
  anchor = "\u{F0031}", -- md-anchor
  ["goto"] = "\u{F08C9}", -- md-bullseye_arrow
}

-- Window layout.
M.windows = {
  window = "\u{F10AC}", -- md-dock_window
  go_left = "\u{F0733}", -- md-arrow_left_bold_box_outline
  go_down = "\u{F0730}", -- md-arrow_down_bold_box_outline
  go_up = "\u{F0739}", -- md-arrow_up_bold_box_outline
  go_right = "\u{F0736}", -- md-arrow_right_bold_box_outline
  far_left = "\u{F10AA}", -- md-dock_left
  far_bottom = "\u{F10A9}", -- md-dock_bottom
  far_top = "\u{F1513}", -- md-dock_top
  far_right = "\u{F10AB}", -- md-dock_right
  height_inc = "\u{F084F}", -- md-arrow_expand_vertical
  height_dec = "\u{F084D}", -- md-arrow_collapse_vertical
  width_inc = "\u{F084E}", -- md-arrow_expand_horizontal
  width_dec = "\u{F084C}", -- md-arrow_collapse_horizontal
  max_height = "\u{F0E7A}", -- md-arrow_up_down_bold
  max_width = "\u{F0E74}", -- md-arrow_left_right_bold
  equalize = "\u{F01FD}", -- md-equal_box
  split_below = "\u{F0BCB}", -- md-view_split_horizontal
  split_right = "\u{F0BCC}", -- md-view_split_vertical
  close = "\u{F05AD}", -- md-window_close
  only = "\u{F05AF}", -- md-window_maximize
  swap = "\u{F0BCD}", -- md-swap_horizontal_bold
  switch = "\u{F08C1}", -- md-swap_horizontal_variant
  to_tab = "\u{F03CC}", -- md-open_in_new
  hydra = "\u{F0931}", -- md-pin_outline
  zoom = "\u{F0293}", -- md-fullscreen
  dock = "\u{F06FD}", -- md-page_layout_sidebar_left
  dock_pick = "\u{F0843}", -- md-view_dashboard_variant
  layout = "\u{F0574}", -- md-view_quilt
  grid = "\u{F0570}", -- md-view_grid
}

-- Tab pages.
M.tabs = {
  tab = "\u{F04E9}", -- md-tab
  new = "\u{F075C}", -- md-tab_plus
  next = "\u{F0BB0}", -- md-page_next
  prev = "\u{F0BB2}", -- md-page_previous
  first = "\u{F0600}", -- md-page_first
  last = "\u{F0601}", -- md-page_last
  close = "\u{F0B4C}", -- md-tab_remove
  close_others = "\u{F0B4B}", -- md-tab_minus
  search = "\u{F199E}", -- md-tab_search
  unselected = "\u{F04EA}", -- md-tab_unselected
}

-- Operators and text edits.
M.edit = {
  change = "\u{F03EB}", -- md-pencil
  delete = "\u{F01B4}", -- md-delete
  yank = "\u{F018F}", -- md-content_copy
  replace = "\u{F06D4}", -- md-find_replace
  format = "\u{F0261}", -- md-format_align_justify
  indent = "\u{F0276}", -- md-format_indent_increase
  outdent = "\u{F0275}", -- md-format_indent_decrease
  upper = "\u{F0B36}", -- md-format_letter_case_upper
  lower = "\u{F0B35}", -- md-format_letter_case_lower
  case = "\u{F0B34}", -- md-format_letter_case
  visual = "\u{F0485}", -- md-select
  visual_line = "\u{F09AA}", -- md-text_long
  visual_last = "\u{F0FDA}", -- md-select_place
  move_up = "\u{F0737}", -- md-arrow_up_bold
  move_down = "\u{F072E}", -- md-arrow_down_bold
  line_above = "\u{F04F4}", -- md-table_row_plus_before
  line_below = "\u{F04F3}", -- md-table_row_plus_after
  delete_line = "\u{F006E}", -- md-backspace
  delete_word = "\u{F0B5C}", -- md-backspace_outline
  repeat_sub = "\u{F0456}", -- md-repeat
  macro = "\u{F044B}", -- md-record_rec
  macro_repeat = "\u{F0458}", -- md-repeat_once
  undo_tree = "\u{F0531}", -- md-tree
  escape = "\u{F12B7}", -- md-keyboard_esc
  join = "\u{F00F8}", -- md-call_merge
  sort = "\u{F04BA}", -- md-sort
  wrap = "\u{F05B6}", -- md-wrap
}

-- Code intelligence: language servers, tree-sitter, comments and formatting.
M.code = {
  code = "\u{F0169}", -- md-code_braces
  action = "\u{F06E9}", -- md-lightbulb_on_outline
  rename = "\u{F0455}", -- md-rename_box
  references = "\u{F0FE8}", -- md-vector_link
  definition = "\u{F08C9}", -- md-bullseye_arrow
  declaration = "\u{F05DD}", -- md-bullseye
  implementation = "\u{F1323}", -- md-hammer_wrench
  type_definition = "\u{F0C24}", -- md-alpha_t_box_outline
  symbols = "\u{F0832}", -- md-shape_outline
  signature = "\u{F0DFB}", -- md-signature
  codelens = "\u{F02AA}", -- md-glasses
  hover = "\u{F02FD}", -- md-information_outline
  format = "\u{F027C}", -- md-format_paint
  autoformat = "\u{F0068}", -- md-auto_fix
  autoformat_buffer = "\u{F0216}", -- md-file_check
  lint = "\u{F00E2}", -- md-broom
  snippet = "\u{F0190}", -- md-content_cut
  comment = "\u{F0182}", -- md-comment_outline
  comment_line = "\u{F0189}", -- md-comment_text_outline
  comment_add = "\u{F0183}", -- md-comment_plus_outline
  treesitter = "\u{F0645}", -- md-file_tree
  node_parent = "\u{F0F82}", -- md-select_group
  node_child = "\u{F0487}", -- md-select_inverse
  node_next = "\u{F0485}", -- md-select
  node_prev = "\u{F0488}", -- md-select_off
  node_sibling = "\u{F0AD9}", -- md-select_compare
  grow_selection = "\u{F0A6C}", -- md-select_drag
  inspect = "\u{F020A}", -- md-eyedropper
  inlay_hints = "\u{F0BD7}", -- md-tooltip_text_outline
  conceal = "\u{F06D1}", -- md-eye_off_outline
  line_numbers = "\u{F027B}", -- md-format_list_numbered
  relative_numbers = "\u{F03A0}", -- md-numeric
  tag = "\u{F04F9}", -- md-tag
  tag_preview = "\u{F1907}", -- md-tag_search
  lsp = "\u{F08D6}", -- md-cogs
  outline = "\u{F027A}", -- md-format_list_bulleted_type
  words = "\u{F0FB9}", -- md-format_letter_matches
  regex = "\u{F0451}", -- md-regex
  ["function"] = "\u{F0295}", -- md-function
  lambda = "\u{F0627}", -- md-lambda
  variable = "\u{F0AE7}", -- md-variable
  api = "\u{F109B}", -- md-api
  console = "\u{F018D}", -- md-console
  debug = "\u{F00E4}", -- md-bug
  test = "\u{F0668}", -- md-test_tube
  coverage = "\u{F07AF}", -- md-chart_donut
  benchmark = "\u{F051B}", -- md-timer_outline
  calls_in = "\u{F00FA}", -- md-call_received
  calls_out = "\u{F00F7}", -- md-call_made
  source_action = "\u{F1801}", -- md-lightbulb_auto_outline
  organize_imports = "\u{F05BD}", -- md-sort_alphabetical_ascending
  rename_file = "\u{F1031}", -- md-file_move_outline
}

-- Pickers and searches.
M.search = {
  search = "\u{F0349}", -- md-magnify
  find = "\u{F021E}", -- md-file_find
  files = "\u{F0C7C}", -- md-file_search
  files_cwd = "\u{F0C7D}", -- md-file_search_outline
  git_files = "\u{F02A2}", -- md-git
  config = "\u{F107B}", -- md-file_cog
  projects = "\u{F069D}", -- md-folder_star
  recent = "\u{F12E1}", -- md-file_clock
  grep = "\u{F13B8}", -- md-text_search
  grep_buffers = "\u{F0EAE}", -- md-text_box_search
  lines = "\u{F126F}", -- md-format_list_text
  command_history = "\u{F07B7}", -- md-console_line
  commands = "\u{F0633}", -- md-apple_keyboard_command
  notifications = "\u{F009A}", -- md-bell
  registers = "\u{F1267}", -- md-clipboard_multiple
  search_history = "\u{F02DA}", -- md-history
  autocmds = "\u{F06A9}", -- md-robot
  help = "\u{F087E}", -- md-lifebuoy
  highlights = "\u{F0E31}", -- md-format_color_highlight
  icons = "\u{F01F2}", -- md-emoticon_outline
  jumps = "\u{F0D20}", -- md-map_marker_path
  keymaps = "\u{F030C}", -- md-keyboard
  buffer_keymaps = "\u{F097B}", -- md-keyboard_outline
  marks = "\u{F0E15}", -- md-bookmark_multiple
  man = "\u{F14F7}", -- md-book_open_variant
  plugin_spec = "\u{F0A66}", -- md-puzzle_outline
  resume = "\u{F099B}", -- md-restore
  undo = "\u{F02DA}", -- md-history
  word = "\u{F0FB9}", -- md-format_letter_matches
  replace = "\u{F06D4}", -- md-find_replace
  next = "\u{F13B8}", -- md-text_search
  prev = "\u{F13B8}", -- md-text_search
  forward = "\u{F1874}", -- md-magnify_expand
  backward = "\u{F0980}", -- md-magnify_close
  todo_fix = "\u{F063E}", -- md-checkbox_multiple_marked_circle_outline
  clear = "\u{F120D}", -- md-magnify_remove_outline
}

-- The quickfix, location and argument lists.
M.lists = {
  quickfix = "\u{F0DD0}", -- md-format_list_bulleted_square
  location = "\u{F0352}", -- md-map_marker_radius
  args = "\u{F0222}", -- md-file_multiple
}

-- Diagnostic severities (Error, Warn, Info, Hint), as language servers and the
-- picker name them, and the keys that move between diagnostics.
M.diagnostics = {
  Error = "\u{F057}", -- fa-times_circle
  Warn = "\u{F071}", -- fa-warning
  Info = "\u{F05A}", -- fa-info_circle
  Hint = "\u{F0EB}", -- fa-lightbulb
  group = "\u{F04D9}", -- md-stethoscope
  jump = "\u{F04D9}", -- md-stethoscope
  line = "\u{F0362}", -- md-message_alert
  list = "\u{F0CE4}", -- md-alert_box_outline
  buffer = "\u{F0A4C}", -- md-file_alert_outline
}

-- Git.
M.git = {
  git = "\u{F02A2}", -- md-git
  github = "\u{F02A4}", -- md-github
  branch = "\u{E725}", -- dev-git_branch
  added = "\u{F0FE}", -- fa-plus_square
  modified = "\u{F14B}", -- fa-pencil_square
  removed = "\u{F146}", -- fa-minus_square
  renamed = "\u{F1031}", -- md-file_move_outline
  untracked = "\u{F078B}", -- md-help_box
  staged = "\u{F0E1E}", -- md-check_bold
  conflict = "\u{F0787}", -- md-sword_cross
  commit = "\u{F0718}", -- md-source_commit
  merge = "\u{F062D}", -- md-source_merge
  pull = "\u{F04C2}", -- md-source_pull
  pull_request = "\u{F04C2}", -- md-source_pull
  issue = "\u{F41B}", -- oct-issue_opened
  stash = "\u{F03D4}", -- md-package_down
  tag = "\u{F04FC}", -- md-tag_outline
  remote = "\u{F0CCF}", -- md-source_repository
  diff = "\u{F055A}", -- md-vector_difference
  blame = "\u{F0935}", -- md-account_search_outline
  log = "\u{F0BD3}", -- md-timeline_text
  hunk = "\u{F0992}", -- md-plus_minus
  hunk_stage = "\u{F0334}", -- md-plus_box_multiple
  hunk_reset = "\u{F054D}", -- md-undo_variant
  fork = "\u{F04C1}", -- md-source_fork
  repository = "\u{F0CD0}", -- md-source_repository_multiple
  lazygit = "\u{F062C}", -- md-source_branch
}

-- The sign column's change bars, drawn as plain block characters.
M.gitsigns = {
  add = "\u{258E}", -- U+258E left one quarter block
  change = "\u{258E}", -- U+258E left one quarter block
  delete = "\u{2581}", -- U+2581 lower one eighth block
  topdelete = "\u{2594}", -- U+2594 upper one eighth block
  changedelete = "\u{258E}", -- U+258E left one quarter block
  untracked = "\u{2506}", -- U+2506 box drawings light triple dash vertical
}

-- Folds.
M.fold = {
  fold = "\u{F054E}", -- md-unfold_less_horizontal
  open = "\u{F054F}", -- md-unfold_more_horizontal
  close = "\u{F054E}", -- md-unfold_less_horizontal
  toggle = "\u{F0761}", -- md-unfold_more_vertical
  create = "\u{F0704}", -- md-plus_box_outline
  delete = "\u{F06F2}", -- md-minus_box_outline
  update = "\u{F0450}", -- md-refresh
}

-- Spelling.
M.spell = {
  spell = "\u{F04C6}", -- md-spellcheck
  add = "\u{F05DB}", -- md-book_plus
  bad = "\u{F0A97}", -- md-book_remove
  suggest = "\u{F19E4}", -- md-lightbulb_question_outline
}

-- Text objects.
M.textobj = {
  around = "\u{F0D32}", -- md-selection_ellipse
  inside = "\u{F0487}", -- md-select_inverse
  string = "\u{EB8D}", -- cod-symbol_string
  angle = "\u{F016E}", -- md-code_less_than
  parens = "\u{F0172}", -- md-code_parentheses
  brackets = "\u{F016A}", -- md-code_brackets
  braces = "\u{F0169}", -- md-code_braces
  word = "\u{F0FBA}", -- md-format_letter_starts_with
  paragraph = "\u{F027D}", -- md-format_paragraph
  sentence = "\u{F09A9}", -- md-text_short
  tag = "\u{F0174}", -- md-code_tags
  scope = "\u{F10D6}", -- md-code_braces_box
  scope_top = "\u{F0623}", -- md-format_vertical_align_top
  scope_bottom = "\u{F0621}", -- md-format_vertical_align_bottom
}

-- Sessions.
M.session = {
  session = "\u{F006F}", -- md-backup_restore
  restore = "\u{F006F}", -- md-backup_restore
  pick = "\u{F10D4}", -- md-clipboard_list
  last = "\u{F02DA}", -- md-history
  stop = "\u{F1643}", -- md-content_save_off
}

-- Multiple cursors.
M.multicursor = {
  cursor = "\u{F05E7}", -- md-cursor_text
  add_match = "\u{F1143}", -- md-plus_box_multiple_outline
  skip = "\u{F01B7}", -- md-debug_step_over
  all = "\u{F0486}", -- md-select_all
  toggle = "\u{F0CFD}", -- md-cursor_default_click
  delete = "\u{F09E7}", -- md-delete_outline
  clear = "\u{F00E2}", -- md-broom
  align = "\u{F0262}", -- md-format_align_left
  above = "\u{F0738}", -- md-arrow_up_bold_box
  below = "\u{F072F}", -- md-arrow_down_bold_box
}

-- Terminals.
M.terminal = {
  term = "\u{F018D}", -- md-console
  cwd = "\u{F018D}", -- md-console
  root = "\u{F08A9}", -- md-console_network
  run = "\u{F07B7}", -- md-console_line
  float = "\u{F0614}", -- md-application_outline
}

-- The interface itself, and everyday objects worth a name.
M.ui = {
  toggle = "\u{F0521}", -- md-toggle_switch
  toggle_off = "\u{F0522}", -- md-toggle_switch_off
  redraw = "\u{F0450}", -- md-refresh
  escape = "\u{F12B7}", -- md-keyboard_esc
  cursorline = "\u{F05C8}", -- md-format_line_style
  notifications = "\u{F009A}", -- md-bell
  notifications_off = "\u{F009B}", -- md-bell_off
  palette = "\u{F03D8}", -- md-palette
  swatch = "\u{F08B5}", -- md-palette_swatch
  dashboard = "\u{F056E}", -- md-view_dashboard
  statusline = "\u{F10A9}", -- md-dock_bottom
  keyboard = "\u{F030C}", -- md-keyboard
  mouse = "\u{F037D}", -- md-mouse
  help = "\u{F0625}", -- md-help_circle_outline
  info = "\u{F02FD}", -- md-information_outline
  vim = "\u{E62B}", -- custom-vim
  neovim = "\u{E6AE}", -- custom-neovim
  health = "\u{F05F6}", -- md-heart_pulse
  checkhealth = "\u{F06EF}", -- md-medical_bag
  messages = "\u{F0369}", -- md-message_text
  log = "\u{F09ED}", -- md-text_box_outline
  news = "\u{F0395}", -- md-newspaper
  rss = "\u{F046B}", -- md-rss
  web = "\u{F059F}", -- md-web
  email = "\u{F01EE}", -- md-email
  calendar = "\u{F00ED}", -- md-calendar
  clock = "\u{F0150}", -- md-clock_outline
  alarm = "\u{F0020}", -- md-alarm
  user = "\u{F0004}", -- md-account
  users = "\u{F0849}", -- md-account_group
  key = "\u{F0306}", -- md-key
  shield = "\u{F0565}", -- md-shield_check
  heart = "\u{F02D1}", -- md-heart
  coffee = "\u{F0176}", -- md-coffee
  rocket = "\u{F14DE}", -- md-rocket_launch
  thumb_up = "\u{F0513}", -- md-thumb_up
  thumb_down = "\u{F0511}", -- md-thumb_down
  question = "\u{F02D7}", -- md-help_circle
  dots = "\u{F01D8}", -- md-dots_horizontal
  dots_vertical = "\u{F01D9}", -- md-dots_vertical
  menu = "\u{F035C}", -- md-menu
  list = "\u{F0279}", -- md-format_list_bulleted
  table = "\u{F04EB}", -- md-table
  chart = "\u{F0128}", -- md-chart_bar
  graph = "\u{F012A}", -- md-chart_line
  pie = "\u{F012B}", -- md-chart_pie
  image = "\u{F02E9}", -- md-image
  camera = "\u{F0100}", -- md-camera
  video = "\u{F0567}", -- md-video
  music = "\u{F075A}", -- md-music
  microphone = "\u{F036C}", -- md-microphone
  volume = "\u{F057E}", -- md-volume_high
  mute = "\u{F0581}", -- md-volume_off
  wifi = "\u{F05A9}", -- md-wifi
  bluetooth = "\u{F00AF}", -- md-bluetooth
  battery = "\u{F0079}", -- md-battery
  plug = "\u{F06A5}", -- md-power_plug
  sun = "\u{F0599}", -- md-weather_sunny
  moon = "\u{F0594}", -- md-weather_night
  brightness = "\u{F00DF}", -- md-brightness_6
  contrast = "\u{F0197}", -- md-contrast_circle
  brush = "\u{F00E3}", -- md-brush
  eyedropper = "\u{F020A}", -- md-eyedropper
  layers = "\u{F0328}", -- md-layers
  sidebar = "\u{F06FD}", -- md-page_layout_sidebar_left
  zen = "\u{F117B}", -- md-meditation
  dim = "\u{F00DD}", -- md-brightness_4
  indent_guides = "\u{F0276}", -- md-format_indent_increase
  scroll = "\u{F1552}", -- md-mouse_move_vertical
  animate = "\u{F05D8}", -- md-animation
  profiler = "\u{F029A}", -- md-gauge
  profiler_highlights = "\u{F066E}", -- md-chart_timeline
  preview = "\u{F06D0}", -- md-eye_outline
  fire = "\u{F0238}", -- md-fire
  lightning = "\u{F140B}", -- md-lightning_bolt
  flag = "\u{F023B}", -- md-flag
  label = "\u{F0316}", -- md-label_outline
  bell = "\u{F009E}", -- md-bell_ring
  target = "\u{F04FE}", -- md-target
  globe = "\u{F01E7}", -- md-earth
  emoji = "\u{F01F2}", -- md-emoticon_outline
}

-- Claude Code.
M.claude = {
  claude = "\u{2726}", -- U+2726 black four pointed star
  ai = "\u{F0674}", -- md-creation
  chat = "\u{F0EDE}", -- md-chat_outline
  send = "\u{F048A}", -- md-send
  add_file = "\u{F0EED}", -- md-file_plus_outline
  add_buffer = "\u{F1A9E}", -- md-file_document_plus_outline
  accept = "\u{F05E0}", -- md-check_circle
  deny = "\u{F0159}", -- md-close_circle
  resume = "\u{F040D}", -- md-play_circle_outline
  continue = "\u{F02DA}", -- md-history
  model = "\u{F09D1}", -- md-brain
  robot = "\u{F167A}", -- md-robot_outline
  focus = "\u{F02F1}", -- md-image_filter_center_focus
}

-- lazy.nvim's own interface, one entry per key of its ui.icons table.
M.lazy = {
  cmd = "\u{F07B7}", -- md-console_line
  config = "\u{F0493}", -- md-cog
  debug = "\u{F00E4}", -- md-bug
  event = "\u{F140B}", -- md-lightning_bolt
  favorite = "\u{F04CE}", -- md-star
  ft = "\u{F0219}", -- md-file_document
  init = "\u{F0425}", -- md-power
  import = "\u{F02FA}", -- md-import
  keys = "\u{F030C}", -- md-keyboard
  lazy = "\u{F04B2}", -- md-sleep
  loaded = "\u{F012F}", -- md-checkbox_blank_circle
  not_loaded = "\u{F0130}", -- md-checkbox_blank_circle_outline
  plugin = "\u{F0431}", -- md-puzzle
  runtime = "\u{E62B}", -- custom-vim
  require = "\u{F08B1}", -- md-language_lua
  source = "\u{F022E}", -- md-file_code
  start = "\u{F14DE}", -- md-rocket_launch
  task = "\u{F0E1E}", -- md-check_bold
}

-- Mason's package states.
M.mason = {
  mason = "\u{F03D7}", -- md-package_variant_closed
  installed = "\u{F05E0}", -- md-check_circle
  pending = "\u{F0996}", -- md-progress_clock
  uninstalled = "\u{F015A}", -- md-close_circle_outline
}

-- todo-comments keywords.
M.todo = {
  FIX = "\u{F00E4}", -- md-bug
  TODO = "\u{F0134}", -- md-checkbox_marked_circle_outline
  HACK = "\u{F0238}", -- md-fire
  WARN = "\u{F0026}", -- md-alert
  PERF = "\u{F04C5}", -- md-speedometer
  NOTE = "\u{F11D7}", -- md-note_text_outline
  TEST = "\u{F0668}", -- md-test_tube
}

-- The debugger: its sign-column marks (capitalised, as nvim-dap names them) and
-- its controls.
M.dap = {
  debug = "\u{F00E4}", -- md-bug
  Stopped = "\u{F0055}", -- md-arrow_right_thick
  Breakpoint = "\u{F111}", -- fa-circle
  BreakpointCondition = "\u{F059}", -- fa-question_circle
  BreakpointRejected = "\u{F06A}", -- fa-exclamation_circle
  LogPoint = "\u{F036A}", -- md-message_text_outline
  continue = "\u{F040C}", -- md-play_circle
  step_over = "\u{F01B7}", -- md-debug_step_over
  step_into = "\u{F01B9}", -- md-debug_step_into
  step_out = "\u{F01B8}", -- md-debug_step_out
  run_to_cursor = "\u{F0CFE}", -- md-cursor_default_click_outline
  run_last = "\u{F02DA}", -- md-history
  restart = "\u{F0709}", -- md-restart
  terminate = "\u{F0666}", -- md-stop_circle
  pause = "\u{F03E5}", -- md-pause_circle
  repl = "\u{F07B7}", -- md-console_line
  eval = "\u{F0A9A}", -- md-calculator_variant
  widgets = "\u{F072C}", -- md-widgets
  ui = "\u{F0675}", -- md-application_cog
  frame_up = "\u{F0060}", -- md-arrow_up_bold_circle_outline
  frame_down = "\u{F0048}", -- md-arrow_down_bold_circle_outline
}

-- Chips, logic gates and signals, for the hardware languages.
M.hardware = {
  chip = "\u{EC19}", -- cod-chip
  microchip = "\u{F2DB}", -- fa-microchip
  fae_chip = "\u{E266}", -- fae-chip
  cpu = "\u{F0EE0}", -- md-cpu_64_bit
  cpu32 = "\u{F0EDF}", -- md-cpu_32_bit
  cpu_oct = "\u{F4BC}", -- oct-cpu
  memory = "\u{F035B}", -- md-memory
  fa_memory = "\u{EFC5}", -- fa-memory
  ic = "\u{F1913}", -- md-integrated_circuit_chip
  board = "\u{F0697}", -- md-developer_board
  circuit = "\u{EABE}", -- cod-circuit_board
  expansion = "\u{F08AE}", -- md-expansion_card
  waveform = "\u{F147D}", -- md-waveform
  sine = "\u{F095B}", -- md-sine_wave
  cosine = "\u{F1479}", -- md-cosine_wave
  square_wave = "\u{F147B}", -- md-square_wave
  resistor = "\u{F0B44}", -- md-resistor
  gate_and = "\u{F08E1}", -- md-gate_and
  gate_or = "\u{F08E5}", -- md-gate_or
  gate_not = "\u{F08E4}", -- md-gate_not
  gate_nand = "\u{F08E2}", -- md-gate_nand
  gate_nor = "\u{F08E3}", -- md-gate_nor
  gate_xor = "\u{F08E7}", -- md-gate_xor
  gate_xnor = "\u{F08E6}", -- md-gate_xnor
  serial = "\u{F065C}", -- md-serial_port
  ethernet = "\u{F0200}", -- md-ethernet
  usb = "\u{F0553}", -- md-usb
  sd = "\u{F0479}", -- md-sd
  flash = "\u{F0241}", -- md-flash
  lightning = "\u{F140B}", -- md-lightning_bolt
  power = "\u{F06A5}", -- md-power_plug
  clock = "\u{F0E97}", -- md-clock_digital
  sigma = "\u{F04A0}", -- md-sigma
  lambda = "\u{F0627}", -- md-lambda
  ["function"] = "\u{F0295}", -- md-function
  function_variant = "\u{F0871}", -- md-function_variant
  variable = "\u{F0AE7}", -- md-variable
  symbol_variable = "\u{EA88}", -- cod-symbol_variable
  timer = "\u{F051F}", -- md-timer_sand
  constraint = "\u{F0EBE}", -- md-ruler_square_compass
  netlist = "\u{F104A}", -- md-graph_outline
  oscilloscope = "\u{F0C50}", -- md-chart_bell_curve
}

-- Languages and tools.
M.lang = {
  python = "\u{F0320}", -- md-language_python
  lua = "\u{F08B1}", -- md-language_lua
  rust = "\u{F1617}", -- md-language_rust
  go = "\u{F07D3}", -- md-language_go
  c = "\u{F0671}", -- md-language_c
  cpp = "\u{F0672}", -- md-language_cpp
  csharp = "\u{F031B}", -- md-language_csharp
  java = "\u{F0B37}", -- md-language_java
  javascript = "\u{F031E}", -- md-language_javascript
  typescript = "\u{F06E6}", -- md-language_typescript
  haskell = "\u{F0C92}", -- md-language_haskell
  ruby = "\u{F0D2D}", -- md-language_ruby
  swift = "\u{F06E5}", -- md-language_swift
  kotlin = "\u{F1219}", -- md-language_kotlin
  r = "\u{F07D4}", -- md-language_r
  php = "\u{F031F}", -- md-language_php
  fortran = "\u{F121A}", -- md-language_fortran
  html = "\u{F031D}", -- md-language_html5
  css = "\u{F031C}", -- md-language_css3
  markdown = "\u{F0354}", -- md-language_markdown
  markdown_outline = "\u{F0F5B}", -- md-language_markdown_outline
  latex = "\u{E69B}", -- seti-tex
  docker = "\u{F0868}", -- md-docker
  nix = "\u{F1105}", -- md-nix
  react = "\u{E7BA}", -- dev-react
  clojure = "\u{E768}", -- dev-clojure
  ocaml = "\u{E67A}", -- seti-ocaml
  gotmpl = "\u{E627}", -- seti-go
  shader = "\u{F0B84}", -- md-cube_scan
  terraform = "\u{F1062}", -- md-terraform
  json = "\u{F0626}", -- md-code_json
  yaml = "\u{F016A}", -- md-code_brackets
  toml = "\u{F08BB}", -- md-cog_outline
  sql = "\u{F0866}", -- md-database_search
  script = "\u{F0BC2}", -- md-script_text
  beer = "\u{F0098}", -- md-beer
  gavel = "\u{F029B}", -- md-gavel
}

-- Symbol and completion kinds: every kind the language server protocol names,
-- and kinds for hardware description languages and Claude.
M.kinds = {
  Array = "\u{F016A}", -- md-code_brackets
  Boolean = "\u{F0A1A}", -- md-toggle_switch_outline
  Class = "\u{EB5B}", -- cod-symbol_class
  Color = "\u{F03D8}", -- md-palette
  Constant = "\u{EB5D}", -- cod-symbol_constant
  Constructor = "\u{F1323}", -- md-hammer_wrench
  Enum = "\u{EA95}", -- cod-symbol_enum
  EnumMember = "\u{EB5E}", -- cod-symbol_enum_member
  Event = "\u{EA86}", -- cod-symbol_event
  Field = "\u{EB5F}", -- cod-symbol_field
  File = "\u{F0224}", -- md-file_outline
  Folder = "\u{F0256}", -- md-folder_outline
  Function = "\u{F0295}", -- md-function
  Interface = "\u{EB61}", -- cod-symbol_interface
  Key = "\u{EA93}", -- cod-symbol_key
  Keyword = "\u{EB62}", -- cod-symbol_keyword
  Method = "\u{EA8C}", -- cod-symbol_method
  Module = "\u{F01A7}", -- md-cube_outline
  Namespace = "\u{EA8B}", -- cod-symbol_namespace
  Null = "\u{F07E2}", -- md-null
  Number = "\u{F03A0}", -- md-numeric
  Object = "\u{F0169}", -- md-code_braces
  Operator = "\u{EB64}", -- cod-symbol_operator
  Package = "\u{F03D7}", -- md-package_variant_closed
  Property = "\u{EB65}", -- cod-symbol_property
  Reference = "\u{EB36}", -- cod-references
  Snippet = "\u{EB66}", -- cod-symbol_snippet
  String = "\u{EB8D}", -- cod-symbol_string
  Struct = "\u{EA91}", -- cod-symbol_structure
  Text = "\u{F0284}", -- md-format_text
  TypeParameter = "\u{F0C24}", -- md-alpha_t_box_outline
  Unit = "\u{EA96}", -- cod-symbol_ruler
  Value = "\u{EA90}", -- cod-symbol_numeric
  Variable = "\u{EA88}", -- cod-symbol_variable
  Control = "\u{F062E}", -- md-tune
  Collapsed = "\u{F0704}", -- md-plus_box_outline
  Claude = "\u{2726}", -- U+2726 black four pointed star
  Macro = "\u{F0423}", -- md-pound
  Parameter = "\u{EA92}", -- cod-symbol_parameter
  Label = "\u{F0316}", -- md-label_outline
  Type = "\u{F0C24}", -- md-alpha_t_box_outline
  TypeAlias = "\u{F0C26}", -- md-alpha_t_circle_outline
  Decorator = "\u{F0065}", -- md-at
  Attribute = "\u{F04FC}", -- md-tag_outline
  Trait = "\u{F0A66}", -- md-puzzle_outline
  Union = "\u{F0778}", -- md-set_all
  Component = "\u{F1355}", -- md-widgets_outline
  Heading = "\u{F0274}", -- md-format_header_pound
  Link = "\u{F0339}", -- md-link_variant
  Regex = "\u{F0451}", -- md-regex
  StaticMethod = "\u{F0871}", -- md-function_variant
  Signal = "\u{F095B}", -- md-sine_wave
  Wire = "\u{F055E}", -- md-vector_line
  Port = "\u{F065C}", -- md-serial_port
  Register = "\u{F035B}", -- md-memory
  Clock = "\u{F147B}", -- md-square_wave
  Reset = "\u{F0901}", -- md-power_cycle
  Instance = "\u{EC19}", -- cod-chip
  Assertion = "\u{F0CC8}", -- md-shield_check_outline
  Coverage = "\u{F07AF}", -- md-chart_donut
  Task = "\u{F0756}", -- md-format_list_checks
  Process = "\u{F08D6}", -- md-cogs
  Sequence = "\u{F0BD2}", -- md-timeline_outline
}

-- The dashboard's buttons.
M.dashboard = {
  find_file = "\u{F002}", -- fa-search
  recent = "\u{F1DA}", -- fa-history
  projects = "\u{F07C}", -- fa-folder_open
  search_text = "\u{F13B8}", -- md-text_search
  config = "\u{F013}", -- fa-cog
  plugins = "\u{F04B2}", -- md-sleep
  language_tools = "\u{F1064}", -- md-tools
  quit = "\u{F0425}", -- md-power
  notes = "\u{F082E}", -- md-notebook
  tip = "\u{F0EB}", -- fa-lightbulb
}

-- The status bar. None of these may be an arrow, chevron, angle or triangle;
-- tests/test_icons.lua checks each against lua/ach/glyphs_forbidden.lua.
M.status = {
  vim = "\u{E62B}", -- custom-vim
  branch = "\u{E725}", -- dev-git_branch
  added = "\u{F0FE}", -- fa-plus_square
  modified = "\u{F14B}", -- fa-pencil_square
  removed = "\u{F146}", -- fa-minus_square
  project = "\u{F07C}", -- fa-folder_open
  unsaved = "\u{25CF}", -- U+25CF black circle
  readonly = "\u{F023}", -- fa-lock
  error = "\u{F057}", -- fa-times_circle
  warn = "\u{F071}", -- fa-warning
  info = "\u{F05A}", -- fa-info_circle
  hint = "\u{F0EB}", -- fa-lightbulb
  lsp = "\u{F085}", -- fa-cogs
  formatter = "\u{F027C}", -- md-format_paint
  linter = "\u{F00E2}", -- md-broom
  words = "\u{F022D}", -- md-file_word_box
  indent = "\u{F1050}", -- md-keyboard_space
  claude = "\u{2726}", -- U+2726 black four pointed star
  recording = "\u{25CF}", -- U+25CF black circle
  search = "\u{F002}", -- fa-search
  selection = "\u{F246}", -- fa-i_cursor
  updates = "\u{F03D6}", -- md-package_variant
  dap = "\u{F188}", -- fa-bug
}

-- lazy.nvim's list bullets, one per nesting depth in its debug view. Its own
-- second bullet is an arrow, which this set swaps for an open circle.
M.lazy_list = { "\u{25CF}", "\u{25CB}", "\u{2605}", "\u{2012}" }

-- Every key description this configuration, Neovim and which-key show, with the
-- glyph and colour which-key draws beside it. which-key compares descriptions in
-- lower case, so two that differ only in case must share an icon.
M.keys = {
  -- Keys this configuration sets: windows, buffers and lines
  ["Close Window"] = { "windows.close", "blue" },
  ["Down"] = { "nav.down", "azure" },
  ["Up"] = { "nav.up", "azure" },
  ["Go to Left Window"] = { "windows.go_left", "blue" },
  ["Go to Lower Window"] = { "windows.go_down", "blue" },
  ["Go to Upper Window"] = { "windows.go_up", "blue" },
  ["Go to Right Window"] = { "windows.go_right", "blue" },
  ["Increase Window Height"] = { "windows.height_inc", "blue" },
  ["Decrease Window Height"] = { "windows.height_dec", "blue" },
  ["Decrease Window Width"] = { "windows.width_dec", "blue" },
  ["Increase Window Width"] = { "windows.width_inc", "blue" },
  ["Split Window Below"] = { "windows.split_below", "blue" },
  ["Split Window Right"] = { "windows.split_right", "blue" },
  ["Delete Window"] = { "windows.close", "red" },
  ["Move Down"] = { "edit.move_down", "yellow" },
  ["Move Up"] = { "edit.move_up", "yellow" },
  ["Prev Buffer"] = { "buffers.buffer", "cyan" },
  ["Next Buffer"] = { "buffers.buffer", "cyan" },
  ["Switch to Other Buffer"] = { "buffers.alternate", "cyan" },
  ["Delete Buffer"] = { "buffers.delete", "red" },
  ["Delete Other Buffers"] = { "buffers.delete_others", "red" },
  ["Delete Buffer and Window"] = { "buffers.delete_window", "red" },
  ["Escape and Clear hlsearch"] = { "ui.escape", "grey" },
  ["Redraw / Clear hlsearch"] = { "ui.redraw", "cyan" },
  ["Next Search Result"] = { "search.next", "green" },
  ["Prev Search Result"] = { "search.prev", "green" },
  ["Save File"] = { "actions.save", "green" },
  ["New File"] = { "files.new", "cyan" },
  ["Copy File Path"] = { "files.copy_path", "cyan" },
  ["Indent Left"] = { "edit.outdent", "yellow" },
  ["Indent Right"] = { "edit.indent", "yellow" },
  ["Add Comment Below"] = { "code.comment_add", "azure" },
  ["Add Comment Above"] = { "code.comment_add", "azure" },
  ["Location List"] = { "lists.location", "azure" },
  ["Quickfix List"] = { "lists.quickfix", "azure" },
  ["Line Diagnostics"] = { "diagnostics.line", "green" },
  ["Next Diagnostic"] = { "diagnostics.jump", "green" },
  ["Prev Diagnostic"] = { "diagnostics.jump", "green" },
  ["Next Error"] = { "diagnostics.Error", "red" },
  ["Prev Error"] = { "diagnostics.Error", "red" },
  ["Next Warning"] = { "diagnostics.Warn", "yellow" },
  ["Prev Warning"] = { "diagnostics.Warn", "yellow" },
  ["Undo Tree"] = { "edit.undo_tree", "yellow" },
  ["Inspect Pos"] = { "code.inspect", "cyan" },
  ["Inspect Tree"] = { "code.treesitter", "green" },
  ["Terminal (cwd)"] = { "terminal.cwd", "red" },
  ["Terminal (Root Dir)"] = { "terminal.root", "red" },
  ["New Tab"] = { "tabs.new", "purple" },
  ["Next Tab"] = { "tabs.next", "purple" },
  ["Previous Tab"] = { "tabs.prev", "purple" },
  ["Close Tab"] = { "tabs.close", "red" },
  ["Close Other Tabs"] = { "tabs.close_others", "red" },
  ["First Tab"] = { "tabs.first", "purple" },
  ["Last Tab"] = { "tabs.last", "purple" },
  ["Quit All"] = { "actions.quit", "red" },
  ["Lazy"] = { "lazy.lazy", "blue" },
  ["Buffer Keymaps (which-key)"] = { "search.buffer_keymaps", "cyan" },
  ["Window Hydra Mode (which-key)"] = { "windows.hydra", "blue" },
  -- Keys this configuration sets: pickers
  ["Find Files (Root Dir)"] = { "search.files", "green" },
  ["Buffers"] = { "buffers.list", "cyan" },
  ["Grep (Root Dir)"] = { "search.grep", "green" },
  ["Command History"] = { "search.command_history", "green" },
  ["Notification History"] = { "search.notifications", "blue" },
  ["Find Config File"] = { "search.config", "green" },
  ["Find Files (cwd)"] = { "search.files_cwd", "green" },
  ["Find Files (git-files)"] = { "search.git_files", "orange" },
  ["Projects"] = { "search.projects", "azure" },
  ["Recent"] = { "search.recent", "green" },
  ["Recent (cwd)"] = { "search.recent", "green" },
  ["Registers"] = { "search.registers", "yellow" },
  ["Search History"] = { "search.search_history", "green" },
  ["Autocmds"] = { "search.autocmds", "green" },
  ["Buffer Lines"] = { "search.lines", "green" },
  ["Grep Open Buffers"] = { "search.grep_buffers", "green" },
  ["Commands"] = { "search.commands", "green" },
  ["Diagnostics"] = { "diagnostics.list", "green" },
  ["Buffer Diagnostics"] = { "diagnostics.buffer", "green" },
  ["Grep (cwd)"] = { "search.grep", "green" },
  ["Help Pages"] = { "search.help", "green" },
  ["Highlights"] = { "search.highlights", "green" },
  ["Icons"] = { "search.icons", "yellow" },
  ["Jumps"] = { "search.jumps", "green" },
  ["Keymaps"] = { "search.keymaps", "green" },
  ["Marks"] = { "search.marks", "green" },
  ["Man Pages"] = { "search.man", "green" },
  ["Search for Plugin Spec"] = { "search.plugin_spec", "green" },
  ["Resume"] = { "search.resume", "green" },
  ["Undo History"] = { "search.undo", "green" },
  ["Selection or Word (Root Dir)"] = { "search.word", "green" },
  ["Selection or Word (cwd)"] = { "search.word", "green" },
  -- Keys this configuration sets: editor plugins
  ["Flash Jump"] = { "nav.flash", "yellow" },
  ["Flash Select by Syntax"] = { "nav.flash_select", "yellow" },
  ["Flash Remote"] = { "nav.flash_remote", "yellow" },
  ["Flash Search by Syntax"] = { "nav.flash_search", "yellow" },
  ["Toggle Flash in Search"] = { "nav.flash_auto", "yellow" },
  ["Grow Selection by Syntax"] = { "code.grow_selection", "purple" },
  ["Search and Replace"] = { "search.replace", "blue" },
  ["Problems (Trouble)"] = { "diagnostics.list", "green" },
  ["Problems in This Buffer (Trouble)"] = { "diagnostics.buffer", "green" },
  ["Symbols (Trouble)"] = { "code.symbols", "purple" },
  ["Definitions and References (Trouble)"] = { "code.references", "purple" },
  ["Location List (Trouble)"] = { "lists.location", "azure" },
  ["Quickfix List (Trouble)"] = { "lists.quickfix", "azure" },
  ["Previous Problem or Quickfix Entry"] = { "lists.quickfix", "azure" },
  ["Next Problem or Quickfix Entry"] = { "lists.quickfix", "azure" },
  ["Next TODO Comment"] = { "todo.TODO", "yellow" },
  ["Previous TODO Comment"] = { "todo.TODO", "yellow" },
  ["TODO Comments (Trouble)"] = { "todo.TODO", "yellow" },
  ["TODO and FIX Comments (Trouble)"] = { "search.todo_fix", "yellow" },
  ["TODO Comments"] = { "todo.TODO", "yellow" },
  ["TODO and FIX Comments"] = { "search.todo_fix", "yellow" },
  ["Open Folder as Text (oil)"] = { "files.folder_edit", "cyan" },
  ["Restore Session for This Folder"] = { "session.restore", "azure" },
  ["Pick a Session"] = { "session.pick", "azure" },
  ["Restore Last Session"] = { "session.last", "azure" },
  ["Don't Save This Session"] = { "session.stop", "red" },
  ["Previous Cursor"] = { "multicursor.cursor", "purple" },
  ["Next Cursor"] = { "multicursor.cursor", "purple" },
  ["Delete This Cursor"] = { "multicursor.delete", "red" },
  ["Clear Cursors"] = { "multicursor.clear", "purple" },
  ["Add Cursor at Next Match"] = { "multicursor.add_match", "purple" },
  ["Add Cursor at Previous Match"] = { "multicursor.add_match", "purple" },
  ["Skip to Next Match"] = { "multicursor.skip", "purple" },
  ["Skip to Previous Match"] = { "multicursor.skip", "purple" },
  ["Add Cursors at Every Match"] = { "multicursor.all", "purple" },
  ["Add or Remove a Cursor Here"] = { "multicursor.toggle", "purple" },
  ["Align Cursors"] = { "multicursor.align", "purple" },
  ["Add Cursor Above"] = { "multicursor.above", "purple" },
  ["Add Cursor Below"] = { "multicursor.below", "purple" },
  ["File Tree (project)"] = { "files.tree", "cyan" },
  ["File Tree (working folder)"] = { "files.tree_outline", "cyan" },
  ["Toggle Docked Panes"] = { "windows.dock", "blue" },
  ["Pick a Docked Pane"] = { "windows.dock_pick", "blue" },
  -- Neovim's own keys
  [":blast"] = { "buffers.buffer", "cyan" },
  [":bnext"] = { "buffers.buffer", "cyan" },
  [":bprevious"] = { "buffers.buffer", "cyan" },
  [":brewind"] = { "buffers.buffer", "cyan" },
  [":clast"] = { "lists.quickfix", "azure" },
  [":cnext"] = { "lists.quickfix", "azure" },
  [":cnfile"] = { "lists.quickfix", "azure" },
  [":cpfile"] = { "lists.quickfix", "azure" },
  [":cprevious"] = { "lists.quickfix", "azure" },
  [":crewind"] = { "lists.quickfix", "azure" },
  [":llast"] = { "lists.location", "azure" },
  [":lnext"] = { "lists.location", "azure" },
  [":lnfile"] = { "lists.location", "azure" },
  [":lpfile"] = { "lists.location", "azure" },
  [":lprevious"] = { "lists.location", "azure" },
  [":lrewind"] = { "lists.location", "azure" },
  [":last"] = { "lists.args", "azure" },
  [":next"] = { "lists.args", "azure" },
  [":previous"] = { "lists.args", "azure" },
  [":rewind"] = { "lists.args", "azure" },
  [":ptnext"] = { "code.tag_preview", "purple" },
  [":ptprevious"] = { "code.tag_preview", "purple" },
  [":tlast"] = { "code.tag", "purple" },
  [":tnext"] = { "code.tag", "purple" },
  [":tprevious"] = { "code.tag", "purple" },
  [":trewind"] = { "code.tag", "purple" },
  [":help &-default"] = { "edit.repeat_sub", "yellow" },
  [":help CTRL-L-default"] = { "ui.redraw", "cyan" },
  [":help Y-default"] = { "edit.yank", "green" },
  [":help i_CTRL-U-default"] = { "edit.delete_line", "red" },
  [":help i_CTRL-W-default"] = { "edit.delete_word", "red" },
  [":help v_#-default"] = { "search.word", "green" },
  [":help v_star-default"] = { "search.word", "green" },
  [":help v_@-default"] = { "edit.macro", "red" },
  [":help v_Q-default"] = { "edit.macro_repeat", "red" },
  ["Add empty line above cursor"] = { "edit.line_above", "yellow" },
  ["Add empty line below cursor"] = { "edit.line_below", "yellow" },
  ["Comment textobject"] = { "code.comment", "azure" },
  ["Toggle comment"] = { "code.comment", "azure" },
  ["Toggle comment line"] = { "code.comment_line", "azure" },
  ["Jump to the first diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the last diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the next diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Jump to the previous diagnostic in the current buffer"] = { "diagnostics.jump", "green" },
  ["Show diagnostics under the cursor"] = { "diagnostics.line", "green" },
  ["Select parent (outer) node"] = { "code.node_parent", "green" },
  ["Select child (inner) node"] = { "code.node_child", "green" },
  ["Select next node"] = { "code.node_next", "green" },
  ["Select previous node"] = { "code.node_prev", "green" },
  ["Select next sibling node"] = { "code.node_sibling", "green" },
  ["Select previous sibling node"] = { "code.node_sibling", "green" },
  ["vim.lsp.buf.code_action()"] = { "code.action", "purple" },
  ["vim.lsp.buf.document_symbol()"] = { "code.symbols", "purple" },
  ["vim.lsp.buf.implementation()"] = { "code.implementation", "purple" },
  ["vim.lsp.buf.references()"] = { "code.references", "purple" },
  ["vim.lsp.buf.rename()"] = { "code.rename", "purple" },
  ["vim.lsp.buf.signature_help()"] = { "code.signature", "purple" },
  ["vim.lsp.buf.type_definition()"] = { "code.type_definition", "purple" },
  ["vim.lsp.codelens.run()"] = { "code.codelens", "purple" },
  ["vim.snippet.jump if active, otherwise <Tab>"] = { "code.snippet", "purple" },
  ["vim.snippet.jump if active, otherwise <S-Tab>"] = { "code.snippet", "purple" },
  ["Opens filepath or URI under cursor with the system handler (file explorer, web browser, …)"] = {
    "actions.open_external",
    "blue",
  },
  -- which-key's built-in descriptions: operators
  ["Change"] = { "edit.change", "yellow" },
  ["Delete"] = { "edit.delete", "red" },
  ["Yank"] = { "edit.yank", "green" },
  ["Replace"] = { "edit.replace", "yellow" },
  ["Format"] = { "edit.format", "yellow" },
  ["Indent left"] = { "edit.outdent", "yellow" },
  ["Indent right"] = { "edit.indent", "yellow" },
  ["Uppercase"] = { "edit.upper", "yellow" },
  ["Lowercase"] = { "edit.lower", "yellow" },
  ["Toggle case"] = { "edit.case", "yellow" },
  ["Visual"] = { "edit.visual", "yellow" },
  ["Visual Line"] = { "edit.visual_line", "yellow" },
  ["Create fold"] = { "fold.create", "blue" },
  ["Run program"] = { "terminal.run", "red" },
  -- which-key's built-in descriptions: motions
  ["Left"] = { "nav.left", "azure" },
  ["Right"] = { "nav.right", "azure" },
  ["End of line"] = { "nav.line_end", "azure" },
  ["Start of line"] = { "nav.line_start", "azure" },
  ["Start of line (non ws)"] = { "nav.line_first_char", "azure" },
  ["First line"] = { "nav.first_line", "azure" },
  ["Last line"] = { "nav.last_line", "azure" },
  ["Matching (){}[]"] = { "nav.match", "azure" },
  ["Move to next char"] = { "nav.char", "azure" },
  ["Move to prev char"] = { "nav.char", "azure" },
  ["Move before next char"] = { "nav.char", "azure" },
  ["Move before prev char"] = { "nav.char", "azure" },
  ["Next ftFT"] = { "nav.char_repeat", "azure" },
  ["Prev ftFT"] = { "nav.char_repeat", "azure" },
  ["Next word"] = { "nav.word", "azure" },
  ["Prev word"] = { "nav.word", "azure" },
  ["Next WORD"] = { "nav.word", "azure" },
  ["Prev WORD"] = { "nav.word", "azure" },
  ["Next end of word"] = { "nav.word_end", "azure" },
  ["Prev end of word"] = { "nav.word_end", "azure" },
  ["Next end of WORD"] = { "nav.word_end", "azure" },
  ["Next empty line"] = { "nav.paragraph", "azure" },
  ["Prev empty line"] = { "nav.paragraph", "azure" },
  ["Search forward"] = { "search.forward", "green" },
  ["Search backward"] = { "search.backward", "green" },
  -- which-key's built-in descriptions: text objects
  ["around"] = { "textobj.around", "cyan" },
  ["inside"] = { "textobj.inside", "cyan" },
  ["' string"] = { "textobj.string", "cyan" },
  ['" string'] = { "textobj.string", "cyan" },
  ["` string"] = { "textobj.string", "cyan" },
  ["inner ' string"] = { "textobj.string", "cyan" },
  ['inner " string'] = { "textobj.string", "cyan" },
  ["inner ` string"] = { "textobj.string", "cyan" },
  ["<> block"] = { "textobj.angle", "cyan" },
  ["inner <>"] = { "textobj.angle", "cyan" },
  ["[(]) block"] = { "textobj.parens", "cyan" },
  ["inner [(])"] = { "textobj.parens", "cyan" },
  ["[] block"] = { "textobj.brackets", "cyan" },
  ["inner []"] = { "textobj.brackets", "cyan" },
  ["[{]} block"] = { "textobj.braces", "cyan" },
  ["inner [{]}"] = { "textobj.braces", "cyan" },
  ["word with ws"] = { "textobj.word", "cyan" },
  ["WORD with ws"] = { "textobj.word", "cyan" },
  ["inner word"] = { "textobj.word", "cyan" },
  ["inner WORD"] = { "textobj.word", "cyan" },
  ["paragraph"] = { "textobj.paragraph", "cyan" },
  ["inner paragraph"] = { "textobj.paragraph", "cyan" },
  ["sentence"] = { "textobj.sentence", "cyan" },
  ["inner sentence"] = { "textobj.sentence", "cyan" },
  ["tag block"] = { "textobj.tag", "cyan" },
  ["inner tag block"] = { "textobj.tag", "cyan" },
  -- which-key's built-in descriptions: windows
  ["window"] = { "windows.window", "blue" },
  ["Go to the left window"] = { "windows.go_left", "blue" },
  ["Go to the down window"] = { "windows.go_down", "blue" },
  ["Go to the up window"] = { "windows.go_up", "blue" },
  ["Go to the right window"] = { "windows.go_right", "blue" },
  ["Move window to far left"] = { "windows.far_left", "blue" },
  ["Move window to far bottom"] = { "windows.far_bottom", "blue" },
  ["Move window to far top"] = { "windows.far_top", "blue" },
  ["Move window to far right"] = { "windows.far_right", "blue" },
  ["Increase height"] = { "windows.height_inc", "blue" },
  ["Decrease height"] = { "windows.height_dec", "blue" },
  ["Increase width"] = { "windows.width_inc", "blue" },
  ["Decrease width"] = { "windows.width_dec", "blue" },
  ["Max out the height"] = { "windows.max_height", "blue" },
  ["Max out the width"] = { "windows.max_width", "blue" },
  ["Equally high and wide"] = { "windows.equalize", "blue" },
  ["Split window"] = { "windows.split_below", "blue" },
  ["Split window vertically"] = { "windows.split_right", "blue" },
  ["Close all other windows"] = { "windows.only", "blue" },
  ["Quit a window"] = { "windows.close", "red" },
  ["Swap current with next"] = { "windows.swap", "blue" },
  ["Switch windows"] = { "windows.switch", "blue" },
  ["Break out into a new tab"] = { "windows.to_tab", "blue" },
  -- which-key's built-in descriptions: folds, spelling and scrolling
  ["Close all folds"] = { "fold.close", "blue" },
  ["Close all folds under cursor"] = { "fold.close", "blue" },
  ["Close fold under cursor"] = { "fold.close", "blue" },
  ["Open all folds"] = { "fold.open", "blue" },
  ["Open all folds under cursor"] = { "fold.open", "blue" },
  ["Open fold under cursor"] = { "fold.open", "blue" },
  ["Toggle all folds under cursor"] = { "fold.toggle", "blue" },
  ["Toggle fold under cursor"] = { "fold.toggle", "blue" },
  ["Toggle folding"] = { "fold.toggle", "blue" },
  ["Delete all folds in file"] = { "fold.delete", "red" },
  ["Delete all folds under cursor"] = { "fold.delete", "red" },
  ["Delete fold under cursor"] = { "fold.delete", "red" },
  ["Fold more"] = { "fold.close", "blue" },
  ["Fold less"] = { "fold.open", "blue" },
  ["Update folds"] = { "fold.update", "blue" },
  ["Add word to spell list"] = { "spell.add", "yellow" },
  ["Mark word as bad/misspelling"] = { "spell.bad", "red" },
  ["Spelling suggestions"] = { "spell.suggest", "yellow" },
  ["Next misspelled word"] = { "spell.spell", "yellow" },
  ["Previous misspelled word"] = { "spell.spell", "yellow" },
  ["Top this line"] = { "nav.view_top", "azure" },
  ["Center this line"] = { "nav.view_center", "azure" },
  ["Bottom this line"] = { "nav.view_bottom", "azure" },
  ["Left this line"] = { "nav.view_left", "azure" },
  ["Right this line"] = { "nav.view_right", "azure" },
  ["Half screen to the left"] = { "nav.pan_left", "azure" },
  ["Half screen to the right"] = { "nav.pan_right", "azure" },
  ["Show cursor line"] = { "ui.cursorline", "cyan" },
  -- which-key's built-in descriptions: brackets and window lines
  ["Home line of window (top)"] = { "nav.window_top", "azure" },
  ["Middle line of window"] = { "nav.window_middle", "azure" },
  ["Last line of window"] = { "nav.window_bottom", "azure" },
  ["Next ("] = { "nav.paren", "azure" },
  ["Previous ("] = { "nav.paren", "azure" },
  ["Next <"] = { "nav.angle", "azure" },
  ["Previous <"] = { "nav.angle", "azure" },
  ["Next {"] = { "nav.brace", "azure" },
  ["Previous {"] = { "nav.brace", "azure" },
  ["Next unmatched group"] = { "nav.paren", "azure" },
  ["Previous unmatched group"] = { "nav.paren", "azure" },
  ["Next method start"] = { "kinds.Method", "purple" },
  ["Next method end"] = { "kinds.Method", "purple" },
  ["Previous method start"] = { "kinds.Method", "purple" },
  ["Previous method end"] = { "kinds.Method", "purple" },
  -- which-key's built-in descriptions: the g prefix
  ["Go to file under cursor"] = { "files.find", "cyan" },
  ["Go to last insert"] = { "nav.last_insert", "azure" },
  ["Go to next tab page"] = { "tabs.next", "purple" },
  ["Go to previous tab page"] = { "tabs.prev", "purple" },
  ["Go to [count] newer position in change list"] = { "nav.changes", "azure" },
  ["Go to [count] older position in change list"] = { "nav.changes", "azure" },
  ["Last visual selection"] = { "edit.visual_last", "yellow" },
  ["Open file with system app"] = { "actions.open_external", "blue" },
  ["Search forwards and select"] = { "search.forward", "green" },
  ["Search backwards and select"] = { "search.backward", "green" },
  ["Cycle backwards through results"] = { "search.prev", "green" },
  -- Text objects from mini.ai and Snacks scope
  ["Around textobject"] = { "textobj.around", "cyan" },
  ["Inside textobject"] = { "textobj.inside", "cyan" },
  ["Around next textobject"] = { "textobj.around", "cyan" },
  ["Around last textobject"] = { "textobj.around", "cyan" },
  ["Inside next textobject"] = { "textobj.inside", "cyan" },
  ["Inside last textobject"] = { "textobj.inside", "cyan" },
  ['Move to left "around"'] = { "textobj.around", "cyan" },
  ['Move to right "around"'] = { "textobj.around", "cyan" },
  ["inner scope"] = { "textobj.scope", "cyan" },
  ["full scope"] = { "textobj.scope", "cyan" },
  ["jump to top edge of scope"] = { "textobj.scope_top", "cyan" },
  ["jump to bottom edge of scope"] = { "textobj.scope_bottom", "cyan" },
  -- Tree-sitter moves
  ["Next Function Start"] = { "kinds.Function", "purple" },
  ["Next Function End"] = { "kinds.Function", "purple" },
  ["Prev Function Start"] = { "kinds.Function", "purple" },
  ["Prev Function End"] = { "kinds.Function", "purple" },
  ["Next Class Start"] = { "kinds.Class", "yellow" },
  ["Next Class End"] = { "kinds.Class", "yellow" },
  ["Prev Class Start"] = { "kinds.Class", "yellow" },
  ["Prev Class End"] = { "kinds.Class", "yellow" },
  ["Next Parameter Start"] = { "kinds.Parameter", "cyan" },
  ["Next Parameter End"] = { "kinds.Parameter", "cyan" },
  ["Prev Parameter Start"] = { "kinds.Parameter", "cyan" },
  ["Prev Parameter End"] = { "kinds.Parameter", "cyan" },
  ["Mason"] = { "mason.mason", "green" },
  ["Lsp Info"] = { "code.lsp", "purple" },
  ["Goto Definition"] = { "code.definition", "purple" },
  ["Goto Declaration"] = { "code.declaration", "purple" },
  ["References"] = { "code.references", "purple" },
  ["Goto Implementation"] = { "code.implementation", "purple" },
  ["Goto Type Definition"] = { "code.type_definition", "purple" },
  ["Incoming Calls"] = { "code.calls_in", "purple" },
  ["Outgoing Calls"] = { "code.calls_out", "purple" },
  ["Hover"] = { "code.hover", "purple" },
  ["Signature Help"] = { "code.signature", "purple" },
  ["Code Action"] = { "code.action", "purple" },
  ["Source Action"] = { "code.source_action", "purple" },
  ["Organize Imports"] = { "code.organize_imports", "purple" },
  ["Run Codelens"] = { "code.codelens", "purple" },
  ["Toggle Codelens"] = { "code.codelens", "purple" },
  ["Rename"] = { "code.rename", "purple" },
  ["Rename File"] = { "code.rename_file", "purple" },
  ["Next Reference"] = { "code.words", "purple" },
  ["Prev Reference"] = { "code.words", "purple" },
  ["LSP Symbols"] = { "code.symbols", "purple" },
  ["LSP Workspace Symbols"] = { "code.symbols", "purple" },
  ["vim.lsp.buf.hover()"] = { "code.hover", "purple" },
  ["Format Injected Langs"] = { "code.format", "purple" },
  ["Lean Infoview"] = { "windows.far_right", "blue" },
  ["Go to Infoview"] = { "windows.go_right", "blue" },
  ["Infoview Options"] = { "actions.tune", "blue" },
  ["Add Pin"] = { "actions.pin", "yellow" },
  ["Clear Pins"] = { "actions.unpin", "yellow" },
  ["Pause Pins"] = { "actions.pause", "yellow" },
  ["Set Diff Pin"] = { "git.diff", "purple" },
  ["Clear Diff Pins"] = { "actions.unpin", "purple" },
  ["Auto Diff"] = { "files.compare", "purple" },
  ["Auto Diff, Clearing Pins"] = { "files.compare", "purple" },
  ["Enable Widgets"] = { "dap.widgets", "cyan" },
  ["Disable Widgets"] = { "kinds.Component", "grey" },
  ["Accept Suggestion"] = { "code.action", "green" },
  ["How to Type This Symbol"] = { "search.keymaps", "cyan" },
  ["Restart Lean for This File"] = { "actions.restart", "red" },
  ["Toggle Breakpoint"] = { "dap.Breakpoint", "red" },
  ["Conditional Breakpoint"] = { "dap.BreakpointCondition", "yellow" },
  ["Log Point"] = { "dap.LogPoint", "cyan" },
  ["Start or Continue"] = { "dap.continue", "green" },
  ["Start with Arguments"] = { "dap.continue", "green" },
  ["Run to Cursor"] = { "dap.run_to_cursor", "green" },
  ["Jump to Line Without Running"] = { "dap.Stopped", "yellow" },
  ["Step Into"] = { "dap.step_into", "blue" },
  ["Step Over"] = { "dap.step_over", "blue" },
  ["Step Out"] = { "dap.step_out", "blue" },
  ["Frame Up"] = { "dap.frame_up", "azure" },
  ["Frame Down"] = { "dap.frame_down", "azure" },
  ["Rerun Last Debug"] = { "dap.run_last", "green" },
  ["Restart Debugging"] = { "dap.restart", "orange" },
  ["Pause Debugging"] = { "dap.pause", "yellow" },
  ["Stop Debugging"] = { "dap.terminate", "red" },
  ["Debug Console"] = { "dap.repl", "purple" },
  ["Debug Sessions"] = { "dap.debug", "red" },
  ["Inspect Value"] = { "dap.widgets", "cyan" },
  ["Evaluate Expression"] = { "dap.eval", "cyan" },
  ["Debug Interface"] = { "dap.ui", "purple" },
  ["Debug Nearest Test"] = { "dap.debug", "red" },
  ["Debug Test Class"] = { "dap.debug", "red" },
  -- Git: gitsigns' keys for one change at a time
  ["Next Hunk"] = { "git.hunk", "orange" },
  ["Prev Hunk"] = { "git.hunk", "orange" },
  ["Last Hunk"] = { "git.hunk", "orange" },
  ["First Hunk"] = { "git.hunk", "orange" },
  ["Stage or Unstage Hunk"] = { "git.hunk_stage", "orange" },
  ["Reset Hunk"] = { "git.hunk_reset", "orange" },
  ["Stage Buffer"] = { "git.staged", "orange" },
  ["Reset Buffer"] = { "git.hunk_reset", "orange" },
  ["Preview Hunk Inline"] = { "git.diff", "orange" },
  ["Blame Line"] = { "git.blame", "orange" },
  ["Blame Buffer"] = { "git.blame", "orange" },
  ["Diff This"] = { "git.diff", "orange" },
  ["Diff This ~"] = { "git.diff", "orange" },
  ["Select Hunk"] = { "textobj.inside", "cyan" },
  -- Git: lazygit, Neogit, diffview, octo and the snacks pickers
  ["Lazygit (Root Dir)"] = { "git.lazygit", "orange" },
  ["Lazygit (cwd)"] = { "git.lazygit", "orange" },
  ["Neogit (Root Dir)"] = { "git.git", "orange" },
  ["Diff View (Root Dir)"] = { "git.diff", "orange" },
  ["File History (Diff View)"] = { "git.log", "orange" },
  ["Git Status"] = { "git.modified", "orange" },
  ["Git Stash"] = { "git.stash", "orange" },
  ["Git Diff (hunks)"] = { "git.hunk", "orange" },
  ["Git Log (Root Dir)"] = { "git.log", "orange" },
  ["Git Log (cwd)"] = { "git.log", "orange" },
  ["Git File History"] = { "git.commit", "orange" },
  ["Git Line History"] = { "git.log", "orange" },
  ["Git Branches"] = { "git.branch", "orange" },
  ["Git Browse (open)"] = { "actions.open_external", "orange" },
  ["Git Browse (copy link)"] = { "actions.link", "orange" },
  ["GitHub Issues"] = { "git.issue", "orange" },
  ["GitHub Pull Requests"] = { "git.pull_request", "orange" },
  -- Claude Code
  ["Toggle Claude"] = { "claude.claude", "orange" },
  ["Focus Claude"] = { "claude.focus", "orange" },
  ["Resume Claude"] = { "claude.resume", "orange" },
  ["Continue Claude"] = { "claude.continue", "orange" },
  ["Select Claude Model"] = { "claude.model", "orange" },
  ["Add Buffer to Claude"] = { "claude.add_buffer", "orange" },
  ["Send to Claude"] = { "claude.send", "orange" },
  ["Add File to Claude"] = { "claude.add_file", "orange" },
  ["Accept Diff"] = { "claude.accept", "green" },
  ["Deny Diff"] = { "claude.deny", "red" },
  -- Keys added by later tasks go above this line.
}

-- which-key group names and their icons. The key spec passes these as each
-- group's icon, so a group never falls back to which-key's guess.
M.groups = {
  ["tabs"] = { "tabs.tab", "purple" },
  ["claude"] = { "claude.claude", "orange" },
  ["buffer"] = { "buffers.list", "cyan" },
  ["code"] = { "code.code", "purple" },
  ["debug"] = { "dap.debug", "red" },
  ["file/find"] = { "search.find", "green" },
  ["git"] = { "git.git", "orange" },
  ["hunks"] = { "git.hunk", "orange" },
  ["multicursor"] = { "multicursor.cursor", "purple" },
  ["quit/session"] = { "session.session", "azure" },
  ["search"] = { "search.search", "green" },
  ["toggles"] = { "ui.toggle", "cyan" },
  ["windows"] = { "windows.window", "blue" },
  ["diagnostics/quickfix"] = { "diagnostics.group", "green" },
  ["prev"] = { "nav.prev", "azure" },
  ["next"] = { "nav.next", "azure" },
  ["goto"] = { "nav.goto", "azure" },
  ["fold"] = { "fold.fold", "blue" },
  ["diff pins"] = { "git.diff", "purple" },
  -- Groups added by later tasks go above this line.
}

-- Snacks toggle ids and their icons. A toggle is drawn green when on and grey
-- when off, so the icon can say what it toggles rather than which way.
M.toggles = {
  autoformat = "code.autoformat",
  autoformat_buffer = "code.autoformat_buffer",
  spell = "spell.spell",
  wrap = "edit.wrap",
  relativenumber = "code.relative_numbers",
  line_number = "code.line_numbers",
  diagnostics = "diagnostics.group",
  conceallevel = "code.conceal",
  treesitter = "code.treesitter",
  inlay_hints = "code.inlay_hints",
  indent = "ui.indent_guides",
  dim = "ui.dim",
  zoom = "windows.zoom",
  zen = "ui.zen",
  words = "code.words",
  scroll = "ui.scroll",
  animate = "ui.animate",
  profiler = "ui.profiler",
  profiler_highlights = "ui.profiler_highlights",
  git_signs = "git.hunk",
  git_blame_line = "git.blame",
  -- Toggles added by later tasks go above this line.
}

-- A safety net for descriptions M.keys does not list, such as a key a plugin adds
-- after an update. Lua patterns, tried in order against the lower-cased description.
-- There is deliberately no catch-all: a description none of these match falls
-- through to which-key's own rules.
M.keywords = {
  { "claude", "claude.claude", "orange" },
  { "%f[%a]ai%f[%A]", "claude.ai", "orange" },
  { "breakpoint", "dap.Breakpoint", "red" },
  { "debug", "dap.debug", "red" },
  { "%f[%a]dap%f[%A]", "dap.debug", "red" },
  { "hunk", "git.hunk", "orange" },
  { "blame", "git.blame", "orange" },
  { "diff", "git.diff", "orange" },
  { "commit", "git.commit", "orange" },
  { "branch", "git.branch", "orange" },
  { "stash", "git.stash", "orange" },
  { "lazygit", "git.lazygit", "orange" },
  { "%f[%a]git", "git.git", "orange" },
  { "github", "git.github", "orange" },
  { "diagnostic", "diagnostics.jump", "green" },
  { "problem", "diagnostics.list", "green" },
  { "%f[%a]error", "diagnostics.Error", "red" },
  { "warning", "diagnostics.Warn", "yellow" },
  { "quickfix", "lists.quickfix", "azure" },
  { "location", "lists.location", "azure" },
  { "%f[%a]todo", "todo.TODO", "yellow" },
  { "test", "code.test", "purple" },
  { "terminal", "terminal.term", "red" },
  { "format", "code.format", "purple" },
  { "rename", "code.rename", "purple" },
  { "reference", "code.references", "purple" },
  { "definition", "code.definition", "purple" },
  { "declaration", "code.declaration", "purple" },
  { "implementation", "code.implementation", "purple" },
  { "symbol", "code.symbols", "purple" },
  { "code action", "code.action", "purple" },
  { "hover", "code.hover", "purple" },
  { "signature", "code.signature", "purple" },
  { "snippet", "code.snippet", "purple" },
  { "%f[%a]lsp", "code.lsp", "purple" },
  { "treesitter", "code.treesitter", "purple" },
  { "mason", "mason.mason", "green" },
  { "lazy", "lazy.lazy", "blue" },
  { "session", "session.session", "azure" },
  { "fold", "fold.fold", "blue" },
  { "spell", "spell.spell", "yellow" },
  { "cursor", "multicursor.cursor", "purple" },
  { "window", "windows.window", "blue" },
  { "%f[%a]tab%f[%A]", "tabs.tab", "purple" },
  { "buffer", "buffers.buffer", "cyan" },
  { "folder", "files.folder", "cyan" },
  { "director", "files.folder", "cyan" },
  { "grep", "search.grep", "green" },
  { "replace", "search.replace", "green" },
  { "find", "search.find", "green" },
  { "search", "search.search", "green" },
  { "file", "files.file", "cyan" },
  { "notif", "search.notifications", "blue" },
  { "help", "search.help", "green" },
  { "keymap", "search.keymaps", "green" },
  { "toggle", "ui.toggle", "cyan" },
  { "%f[%a]quit", "actions.quit", "red" },
  { "%f[%a]exit", "actions.quit", "red" },
  { "%f[%a]save", "actions.save", "green" },
  { "comment", "code.comment", "azure" },
  { "yank", "edit.yank", "green" },
  { "%f[%a]copy", "actions.copy", "green" },
  { "paste", "actions.paste", "yellow" },
  { "delete", "edit.delete", "red" },
  { "%f[%a]close", "actions.close", "red" },
  { "%f[%a]open", "actions.open", "yellow" },
  { "preview", "ui.preview", "cyan" },
  { "markdown", "lang.markdown_outline", "blue" },
  { "latex", "lang.latex", "blue" },
  { "%f[%a]chat", "claude.chat", "orange" },
  { "%f[%a]build", "actions.build", "yellow" },
  { "%f[%a]run", "actions.run", "green" },
  { "install", "actions.install", "yellow" },
  { "update", "actions.update", "yellow" },
  { "profile", "ui.profiler", "cyan" },
  { "colou?r", "ui.palette", "cyan" },
  { "theme", "ui.palette", "cyan" },
  { "select", "edit.visual", "yellow" },
  { "%f[%a]jump", "nav.jump", "azure" },
  { "%f[%a]next", "nav.next", "azure" },
  { "%f[%a]prev", "nav.prev", "azure" },
  { "%f[%a]go to", "nav.goto", "azure" },
  { "%f[%a]goto", "nav.goto", "azure" },
  { "%f[%a]move", "actions.move", "yellow" },
}

-- File types, extensions and file names mini.icons draws wrongly or not at all:
-- each language-table file type it has no icon for, and distinct icons for the
-- hardware languages, which it otherwise draws alike.
M.filetypes = {
  bsv = { "hardware.gate_xnor", "green" },
  edn = { "lang.clojure", "blue" },
  gotmpl = { "lang.gotmpl", "blue" },
  hlsl = { "lang.shader", "blue" },
  ["javascript.jsx"] = { "lang.react", "blue" },
  ["markdown.mdx"] = { "lang.markdown_outline", "blue" },
  ocamlinterface = { "lang.ocaml", "blue" },
  ["typescript.tsx"] = { "lang.react", "blue" },
  veryl = { "hardware.gate_nand", "green" },
  xdc = { "hardware.constraint", "orange" },
  upf = { "hardware.power", "yellow" },
  verilog = { "hardware.gate_and", "green" },
  systemverilog = { "hardware.ic", "green" },
  vhdl = { "hardware.gate_xor", "green" },
  firrtl = { "hardware.netlist", "green" },
  sdc = { "hardware.timer", "orange" },
  tcl = { "lang.script", "blue" },
}
M.extensions = {
  v = { "hardware.gate_and", "green" },
  vh = { "hardware.gate_and", "green" },
  sv = { "hardware.ic", "green" },
  svh = { "hardware.ic", "green" },
  vhd = { "hardware.gate_xor", "green" },
  vhdl = { "hardware.gate_xor", "green" },
  bsv = { "hardware.gate_xnor", "green" },
  veryl = { "hardware.gate_nand", "green" },
  fir = { "hardware.netlist", "green" },
  sdc = { "hardware.timer", "orange" },
  xdc = { "hardware.constraint", "orange" },
  upf = { "hardware.power", "yellow" },
  vcd = { "hardware.waveform", "green" },
  fst = { "hardware.waveform", "green" },
  gtkw = { "hardware.waveform", "green" },
  sp = { "hardware.resistor", "green" },
  spice = { "hardware.resistor", "green" },
}
M.filenames = {
  ["lazy-lock.json"] = { "lazy.lazy", "blue" },
  ["mason-lock.json"] = { "mason.mason", "green" },
  Brewfile = { "lang.beer", "yellow" },
  [".nvim.lua"] = { "ui.neovim", "green" },
  [".latexmkrc"] = { "lang.latex", "blue" },
  justfile = { "lang.gavel", "orange" },
  Justfile = { "lang.gavel", "orange" },
  ["CLAUDE.md"] = { "claude.claude", "orange" },
}

-- The glyph a reference such as "git.branch" names, or nil when it names none.
function M.get(ref)
  local category, name = ref:match("^([%w_]+)%.([%w_]+)$")
  local t = category and vim.tbl_contains(M.vocabulary, category) and M[category]
  return t and t[name] or nil
end

local function resolve(entry) return entry and { icon = M.get(entry[1]), color = entry[2] } or nil end

-- The icon and colour for a key description, or nil when M.keys has none.
function M.key(desc) return resolve(M.keys[desc]) end

-- The icon and colour for a which-key group name, or nil when M.groups has none.
function M.group(name) return resolve(M.groups[name]) end

-- which-key's icons.rules: one exact rule per M.keys description, then the
-- keyword rules. which-key tries these before its own.
function M.which_key_rules()
  local descs = vim.tbl_keys(M.keys)
  table.sort(descs)
  local rules = {}
  for _, desc in ipairs(descs) do
    local icon = M.key(desc)
    rules[#rules + 1] = { pattern = "^" .. vim.pesc(desc:lower()) .. "$", icon = icon.icon, color = icon.color }
  end
  for _, rule in ipairs(M.keywords) do
    rules[#rules + 1] = { pattern = rule[1], icon = M.get(rule[2]), color = rule[3] }
  end
  return rules
end

-- Gives a Snacks toggle its icon from M.toggles, green when on and grey when
-- off, and returns the toggle so the call can chain on to :map(). A toggle with
-- no entry keeps Snacks' default icon, and tests/test_keys.lua fails on it.
function M.toggle(toggle)
  local ref = M.toggles[toggle.opts.id]
  if ref then
    toggle.opts.icon = M.get(ref)
    toggle.opts.color = { enabled = "green", disabled = "grey" }
  end
  return toggle
end

-- mini.icons' overrides, in the shape its setup() takes.
function M.mini()
  local function shape(t)
    local out = {}
    for name, entry in pairs(t) do
      out[name] = { glyph = M.get(entry[1]), hl = "MiniIcons" .. entry[2]:sub(1, 1):upper() .. entry[2]:sub(2) }
    end
    return out
  end
  return { filetype = shape(M.filetypes), extension = shape(M.extensions), file = shape(M.filenames) }
end

-- A copy of a name-to-glyph table with a space after each glyph, the shape the
-- Snacks picker, trouble and lazy.nvim expect.
function M.spaced(t)
  local out = {}
  for name, glyph in pairs(t) do
    out[name] = glyph .. " "
  end
  return out
end

-- lazy.nvim's ui.icons table.
function M.lazy_ui()
  local icons = M.spaced(M.lazy)
  icons.loaded, icons.not_loaded, icons.list = M.lazy.loaded, M.lazy.not_loaded, M.lazy_list
  return icons
end

-- todo-comments' keywords, each with its icon. todo-comments merges these into
-- its own defaults, so every keyword keeps its colour and alternative spellings.
function M.todo_keywords()
  local out = {}
  for name, glyph in pairs(M.todo) do
    out[name] = { icon = glyph .. " " }
  end
  return out
end

return M
