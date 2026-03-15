return {
	{
		"trigger_colorscheme",
		event = "VimEnter",
		load = function(_name)
			vim.schedule(function()
				vim.cmd("set notermguicolors")
				vim.cmd.colorscheme("default")
			end)
		end,
	},
	{
		"nvim-autopairs",
		auto_enable = true,
		event = "InsertEnter",
		after = function(_)
			require("nvim-autopairs").setup({
				disable_filetype = { "vim" },
			})
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
	{
		"fidget.nvim",
		auto_enable = true,
		event = "LspAttach",
		after = function(_)
			require("fidget").setup({
				progress = {
					display = {
						overrides = {
							rust_analyzer = { name = "rust-analyzer" },
						},
					},
				},
				notification = {
					override_vim_notify = true,
					redirect = function(msg, level, opts)
						if opts and opts.on_open then
							return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
						end
					end,
					window = {
						winblend = 0,
					},
				},
			})
		end,
	},
	{
		"gitsigns.nvim",
		auto_enable = true,
		event = "BufReadPre",
		after = function(_)
			require("gitsigns").setup({
				signs = {
					add = { text = " " },
					change = { text = " " },
					delete = { text = " " },
					untracked = { text = "" },
					topdelete = { text = "󱂥 " },
					changedelete = { text = "󱂧 " },
				},
				signs_staged = {
					add = { text = "" },
					change = { text = "" },
					delete = { text = "" },
					untracked = { text = "" },
					topdelete = { text = "󱂥 " },
					changedelete = { text = "󱂧 " },
				},
			})
		end,
	},
	{
		"leap.nvim",
		auto_enable = true,
		event = "DeferredUIEnter",
		after = function(_)
			vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
			vim.keymap.set("n", "S", "<Plug>(leap-from-window)")
		end,
	},
	{
		"nvim-ufo",
		auto_enable = true,
		event = "BufReadPost",
		after = function(_)
			vim.o.foldcolumn = "0"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "lsp", "indent" }
				end,
			})

			vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
			vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
			vim.keymap.set("n", "zK", function()
				local winid = require("ufo").peekFoldedLinesUnderCursor()
				if not winid then
					vim.lsp.buf.hover()
				end
			end, { desc = "Peek fold" })
		end,
	},
	{
		"promise-async",
		dep_of = "nvim-ufo",
	},
	{
		"which-key.nvim",
		after = function(_)
			require("which-key").setup({
				delay = 200,
				expand = 1,
				notify = false,
				preset = false,
				replace = {
					desc = {
						{ "<space>", "SPACE" },
						{ "<leader>", "SPACE" },
						{ "<[cC][rR]>", "RETURN" },
						{ "<[tT][aA][bB]>", "TAB" },
						{ "<[bB][sS]>", "BACKSPACE" },
					},
				},
			})
		end,
	},
	{
		"lualine.nvim",
		event = "DeferredUIEnter",
		after = function(_)
			require("mini.icons").mock_nvim_web_devicons()
			local hi = vim.api.nvim_set_hl

			hi(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
			hi(0, "NormalNC", { bg = "NONE", ctermbg = "NONE" })
			hi(0, "@boolean", { ctermfg = "Magenta" })
			hi(0, "@type", { ctermfg = "Cyan" })
			hi(0, "Type", { ctermfg = "Cyan" })
			hi(0, "LspInlayHint", { ctermfg = "LightGray" })
			hi(0, "CmpGhostText", { ctermfg = "LightGray" })
			hi(0, "LualineDim", { bg = "NONE", ctermfg = "NONE", italic = true })
			hi(0, "LualineFile", { ctermfg = "NONE", ctermbg = "NONE" })

			local transparent = { fg = "NONE", bg = "NONE" }
			local custom_theme = {}
			for _, mode in ipairs({ "normal", "insert", "visual", "replace", "command", "inactive" }) do
				custom_theme[mode] = { a = transparent, b = transparent, c = transparent }
			end

			local function isNormal()
				return vim.tbl_contains({ "n", "niI", "niR", "niV", "nt", "ntT" }, vim.api.nvim_get_mode().mode)
			end

			local function isInsert()
				return vim.tbl_contains({ "i", "ic", "ix" }, vim.api.nvim_get_mode().mode)
			end

			local function isVisual()
				return vim.tbl_contains(
					{ "v", "vs", "V", "Vs", "\22", "\22s", "s", "S", "\19" },
					vim.api.nvim_get_mode().mode
				)
			end

			local function isCommand()
				return vim.tbl_contains({ "c", "cv", "ce", "rm", "r?" }, vim.api.nvim_get_mode().mode)
			end

			local function isReplace()
				return vim.tbl_contains({ "R", "Rc", "Rx", "Rv", "Rvc", "Rvx", "r" }, vim.api.nvim_get_mode().mode)
			end

			require("lualine").setup({
				options = {
					theme = custom_theme,
					icons_enabled = true,
					component_separators = { left = "", right = "" },
					section_separators = { left = "   ", right = "   " },
					disabled_filetypes = { "snacks_dashboard" },
					always_divide_middle = true,
					globalstatus = false,
					refresh = {
						statusline = 1000,
						tabline = 1000,
						winbar = 1000,
					},
				},
				sections = {
					lualine_a = {
						{
							"mode",
							icon_enable = true,
							fmt = function()
								return isNormal() and "󱣱"
									or isInsert() and ""
									or isVisual() and "󰒉"
									or isCommand() and ""
									or isReplace() and ""
									or vim.api.nvim_get_mode().mode == "t" and ""
									or ""
							end,
						},
						"mode",
					},
					lualine_c = {},
					lualine_x = {
						{
							"filetype",
							colored = true,
							icon_only = true,
							icon = { align = "right" },
						},
						{
							function()
								local full_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
								local dir = vim.fn.fnamemodify(full_path, ":h") .. "/"
								local file = vim.fn.fnamemodify(full_path, ":t")
								return dir .. file
							end,
							color = {},
						},
					},
					lualine_y = {
						{
							"progress",
							color = function()
								return {
									fg = vim.fn.synIDattr(
										vim.fn.synIDtrans(
											vim.fn.hlID(
												"progressHl"
													.. (math.floor((vim.fn.line(".") / vim.fn.line("$")) / 0.17) + 1)
											)
										),
										"fg"
									),
								}
							end,
						},
					},
					lualine_z = { "location" },
				},
			})
		end,
	},
	{
		"mini.icons",
		dep_of = "lualine.nvim",
	},
	{
		"snacks.nvim",
		auto_enable = true,
		lazy = false,
		priority = 1000,
		after = function(plugin)
			require("snacks").setup({
				bigfile = { enabled = true },
				explorer = { enabled = true },
				indent = { enabled = true },
				input = { enabled = true },
				notifier = {
					enabled = true,
					timeout = 3000,
				},
				picker = {
					enabled = true,
					sources = {
						explorer = {
							auto_close = true,
							jump = { close = true },
						},
					},
				},
				quickfile = { enabled = true },
				scope = { enabled = true },
				scroll = { enabled = true },
				statuscolumn = { enabled = true },
				words = { enabled = true },
			})
			-- Top Pickers & Explorer
			vim.keymap.set("n", "<leader><space>", function()
				Snacks.picker.smart()
			end, { desc = "Smart Find Files" })
			vim.keymap.set("n", "<leader>,", function()
				Snacks.picker.buffers()
			end, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>/", function()
				Snacks.picker.grep()
			end, { desc = "Grep" })
			vim.keymap.set("n", "<leader>:", function()
				Snacks.picker.command_history()
			end, { desc = "Command History" })
			vim.keymap.set("n", "<leader>e", function()
				Snacks.explorer()
			end, { desc = "File Explorer" })

			-- find
			vim.keymap.set("n", "<leader>fb", function()
				Snacks.picker.buffers()
			end, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>fc", function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "Find Config File" })
			vim.keymap.set("n", "<leader>ff", function()
				Snacks.picker.files()
			end, { desc = "Find Files" })
			vim.keymap.set("n", "<leader>fg", function()
				Snacks.picker.git_files()
			end, { desc = "Find Git Files" })
			vim.keymap.set("n", "<leader>fp", function()
				Snacks.picker.projects()
			end, { desc = "Projects" })
			vim.keymap.set("n", "<leader>fr", function()
				Snacks.picker.recent()
			end, { desc = "Recent" })

			-- git
			vim.keymap.set("n", "<leader>gb", function()
				Snacks.picker.git_branches()
			end, { desc = "Git Branches" })
			vim.keymap.set("n", "<leader>gl", function()
				Snacks.picker.git_log()
			end, { desc = "Git Log" })
			vim.keymap.set("n", "<leader>gL", function()
				Snacks.picker.git_log_line()
			end, { desc = "Git Log Line" })
			vim.keymap.set("n", "<leader>gs", function()
				Snacks.picker.git_status()
			end, { desc = "Git Status" })
			vim.keymap.set("n", "<leader>gS", function()
				Snacks.picker.git_stash()
			end, { desc = "Git Stash" })
			vim.keymap.set("n", "<leader>gd", function()
				Snacks.picker.git_diff()
			end, { desc = "Git Diff (Hunks)" })
			vim.keymap.set("n", "<leader>gf", function()
				Snacks.picker.git_log_file()
			end, { desc = "Git Log File" })

			-- gh
			vim.keymap.set("n", "<leader>gi", function()
				Snacks.picker.gh_issue()
			end, { desc = "GitHub Issues (open)" })
			vim.keymap.set("n", "<leader>gI", function()
				Snacks.picker.gh_issue({ state = "all" })
			end, { desc = "GitHub Issues (all)" })
			vim.keymap.set("n", "<leader>gp", function()
				Snacks.picker.gh_pr()
			end, { desc = "GitHub Pull Requests (open)" })
			vim.keymap.set("n", "<leader>gP", function()
				Snacks.picker.gh_pr({ state = "all" })
			end, { desc = "GitHub Pull Requests (all)" })

			-- Grep
			vim.keymap.set("n", "<leader>sb", function()
				Snacks.picker.lines()
			end, { desc = "Buffer Lines" })
			vim.keymap.set("n", "<leader>sB", function()
				Snacks.picker.grep_buffers()
			end, { desc = "Grep Open Buffers" })
			vim.keymap.set("n", "<leader>sg", function()
				Snacks.picker.grep()
			end, { desc = "Grep" })
			vim.keymap.set({ "n", "x" }, "<leader>sw", function()
				Snacks.picker.grep_word()
			end, { desc = "Visual selection or word" })

			-- search
			vim.keymap.set("n", '<leader>s"', function()
				Snacks.picker.registers()
			end, { desc = "Registers" })
			vim.keymap.set("n", "<leader>s/", function()
				Snacks.picker.search_history()
			end, { desc = "Search History" })
			vim.keymap.set("n", "<leader>sa", function()
				Snacks.picker.autocmds()
			end, { desc = "Autocmds" })
			vim.keymap.set("n", "<leader>sc", function()
				Snacks.picker.command_history()
			end, { desc = "Command History" })
			vim.keymap.set("n", "<leader>sC", function()
				Snacks.picker.commands()
			end, { desc = "Commands" })
			vim.keymap.set("n", "<leader>sd", function()
				Snacks.picker.diagnostics()
			end, { desc = "Diagnostics" })
			vim.keymap.set("n", "<leader>sD", function()
				Snacks.picker.diagnostics_buffer()
			end, { desc = "Buffer Diagnostics" })
			vim.keymap.set("n", "<leader>sh", function()
				Snacks.picker.help()
			end, { desc = "Help Pages" })
			vim.keymap.set("n", "<leader>sH", function()
				Snacks.picker.highlights()
			end, { desc = "Highlights" })
			vim.keymap.set("n", "<leader>si", function()
				Snacks.picker.icons()
			end, { desc = "Icons" })
			vim.keymap.set("n", "<leader>sj", function()
				Snacks.picker.jumps()
			end, { desc = "Jumps" })
			vim.keymap.set("n", "<leader>sk", function()
				Snacks.picker.keymaps()
			end, { desc = "Keymaps" })
			vim.keymap.set("n", "<leader>sl", function()
				Snacks.picker.loclist()
			end, { desc = "Location List" })
			vim.keymap.set("n", "<leader>sm", function()
				Snacks.picker.marks()
			end, { desc = "Marks" })
			vim.keymap.set("n", "<leader>sM", function()
				Snacks.picker.man()
			end, { desc = "Man Pages" })
			vim.keymap.set("n", "<leader>sp", function()
				Snacks.picker.lazy()
			end, { desc = "Search for Plugin Spec" })
			vim.keymap.set("n", "<leader>sq", function()
				Snacks.picker.qflist()
			end, { desc = "Quickfix List" })
			vim.keymap.set("n", "<leader>sR", function()
				Snacks.picker.resume()
			end, { desc = "Resume" })
			vim.keymap.set("n", "<leader>su", function()
				Snacks.picker.undo()
			end, { desc = "Undo History" })
			vim.keymap.set("n", "<leader>uC", function()
				Snacks.picker.colorschemes()
			end, { desc = "Colorschemes" })

			-- LSP
			vim.keymap.set("n", "gd", function()
				Snacks.picker.lsp_definitions()
			end, { desc = "Goto Definition" })
			vim.keymap.set("n", "gD", function()
				Snacks.picker.lsp_declarations()
			end, { desc = "Goto Declaration" })
			vim.keymap.set("n", "gr", function()
				Snacks.picker.lsp_references()
			end, { nowait = true, desc = "References" })
			vim.keymap.set("n", "gI", function()
				Snacks.picker.lsp_implementations()
			end, { desc = "Goto Implementation" })
			vim.keymap.set("n", "gy", function()
				Snacks.picker.lsp_type_definitions()
			end, { desc = "Goto T[y]pe Definition" })
			vim.keymap.set("n", "gai", function()
				Snacks.picker.lsp_incoming_calls()
			end, { desc = "C[a]lls Incoming" })
			vim.keymap.set("n", "gao", function()
				Snacks.picker.lsp_outgoing_calls()
			end, { desc = "C[a]lls Outgoing" })
			vim.keymap.set("n", "<leader>ss", function()
				Snacks.picker.lsp_symbols()
			end, { desc = "LSP Symbols" })
			vim.keymap.set("n", "<leader>sS", function()
				Snacks.picker.lsp_workspace_symbols()
			end, { desc = "LSP Workspace Symbols" })

			-- Other
			vim.keymap.set("n", "<leader>z", function()
				Snacks.zen()
			end, { desc = "Toggle Zen Mode" })
			vim.keymap.set("n", "<leader>Z", function()
				Snacks.zen.zoom()
			end, { desc = "Toggle Zoom" })
			vim.keymap.set("n", "<leader>.", function()
				Snacks.scratch()
			end, { desc = "Toggle Scratch Buffer" })
			vim.keymap.set("n", "<leader>S", function()
				Snacks.scratch.select()
			end, { desc = "Select Scratch Buffer" })
			vim.keymap.set("n", "<leader>n", function()
				Snacks.notifier.show_history()
			end, { desc = "Notification History" })
			vim.keymap.set("n", "<leader>bd", function()
				Snacks.bufdelete()
			end, { desc = "Delete Buffer" })
			vim.keymap.set("n", "<leader>cR", function()
				Snacks.rename.rename_file()
			end, { desc = "Rename File" })
			vim.keymap.set("n", "<leader>gg", function()
				Snacks.lazygit()
			end, { desc = "Lazygit" })
			vim.keymap.set("n", "<leader>un", function()
				Snacks.notifier.hide()
			end, { desc = "Dismiss All Notifications" })
			vim.keymap.set("n", "<c-/>", function()
				Snacks.terminal()
			end, { desc = "Toggle Terminal" })
			vim.keymap.set("n", "<c-_>", function()
				Snacks.terminal()
			end, { desc = "which_key_ignore" })
			vim.keymap.set({ "n", "t" }, "]]", function()
				Snacks.words.jump(vim.v.count1)
			end, { desc = "Next Reference" })
			vim.keymap.set({ "n", "t" }, "[[", function()
				Snacks.words.jump(-vim.v.count1)
			end, { desc = "Prev Reference" })

			vim.keymap.set("n", "<leader>N", function()
				Snacks.win({
					file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
					width = 0.6,
					height = 0.6,
					wo = {
						spell = false,
						wrap = false,
						signcolumn = "yes",
						statuscolumn = " ",
						conceallevel = 3,
					},
				})
			end, { desc = "Neovim News" })

			-- Init / VeryLazy autocmd
			vim.api.nvim_create_autocmd("User", {
				pattern = "DeferredUIEnter",
				callback = function()
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end

					if vim.fn.has("nvim-0.11") == 1 then
						vim._print = function(_, ...)
							dd(...)
						end
					else
						vim.print = _G.dd
					end

					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<leader>uc")
					Snacks.toggle.treesitter():map("<leader>uT")
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<leader>ub")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle.indent():map("<leader>ug")
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
	},
	{
		"vim-startuptime",
	},
}
