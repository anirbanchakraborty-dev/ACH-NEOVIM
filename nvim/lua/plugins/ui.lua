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
}
