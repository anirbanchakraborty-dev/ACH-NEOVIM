-- UI: Dashboard, Noice, Rainbow Delimiters, Indent Lines, Colorizer
local icons = require("config.icons")

return {
	-- Dashboard (snacks.nvim)
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			dashboard = {
				enabled = true,
				width = 64,
				preset = {
					header = [[
 █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝██║  ██║
███████║██║     ███████║
██╔══██║██║     ██╔══██║
██║  ██║╚██████╗██║  ██║
╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

Powered by ]]
						.. icons.ui.lazy
						.. [[ Lazy Package Manager ]],
					keys = {
						{
							icon = icons.ui.find_file .. " ",
							key = "f",
							desc = "Find File",
							action = ":lua Snacks.dashboard.pick('files')",
						},
						{
							icon = icons.ui.new_file .. " ",
							key = "n",
							desc = "New File",
							action = ":ene | startinsert",
						},
						{
							icon = icons.ui.find_text .. " ",
							key = "g",
							desc = "Find Text",
							action = ":lua Snacks.dashboard.pick('live_grep')",
						},
						{
							icon = icons.ui.recent .. " ",
							key = "r",
							desc = "Recent Files",
							action = ":lua Snacks.dashboard.pick('oldfiles')",
						},
						{
							icon = icons.ui.config .. " ",
							key = "c",
							desc = "Config",
							action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
						},
						{ icon = icons.ui.lazy .. " ", key = "l", desc = "Lazy", action = ":Lazy" },
						{ icon = icons.ui.quit .. " ", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "startup", icon = icons.ui.startup .. " " },
				},
			},
			notifier = {
				enabled = true,
				timeout = 4000,
				width = { min = 40, max = 80 },
				height = { min = 1, max = 20 },
				margin = { top = 0, right = 1, bottom = 0 },
				padding = true,
				sort = { "level", "added" },
				level = vim.log.levels.TRACE,
				icons = {
					error = icons.diagnostics.Error,
					warn = icons.diagnostics.Warn,
					info = icons.diagnostics.Info,
					debug = icons.diagnostics.Hint,
					trace = icons.diagnostics.Hint,
				},
				style = "fancy",
				top_down = true,
				date_format = "%R",
				more_format = " ↓ %d lines ",
				refresh = 50,
			},
			lazygit = {
				enabled = true,
				configure = true,
				theme = {
					[241] = { fg = "Special" },
					activeBorderColor = { fg = "MatchParen", bold = true },
					cherryPickedCommitBgColor = { fg = "Identifier" },
					cherryPickedCommitFgColor = { fg = "Function" },
					defaultFgColor = { fg = "Normal" },
					inactiveBorderColor = { fg = "FloatBorder" },
					optionsTextColor = { fg = "Function" },
					searchingActiveBorderColor = { fg = "MatchParen", bold = true },
					selectedLineBgColor = { bg = "Visual" },
					unstagedChangesColor = { fg = "DiagnosticError" },
				},
				win = {
					style = "lazygit",
					border = "rounded",
				},
			},
			gitbrowse = {
				enabled = true,
			},
			-- File tree explorer. The snacks ecosystem already loads, so
			-- enabling this is one line vs adding neo-tree as a separate
			-- plugin. Bound to <leader>e (root dir) and <leader>E (cwd)
			-- in the snacks keys block in util.lua, with <leader>fe / <leader>fE
			-- as the canonical names that <leader>e / <leader>E remap to.
			explorer = {
				enabled = true,
			},
			-- Defers some buffer setup operations on file open so the buffer
			-- renders faster. Pure speedup, no behavior change.
			quickfile = {
				enabled = true,
			},
			-- Floating prompt replacement for vim.ui.input. Used by LSP rename
			-- and any plugin that calls vim.ui.input directly.
			input = {
				enabled = true,
			},
			-- Animated smooth scrolling. Coexists with Neovim's native
			-- smoothscroll (set in options.lua) -- snacks adds animation on
			-- top of the partial-line stepping that smoothscroll provides.
			scroll = {
				enabled = true,
			},
			-- Highlight every occurrence of the word under the cursor across
			-- the visible buffer. Like vim-illuminate but bundled with snacks.
			words = {
				enabled = true,
			},
			indent = {
				enabled = true,
				char = "│",
				only_scope = false,
				scope = {
					enabled = true,
					char = "│",
					hl = {
						"RainbowDelimiterRed",
						"RainbowDelimiterOrange",
						"RainbowDelimiterYellow",
						"RainbowDelimiterGreen",
						"RainbowDelimiterCyan",
						"RainbowDelimiterBlue",
						"RainbowDelimiterViolet",
					},
				},
				chunk = {
					enabled = true,
					hl = {
						"RainbowDelimiterRed",
						"RainbowDelimiterOrange",
						"RainbowDelimiterYellow",
						"RainbowDelimiterGreen",
						"RainbowDelimiterCyan",
						"RainbowDelimiterBlue",
						"RainbowDelimiterViolet",
					},
					char = {
						corner_top = "┌",
						corner_bottom = "└",
						horizontal = "─",
						vertical = "│",
						arrow = ">",
					},
				},
				animate = {
					enabled = true,
					style = "out",
					easing = "linear",
					duration = {
						step = 20,
						total = 500,
					},
				},
			},
		},
		config = function(_, opts)
			-- Set up rainbow highlight groups for indent/scope
			vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#FF5370" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterOrange", { fg = "#F78C6C" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#FFCB6B" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterGreen", { fg = "#C3E88D" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterCyan", { fg = "#89DDFF" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#82AAFF" })
			vim.api.nvim_set_hl(0, "RainbowDelimiterViolet", { fg = "#C792EA" })
			require("snacks").setup(opts)

			-- ----------------------------------------------------------------
			-- UI/Toggle keymaps under <leader>u, powered by Snacks.toggle.
			-- These were previously manual vim.keymap.set callbacks in
			-- keymaps.lua. snacks.toggle handles get/set/notify automatically
			-- and pops a small toast on every toggle so you can see the new
			-- state. <leader>uf (Format on Save) stays manual in keymaps.lua
			-- because conform's disable_autoformat flag has no snacks built-in.
			-- ----------------------------------------------------------------
			Snacks.toggle.line_number():map("<leader>ul")
			Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
			Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
			Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
			Snacks.toggle.diagnostics():map("<leader>ud")
			Snacks.toggle.option("colorcolumn", { off = "", on = "80", name = "Color Column" }):map("<leader>uc")
			Snacks.toggle.inlay_hints():map("<leader>uh")
		end,
	},

	-- Noice (floating cmdline, messages, notifications)
	{
		"folke/noice.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		event = "VeryLazy",
		keys = {
			-- Redirect the typed cmdline to a floating popup -- handy for
			-- long :commands or :lua snippets where you want to read the output.
			{
				"<S-Enter>",
				function()
					require("noice").redirect(vim.fn.getcmdline())
				end,
				mode = "c",
				desc = "Redirect Cmdline",
			},

			-- Noice message browsing
			{
				"<leader>snl",
				function()
					require("noice").cmd("last")
				end,
				desc = "Noice Last Message",
			},
			{
				"<leader>snh",
				function()
					require("noice").cmd("history")
				end,
				desc = "Noice History",
			},
			{
				"<leader>sna",
				function()
					require("noice").cmd("all")
				end,
				desc = "Noice All",
			},
			{
				"<leader>snd",
				function()
					require("noice").cmd("dismiss")
				end,
				desc = "Dismiss All",
			},

			-- Scroll inside an LSP hover popup. Falls back to vanilla
			-- <C-f>/<C-b> page scrolling when no popup is open.
			{
				"<C-f>",
				function()
					if not require("noice.lsp").scroll(4) then
						return "<C-f>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Forward Docs",
				mode = { "i", "n", "s" },
			},
			{
				"<C-b>",
				function()
					if not require("noice.lsp").scroll(-4) then
						return "<C-b>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Backward Docs",
				mode = { "i", "n", "s" },
			},
		},
		opts = {
			cmdline = {
				enabled = true,
				view = "cmdline_popup",
				format = {
					cmdline = { icon = icons.devtools.terminal },
					search_down = { icon = icons.misc.arrow_down },
					search_up = { icon = icons.misc.arrow_up },
					filter = { icon = icons.ui.filter },
					lua = { icon = icons.filetypes.lua },
					help = { icon = icons.ui.help },
				},
			},
			notify = {
				-- let snacks.notifier own vim.notify (nicer theming + history)
				enabled = false,
			},
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				progress = {
					enabled = true,
				},
				hover = {
					enabled = true,
				},
				signature = {
					enabled = true,
				},
			},
			presets = {
				bottom_search = false,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = true,
			},
			views = {
				cmdline_popup = {
					position = {
						row = "40%",
						col = "50%",
					},
					size = {
						width = 60,
						height = "auto",
					},
					border = {
						style = "rounded",
					},
				},
			},
			routes = {
				-- Skip "X written" notifications entirely (already obvious from
				-- the buffer status).
				{
					filter = {
						event = "msg_show",
						kind = "",
						find = "written",
					},
					opts = { skip = true },
				},
				-- Send terse system messages (write summaries like "12L, 380B"
				-- and undo info "; after #N" / "; before #N") to a small mini
				-- view in the corner instead of the big notification area.
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
						},
					},
					view = "mini",
				},
			},
		},
	},

	-- Rainbow Delimiters (treesitter-based rainbow brackets)
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "BufReadPost",
		config = function()
			local rainbow = require("rainbow-delimiters")
			vim.g.rainbow_delimiters = {
				strategy = {
					[""] = rainbow.strategy["global"],
					vim = rainbow.strategy["local"],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterOrange",
					"RainbowDelimiterYellow",
					"RainbowDelimiterGreen",
					"RainbowDelimiterCyan",
					"RainbowDelimiterBlue",
					"RainbowDelimiterViolet",
				},
			}
		end,
	},

	-- bufferline.nvim: visual buffer tabs at the top with file icons,
	-- diagnostics, modified indicators, pinning, and close buttons. Replaces
	-- the vanilla <S-h>/<S-l>/[b/]b cycle with bufferline-aware versions
	-- that honor drag-to-reorder.
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			-- Buffer cycle (replaces the vanilla bnext/bprevious that used to
			-- live in keymaps.lua so the bufferline order is honored).
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },

			-- Move the current buffer left/right in the bufferline order.
			{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
			{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },

			-- Pinning + bulk close
			{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle Pin Buffer" },
			{ "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Delete Non-Pinned Buffers" },
			{ "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete Buffers to the Right" },
			{ "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete Buffers to the Left" },
			{ "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
		},
		opts = {
			options = {
				-- Snacks.bufdelete keeps the window open when closing the
				-- last buffer (vs vanilla :bd which closes the window too).
				close_command = function(n)
					Snacks.bufdelete(n)
				end,
				right_mouse_command = function(n)
					Snacks.bufdelete(n)
				end,

				diagnostics = "nvim_lsp",
				diagnostics_update_in_insert = false,
				always_show_bufferline = false,
				show_buffer_close_icons = true,
				show_close_icon = false,
				separator_style = "slant",
				indicator = { style = "underline" },

				-- All glyphs sourced from icons.lua per the central icons rule.
				modified_icon = icons.ui.pencil,
				buffer_close_icon = icons.ui.close,
				close_icon = icons.ui.close,
				left_trunc_marker = icons.misc.arrow_left,
				right_trunc_marker = icons.misc.arrow_right,

				-- LSP diagnostic indicator next to each tab. Returns a string
				-- like " 2  1" using error/warn icons from icons.lua.
				diagnostics_indicator = function(_, _, diag)
					local d = icons.diagnostics
					local ret = (diag.error and (d.Error .. " " .. diag.error .. " ") or "")
						.. (diag.warning and (d.Warn .. " " .. diag.warning) or "")
					return vim.trim(ret)
				end,

				-- Reserve space at the left edge for explorer-style sidebars.
				offsets = {
					{
						filetype = "neo-tree",
						text = "Neo-tree",
						highlight = "Directory",
						text_align = "left",
					},
					{
						filetype = "snacks_layout_box",
					},
				},
			},
		},
		config = function(_, opts)
			require("bufferline").setup(opts)

			-- Refresh bufferline when buffers come and go (mostly so the tab
			-- bar reappears correctly after restoring a session).
			vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
				callback = function()
					vim.schedule(function()
						pcall(nvim_bufferline)
					end)
				end,
			})
		end,
	},

	-- bufferline edgy offset patch: monkey-patches bufferline.offset.get
	-- to render a "Sidebar" placeholder + width when an edgy left/right
	-- pane is open but bufferline's own offsets[] table doesn't have a
	-- matching filetype. Without this, opening an edgy explorer or
	-- outline pane would let the bufferline tabs spill over the sidebar
	-- area instead of being offset cleanly. Borrowed from LazyVim's
	-- extras/ui/edgy.lua. The `Offset.edgy` flag is a re-entry guard so
	-- the patch only applies once per nvim session.
	{
		"akinsho/bufferline.nvim",
		optional = true,
		opts = function()
			local Offset = require("bufferline.offset")
			if not Offset.edgy then
				local get = Offset.get
				Offset.get = function()
					if package.loaded.edgy then
						local old_offset = get()
						local layout = require("edgy.config").layout
						local ret = { left = "", left_size = 0, right = "", right_size = 0 }
						for _, pos in ipairs({ "left", "right" }) do
							local sb = layout[pos]
							if sb and #sb.wins > 0 then
								local title = " Sidebar" .. string.rep(" ", sb.bounds.width - 8)
								-- Restructured from LazyVim's nested and/or chain so
								-- lua_ls can infer the result type cleanly. Behavior
								-- is identical: prefer the existing offset if any
								-- bufferline plugin already claimed it, otherwise
								-- render a Sidebar placeholder + separator.
								if old_offset[pos .. "_size"] > 0 then
									ret[pos] = old_offset[pos]
									ret[pos .. "_size"] = old_offset[pos .. "_size"]
								elseif pos == "left" then
									ret[pos] = "%#Bold#" .. title .. "%*" .. "%#BufferLineOffsetSeparator#│%*"
									ret[pos .. "_size"] = sb.bounds.width
								elseif pos == "right" then
									ret[pos] = "%#BufferLineOffsetSeparator#│%*" .. "%#Bold#" .. title .. "%*"
									ret[pos .. "_size"] = sb.bounds.width
								end
							end
						end
						ret.total_size = ret.left_size + ret.right_size
						if ret.total_size > 0 then
							return ret
						end
					end
					return get()
				end
				Offset.edgy = true
			end
		end,
	},

	-- edgy.nvim: layout manager that corrals sidebar windows (Trouble,
	-- Outline, Grug Far, terminal splits, quickfix, help, noice cmdline,
	-- snacks terminal) into edge groups (left/right/top/bottom). Each
	-- entry below describes a window the manager should accept and where
	-- to put it. Borrowed from LazyVim's extras/ui/edgy.lua, trimmed of
	-- the neo-tree, telescope, and neotest blocks (the user uses snacks
	-- explorer, fzf-lua, and has deferred neotest respectively).
	--
	-- Key insight: the trouble + snacks_terminal loops at the bottom add
	-- the same filetype to all four positions with a `vim.w[win]....position`
	-- filter, so a single plugin can land in any edge depending on how it
	-- was opened. Outline always lives on the right; grug-far on the right;
	-- toggleterm/noice/qf/help/Trouble at the bottom by default.
	--
	-- The `keys` table in opts sets buffer-local resize bindings inside
	-- edgy panes (`<C-arrows>` resize the layout group, not just the
	-- single window). The user's global `<C-arrow>` resize bindings in
	-- keymaps.lua still apply in non-edgy windows.
	{
		"folke/edgy.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>ue", function() require("edgy").toggle() end, desc = "Edgy Toggle" },
			{ "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
		},
		opts = function()
			local opts = {
				bottom = {
					{
						ft = "toggleterm",
						size = { height = 0.4 },
						filter = function(_, win)
							return vim.api.nvim_win_get_config(win).relative == ""
						end,
					},
					{
						ft = "noice",
						size = { height = 0.4 },
						filter = function(_, win)
							return vim.api.nvim_win_get_config(win).relative == ""
						end,
					},
					"Trouble",
					{ ft = "qf", title = "QuickFix" },
					{
						ft = "help",
						size = { height = 20 },
						-- Don't capture help files we're actively editing
						filter = function(buf)
							return vim.bo[buf].buftype == "help"
						end,
					},
				},
				right = {
					{ title = "Outline", ft = "Outline", size = { width = 0.25 } },
					{ title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
				},
				keys = {
					-- Increase / decrease pane width inside an edgy group
					["<c-Right>"] = function(win) win:resize("width", 2) end,
					["<c-Left>"]  = function(win) win:resize("width", -2) end,
					["<c-Up>"]    = function(win) win:resize("height", 2) end,
					["<c-Down>"]  = function(win) win:resize("height", -2) end,
				},
			}

			-- Trouble in any of the four positions: trouble can be opened
			-- with `position = "left"|"right"|"top"|"bottom"`. The filter
			-- checks vim.w[win].trouble.position so each open trouble window
			-- lands in the matching edge.
			for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
				opts[pos] = opts[pos] or {}
				table.insert(opts[pos], {
					ft = "trouble",
					filter = function(_, win)
						return vim.w[win].trouble
							and vim.w[win].trouble.position == pos
							and vim.w[win].trouble.type == "split"
							and vim.w[win].trouble.relative == "editor"
							and not vim.w[win].trouble_preview
					end,
				})
			end

			-- Snacks terminal (the non-toggleterm one snacks ships) in any
			-- of the four positions, with the terminal title formatted to
			-- show the snacks term ID + the underlying shell title.
			for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
				opts[pos] = opts[pos] or {}
				table.insert(opts[pos], {
					ft = "snacks_terminal",
					size = { height = 0.4 },
					title = "%{b:snacks_terminal.id}: %{b:term_title}",
					filter = function(_, win)
						return vim.w[win].snacks_win
							and vim.w[win].snacks_win.position == pos
							and vim.w[win].snacks_win.relative == "editor"
							and not vim.w[win].trouble_preview
					end,
				})
			end

			return opts
		end,
	},

	-- which-key: icons for the edgy toggles.
	{
		"folke/which-key.nvim",
		optional = true,
		opts_extend = { "spec" },
		opts = {
			spec = {
				{ "<leader>ue", desc = "Edgy Toggle", icon = { icon = icons.ui.split_v, color = "blue" } },
				{ "<leader>uE", desc = "Edgy Select Window", icon = { icon = icons.ui.menu, color = "blue" } },
			},
		},
	},

	-- mini.icons: modern replacement for nvim-web-devicons. The init hook
	-- registers a package.preload entry so any plugin that does
	-- `require("nvim-web-devicons")` transparently gets mini.icons' compat
	-- shim instead. This means lualine, fzf-lua, bufferline, neo-tree, etc.
	-- all keep working without needing nvim-web-devicons installed.
	{
		"nvim-mini/mini.icons",
		lazy = true,
		opts = {
			file = {
				[".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
				["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
				-- JavaScript / TypeScript project files. Borrowed verbatim
				-- from LazyVim's extras/lang/typescript/init.lua. Without
				-- these entries the file picker / lualine / bufferline
				-- show the generic JSON icon for tsconfig.json /
				-- package.json / etc., which is technically correct but
				-- visually identical to every other JSON file in the tree.
				-- These entries give them recognizable per-tool glyphs so
				-- they stand out in a crowded explorer.
				[".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				[".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
				[".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
				[".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
				["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
				["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
			},
			filetype = {
				dotenv = { glyph = "", hl = "MiniIconsYellow" },
			},
		},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},

	-- Colorizer (inline color preview)
	{
		"NvChad/nvim-colorizer.lua",
		event = "BufReadPost",
		opts = {
			filetypes = {
				"*",
				css = { css = true },
				scss = { css = true },
				html = { css = true },
				javascript = { css = true },
				typescript = { css = true },
				lua = { css = true },
			},
			user_default_options = {
				RGB = true,
				RRGGBB = true,
				RRGGBBAA = true,
				AARRGGBB = true,
				names = false,
				rgb_fn = true,
				hsl_fn = true,
				css = false,
				css_fn = false,
				mode = "background",
				virtualtext = "■",
			},
		},
	},

	-- mini.hipatterns: Tailwind CSS class highlighter. Renders class
	-- names like `bg-blue-500`, `text-emerald-600`, etc. with the actual
	-- Tailwind color inline. The Tailwind palette lives in the data
	-- module `nvim/lua/config/tailwind_colors.lua` (270 lines of static
	-- color tables, one entry per Tailwind palette × shade combo).
	--
	-- Borrowed from LazyVim's extras/util/mini-hipatterns.lua, trimmed
	-- of the `hex_color` and `shorthand` highlighters since
	-- nvim-colorizer (declared right above) already handles hex / rgb /
	-- hsl. mini.hipatterns is here PURELY for Tailwind class
	-- highlighting -- the two plugins coexist with zero overlap.
	--
	-- The `tailwind_hl` cache table is reset on `ColorScheme` events so
	-- that switching colorschemes doesn't leave stale highlight groups
	-- around (each highlight group encodes the Tailwind shade's bg + fg
	-- pair, which depends on the active colorscheme's contrast
	-- conventions).
	{
		"nvim-mini/mini.hipatterns",
		event = { "BufReadPost", "BufNewFile" },
		opts = function()
			local colors = require("config.tailwind_colors")
			-- Filetypes the Tailwind highlighter should activate in.
			-- Mirrors LazyVim's list plus a few extras (handlebars,
			-- twig, postcss) that match the user's web language stack.
			local tailwind_ft = {
				"astro",
				"css",
				"handlebars",
				"heex",
				"html",
				"html-eex",
				"htmlangular",
				"javascript",
				"javascriptreact",
				"less",
				"postcss",
				"sass",
				"scss",
				"svelte",
				"twig",
				"typescript",
				"typescriptreact",
				"vue",
			}
			local tailwind_hl = {}

			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("ACHHipatternsTailwindReset", { clear = true }),
				callback = function() tailwind_hl = {} end,
			})

			return {
				highlighters = {
					tailwind = {
						pattern = function()
							if not vim.tbl_contains(tailwind_ft, vim.bo.filetype) then
								return
							end
							-- "full" style: highlight the whole utility class.
							-- Use "compact" if you only want the color portion
							-- (e.g. `blue-500`) highlighted.
							return "%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]"
						end,
						group = function(_, _, m)
							---@type string
							local match = m.full_match
							---@type string, number|nil
							local color, shade = match:match("[%w-]+%-([a-z%-]+)%-(%d+)")
							shade = tonumber(shade)
							local bg = vim.tbl_get(colors, color, shade)
							if bg then
								local hl = "MiniHipatternsTailwind" .. color .. shade
								if not tailwind_hl[hl] then
									tailwind_hl[hl] = true
									-- Pick a contrasting fg shade so the class
									-- name stays readable on the color background:
									-- 500 -> 950 (dark fg on mid bg)
									-- <500 -> 900 (dark fg on light bg)
									-- >500 -> 100 (light fg on dark bg)
									local bg_shade = shade == 500 and 950
										or (shade < 500 and 900 or 100)
									local fg = vim.tbl_get(colors, color, bg_shade)
									vim.api.nvim_set_hl(0, hl, { bg = "#" .. bg, fg = "#" .. fg })
								end
								return hl
							end
						end,
						extmark_opts = { priority = 2000 },
					},
				},
			}
		end,
	},
}
