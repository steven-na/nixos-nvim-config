vim.loader.enable()
do
	local ok
	ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
	if not ok then
		package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
			__call = function(_, default)
				return default
			end,
		})
		_G.nixInfo = require(vim.g.nix_info_plugin_name)
	end
	nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
	---@module 'lzextras'
	---@type lzextras | lze
	nixInfo.lze = setmetatable(require("lze"), getmetatable(require("lzextras")))
	function nixInfo.get_nix_plugin_path(name)
		return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
	end
end

nixInfo.lze.register_handlers({
	{
		spec_field = "auto_enable",
		set_lazy = false,
		modify = function(plugin)
			if vim.g.nix_info_plugin_name then
				if type(plugin.auto_enable) == "table" then
					for _, name in pairs(plugin.auto_enable) do
						if not nixInfo.get_nix_plugin_path(name) then
							plugin.enabled = false
							break
						end
					end
				elseif type(plugin.auto_enable) == "string" then
					if not nixInfo.get_nix_plugin_path(plugin.auto_enable) then
						plugin.enabled = false
					end
				elseif type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
					if not nixInfo.get_nix_plugin_path(plugin.name) then
						plugin.enabled = false
					end
				end
			end
			return plugin
		end,
	},
	{
		spec_field = "for_cat",
		set_lazy = false,
		modify = function(plugin)
			if vim.g.nix_info_plugin_name then
				if type(plugin.for_cat) == "string" then
					plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
				end
			end
			return plugin
		end,
	},
	nixInfo.lze.lsp,
})

nixInfo.lze.h.lsp.set_ft_fallback(function(name)
	local lspcfg = nixInfo.get_nix_plugin_path("nvim-lspconfig")
	if lspcfg then
		local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
		return (ok and cfg or {}).filetypes or {}
	else
		return (vim.lsp.config[name] or {}).filetypes or {}
	end
end)

-- ============================================================
-- OPTIONS
-- Set vim options here. See `:help vim.o`
-- Examples:
--   vim.o.number = true
--   vim.o.relativenumber = true
--   vim.o.tabstop = 4
--   vim.o.shiftwidth = 4
--   vim.o.expandtab = true
--   vim.o.termguicolors = true
--   vim.o.undofile = true
-- ============================================================

-- Pre-config
if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.o.shell = vim.fn.executable("pwsh") and "pwsh" or "powershell"
end

-- Globals
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
local opt = vim.opt

opt.timeoutlen = 300
opt.updatetime = 250

opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4

opt.showmode = false
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 10

opt.swapfile = false

opt.list = true
opt.listchars = {
	tab = "  ",
	trail = "·",
	nbsp = "␣",
}

-- Diagnostics
vim.diagnostic.config({
	underline = true,
	virtual_text = {
		prefix = "",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅙",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "󰋼",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
	float = {
		border = "single",
	},
})

-- ============================================================
-- KEYMAPS
-- Set keymaps here. See `:help vim.keymap.set()`
-- Examples:
--   vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
-- ============================================================
local map = vim.keymap.set

map("n", "<Space>", "<Nop>", { noremap = true, silent = true })
map({ "n", "i" }, "<Insert>", "<Nop>", { noremap = true, silent = true })
map("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- ============================================================
-- AUTOCOMMANDS
-- Set autocommands here. See `:help vim.api.nvim_create_autocmd()`
-- Examples:
--   vim.api.nvim_create_autocmd("FileType", {
--       pattern = "lua",
--       callback = function() vim.o.shiftwidth = 2 end,
--   })
-- ============================================================

-- Pre-config (before plugins load)
local slow_format_filetypes = {}

vim.api.nvim_create_user_command("FormatDisable", function(args)
	if args.bang then
		vim.b.disable_autoformat = true
	else
		vim.g.disable_autoformat = true
	end
end, {
	desc = "Disable autoformat-on-save",
	bang = true,
})

vim.api.nvim_create_user_command("FormatEnable", function()
	vim.b.disable_autoformat = false
	vim.g.disable_autoformat = false
end, {
	desc = "Re-enable autoformat-on-save",
})

vim.api.nvim_create_user_command("FormatToggle", function(args)
	if args.bang then
		vim.b.disable_autoformat = not vim.b.disable_autoformat
	else
		vim.g.disable_autoformat = not vim.g.disable_autoformat
	end
end, {
	desc = "Toggle autoformat-on-save",
	bang = true,
})

nixInfo.lze.load({
	-- ============================================================
	-- COLORSCHEME
	-- Load your colorscheme plugin here, then trigger it below.
	-- The trigger_colorscheme spec below calls vim.cmd.colorscheme()
	-- on VimEnter. Change the string to match your colorscheme's name.
	-- ============================================================
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

	-- ============================================================
	-- LSP
	-- 1. Add an lsp spec per language server, e.g.:
	--
	--   {
	--       "lua_ls",
	--       for_cat = "lua",  -- optional, ties to a nix cat toggle
	--       lsp = {
	--           filetypes = { "lua" },
	--           settings = { ... },
	--       },
	--   },
	--
	-- 2. The nvim-lspconfig spec below wires up on_attach for all servers.
	--    Add keymaps or capabilities inside its before = function.
	-- ============================================================
	{
		"nvim-lspconfig",
		auto_enable = true,
		lsp = function(plugin)
			vim.lsp.config(plugin.name, plugin.lsp or {})
			vim.lsp.enable(plugin.name)
		end,
		before = function(_)
			vim.lsp.config("*", {
				on_attach = function(client, bufnr)
					-- Enable inlay hints if supported
					if client.supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end

					local map = function(key, action, desc)
						vim.keymap.set("n", key, action, { buffer = bufnr, silent = true, desc = desc })
					end

					-- lspBuf keymaps
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("gd", vim.lsp.buf.definition, "Goto Definition")
					map("gr", vim.lsp.buf.references, "Goto References")
					map("gD", vim.lsp.buf.declaration, "Goto Declaration")
					map("gI", vim.lsp.buf.implementation, "Goto Implementation")
					map("gT", vim.lsp.buf.type_definition, "Type Definition")
					map("K", vim.lsp.buf.hover, "Hover")

					-- diagnostic keymaps
					map("<leader>L", vim.diagnostic.open_float, "Line Diagnostics")
					map("[d", vim.diagnostic.goto_next, "Next Diagnostic")
					map("]d", vim.diagnostic.goto_prev, "Previous Diagnostic")
				end,
			})
		end,
	},
	{
		"mason.nvim",
		enabled = not nixInfo.isNix,
		priority = 100,
		on_plugin = { "nvim-lspconfig" },
		lsp = function(plugin)
			vim.cmd.MasonInstall(plugin.name)
		end,
	},
	{
		-- lazydev makes your lua lsp load only the relevant definitions for a file.
		-- It also gives us a nice way to correlate globals we create with files.
		"lazydev.nvim",
		auto_enable = true,
		cmd = { "LazyDev" },
		ft = "lua",
		after = function(_)
			require("lazydev").setup({
				library = {
					{ words = { "nixInfo%.lze" }, path = nixInfo("lze", "plugins", "start", "lze") .. "/lua" },
					{
						words = { "nixInfo%.lze" },
						path = nixInfo("lzextras", "plugins", "start", "lzextras") .. "/lua",
					},
				},
			})
		end,
	},

	-- LSP servers
	{ "html", lsp = { filetypes = { "html" } } },
	{
		"lua_ls",
		-- for_cat = "lua",
		lsp = {
			filetypes = { "lua" },
			settings = {
				Lua = {
					signatureHelp = { enabled = true },
					hint = {
						enable = true,
						arrayIndex = "Disable", -- removes the [1], [2], [3] hints
						setType = false,
						paramName = "Disable", -- optional: removes param name hints
						paramType = true,
					},
					diagnostics = {
						globals = { "nixInfo", "vim" },
						disable = { "missing-fields" },
					},
				},
			},
		},
	},
	{
		"nixd",
		enabled = nixInfo.isNix,
		-- removed for_cat = "nix"
		lsp = {
			filetypes = { "nix" },
			settings = { ... },
		},
	},
	{ "nil_ls", lsp = { filetypes = { "nix" } } },
	{ "clangd", lsp = { filetypes = { "c", "cpp", "objc", "objcpp", "cuda" } } },
	{
		"rust_analyzer",
		lsp = {
			filetypes = { "rust" },
			settings = {
				["rust-analyzer"] = {
					cargo = {
						allFeatures = true,
					},
					checkOnSave = {
						command = "clippy",
					},
					inlayHints = {
						bindingModeHints = { enable = true },
						chainingHints = { enable = true },
						closingBraceHints = { enable = true },
						closureReturnTypeHints = { enable = true },
						parameterHints = { enable = true },
						typeHints = { enable = true },
					},
				},
			},
		},
	},
	{ "bashls", lsp = { filetypes = { "sh" } } },
	{ "pyright", lsp = { filetypes = { "python" } } },
	{ "gopls", lsp = { filetypes = { "go", "gomod", "gowork", "gotmpl" } } },
	{ "jsonls", lsp = { filetypes = { "json", "jsonc" } } },
	{ "cssls", lsp = { filetypes = { "css", "scss", "less" } } },
	{ "eslint", lsp = { filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" } } },

	-- ============================================================
	-- TREESITTER
	-- Parses and installs grammars automatically on FileType.
	-- No further config needed unless you want to add textobjects etc.
	-- ============================================================
	{
		"nvim-treesitter",
		lazy = false,
		auto_enable = true,
		after = function(_)
			local function ts_attach(buf, language)
				if not vim.treesitter.language.add(language) then
					return false
				end
				vim.treesitter.start(buf, language)
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldmethod = "expr"
				vim.o.foldlevel = 99
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				return true
			end

			local installable = require("nvim-treesitter").get_available()
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local language = vim.treesitter.language.get_lang(args.match)
					if not language then
						return
					end
					if not ts_attach(args.buf, language) then
						if vim.tbl_contains(installable, language) then
							require("nvim-treesitter").install(language):await(function()
								ts_attach(args.buf, language)
							end)
						end
					end
				end,
			})
		end,
	},

	-- ============================================================
	-- COMPLETION
	-- blink.cmp is the completion engine.
	-- Add sources/providers inside its after = function.
	-- ============================================================
	-- {
	-- 	"blink.cmp",
	-- 	auto_enable = true,
	-- 	event = "DeferredUIEnter",
	-- 	after = function(_)
	-- 		require("blink.cmp").setup({
	-- 			keymap = { preset = "default" },
	-- 			signature = { enabled = true },
	-- 			completion = {
	-- 				documentation = { auto_show = true },
	-- 			},
	-- 			sources = {
	-- 				default = { "lsp", "path", "buffer" },
	-- 			},
	-- 			-- Add more sources/providers here
	-- 		})
	-- 	end,
	-- },

	{
		"nvim-cmp",
		after = function(_)
			local cmp = require("cmp")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			vim.lsp.config("*", { capabilities = capabilities })
			local icons = {
				Text = "󰉿",
				Method = "󰆧",
				Function = "󰊕",
				Constructor = "",
				Field = "󰜢",
				Variable = "󰀫",
				Class = "󰠱",
				Interface = "",
				Module = "",
				Property = "󰜢",
				Unit = "󰑭",
				Value = "󰎠",
				Enum = "",
				Keyword = "󰌋",
				Snippet = "",
				Color = "󰏘",
				File = "󰈙",
				Reference = "󰈇",
				Folder = "󰉋",
				EnumMember = "",
				Constant = "󰏿",
				Struct = "󰙅",
				Event = "",
				Operator = "󰆕",
				TypeParameter = "",
			}

			vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = "#C792EA", italic = true })

			cmp.setup({
				experimental = {
					ghost_text = true,
				},
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "git" },
					{
						name = "buffer",
						-- ✅ fixed: wrap in a function
						option = {
							get_bufnrs = function()
								return vim.api.nvim_list_bufs()
							end,
						},
						keyword_length = 3,
					},
					{
						name = "path",
						keyword_length = 3,
					},
					{
						name = "luasnip",
						keyword_length = 3,
					},
				}),
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-n>"] = cmp.mapping.select_next_item({
						behavior = cmp.SelectBehavior.Insert,
					}),
					["<C-p>"] = cmp.mapping.select_prev_item({
						behavior = cmp.SelectBehavior.Insert,
					}),
					["<C-y>"] = cmp.mapping(
						cmp.mapping.confirm({
							behavior = cmp.ConfirmBehavior.Insert,
							select = true,
						}),
						{ "i", "c" }
					),
				}),
				window = {
					completion = cmp.config.window.bordered({
						border = "double",
						winhighlight = "Normal:Normal,FloatBorder:Normal,Search:NONE",
						side_padding = 0,
						col_offset = -2,
					}),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(_, vim_item)
						local kind = vim_item.kind
						vim_item.kind = icons[kind] or ""
						vim_item.menu = " (" .. (kind or "Unknown") .. ") "
						return vim_item
					end,
				},
			})
		end,
	},
	{
		"luasnip",
		after = function(_)
			local ls = require("luasnip")

			require("luasnip.loaders.from_vscode").lazy_load()

			ls.config.set_config({
				enable_autosnippets = true,
			})

			vim.keymap.set({ "i", "s" }, "<c-k>", function()
				if ls.expand_or_jumpable() then
					ls.expand_or_jump()
				end
			end, { silent = true })

			vim.keymap.set({ "i", "s" }, "<c-j>", function()
				if ls.jumpable(-1) then
					ls.jump(-1)
				end
			end, { silent = true })
		end,
	},
	{ "cmp-nvim-lsp", dep_of = "nvim-cmp" },
	{ "cmp-buffer", dep_of = "nvim-cmp" },
	{ "cmp-git", dep_of = "nvim-cmp" },
	{ "cmp-path", dep_of = "nvim-cmp" },
	{ "friendly-snippets", dep_of = "luasnip" },

	-- ============================================================
	-- FORMATTING
	-- Add formatters_by_ft entries inside conform's after = function.
	-- ============================================================
	{
		"conform.nvim",
		auto_enable = true,
		after = function(_)
			local conform = require("conform")
			conform.setup({
				format_on_save = function(bufnr)
					if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
						return
					end
					if slow_format_filetypes[vim.bo[bufnr].filetype] then
						return
					end
					local function on_format(err)
						if err and err:match("timeout$") then
							slow_format_filetypes[vim.bo[bufnr].filetype] = true
						end
					end
					return { timeout_ms = 200, lsp_format = "fallback" }, on_format
				end,

				notify_on_error = true,

				formatters_by_ft = {
					html = { "prettierd", "prettier" },
					css = { "prettierd", "prettier" },
					javascript = { "prettierd", "prettier" },
					typescript = { "prettierd", "prettier" },
					python = { "black", "isort" },
					rust = { "rustfmt" },
					lua = { "stylua" },
					nix = { "nixfmt" },
					markdown = { "prettierd", "prettier" },
					yaml = { "prettierd", "prettier" },
					bash = { "shellcheck", "shellharden", "shfmt" },
					sh = { "shellcheck", "shellharden", "shfmt" },
					json = { "jq" },
					c = { "clang_format" },
					cpp = { "clang_format" },
					["_"] = { "trim_whitespace" },
				},

				formatters = {
					black = {
						command = "black",
					},
					isort = {
						command = "isort",
					},
					nixfmt = {
						command = "nixfmt",
						prepend_args = { "--indent=4" },
					},
					jq = {
						command = "jq",
					},
					prettierd = {
						command = "prettierd",
					},
					stylua = {
						command = "stylua",
					},
					shellcheck = {
						command = "shellcheck",
					},
					shfmt = {
						command = "shfmt",
					},
					shellharden = {
						command = "shellharden",
					},
					bicep = {
						command = "bicep",
					},
					rustfmt = {
						command = "rustfmt",
					},
					clang_format = {
						command = "clang-format",
					},
				},
			})
		end,
	},

	-- ============================================================
	-- LINTING
	-- Add linters_by_ft entries inside nvim-lint's after = function.
	-- ============================================================
	{
		"nvim-lint",
		auto_enable = true,
		event = "FileType",
		after = function(_)
			require("lint").linters_by_ft = {
				-- e.g. javascript = { "eslint" },
				c = { "cppcheck" },
				cpp = { "cppcheck" },
			}
			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},

	-- ============================================================
	-- ADD PLUGINS
	-- Add additional plugin specs here following this pattern:
	--
	--   {
	--       "plugin-name",
	--       auto_enable = true,      -- disable if not installed by nix
	--       event = "DeferredUIEnter", -- or: cmd, ft, keys, colorscheme
	--       after = function(_)
	--           require("plugin-name").setup({ ... })
	--       end,
	--   },
	--
	-- Trigger options:
	--   event      = vim event string or table of strings
	--   cmd        = ex-command string or table of strings
	--   ft         = filetype string or table of strings
	--   keys       = table of { lhs, mode?, desc? } tables
	--   colorscheme = colorscheme name string or table of strings
	--   on_plugin  = load after another plugin by name
	--   dep_of     = treat this as a dependency of another spec
	--   lazy = false  for eager (non-lazy) loading
	-- ============================================================

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
				logger = {
					level = vim.log.levels.WARN,
					float_precision = 1.0e-2,
				},
				progress = {
					poll_rate = 0,
					suppress_on_insert = true,
					ignore_done_already = false,
					ignore_empty_message = false,
					clear_on_detach = function(client_id)
						local client = vim.lsp.get_client_by_id(client_id)
						return client and client.name or nil
					end,
					notification_group = function(msg)
						return msg.lsp_client.name
					end,
					ignore = {},
					lsp = {
						progress_ringbuf_size = 0,
					},
					display = {
						render_limit = 16,
						done_ttl = 3,
						done_icon = "✔",
						done_style = "Constant",
						progress_ttl = math.huge,
						progress_icon = { pattern = "dots", period = 1 },
						progress_style = "WarningMsg",
						group_style = "Title",
						icon_style = "Question",
						priority = 30,
						skip_history = true,
						format_message = require("fidget.progress.display").default_format_message,
						format_annote = function(msg)
							return msg.title
						end,
						format_group_name = function(group)
							return tostring(group)
						end,
						overrides = {
							rust_analyzer = { name = "rust-analyzer" },
						},
					},
				},
				notification = {
					poll_rate = 10,
					filter = vim.log.levels.INFO,
					history_size = 128,
					override_vim_notify = true,
					redirect = function(msg, level, opts)
						if opts and opts.on_open then
							return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
						end
					end,
					configs = {
						default = require("fidget.notification").default_config,
					},
					window = {
						normal_hl = "Comment",
						winblend = 0,
						border = "none",
						zindex = 45,
						max_width = 0,
						max_height = 0,
						x_padding = 1,
						y_padding = 0,
						align = "bottom",
						relative = "editor",
					},
					view = {
						stack_upwards = true,
						icon_separator = " ",
						group_separator = "---",
						group_separator_hl = "Comment",
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
					add = { text = " " },
					change = { text = " " },
					delete = { text = " " },
					untracked = { text = "" },
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
		dep_of = "nvim-ufo", -- ensures it loads before ufo
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
				-- spec = {
				-- 	{ "<leader>c", group = "Code" },
				-- 	{ "<leader>g", group = "Git" },
				-- 	{ "<leader>d", group = "Symbol find" },
				-- 	{ "<leader>s", group = "Bufferline" },
				-- 	{ "<leader>sc", group = "Close buffers" },
				-- 	{ "<leader>S", group = "Snacks commands" },
				-- },
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
			local custom_theme = {
				normal = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
				insert = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
				visual = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
				replace = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
				command = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
				inactive = {
					a = { fg = "NONE", bg = "NONE" },
					b = { fg = "NONE", bg = "NONE" },
					c = { fg = "NONE", bg = "NONE" },
				},
			}

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
									or isInsert() and ""
									or isVisual() and "󰒉"
									or isCommand() and ""
									or isReplace() and ""
									or vim.api.nvim_get_mode().mode == "t" and ""
									or ""
							end,
						},
						"mode",
					},
					-- lualine_b = { "branch", "diff" },
					lualine_c = {
						-- {
						-- 	"diagnostics",
						-- 	symbols = {
						-- 		error = "󰅙 ",
						-- 		warn = " ",
						-- 		info = "󰋼 ",
						-- 		hint = "󰌵 ",
						-- 	},
						-- },
					},
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
								-- return "%#LualineDim#" .. dir .. "%#LualineFile#" .. file
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
				picker = { enabled = true },
				quickfile = { enabled = true },
				scope = { enabled = true },
				scroll = { enabled = true },
				statuscolumn = { enabled = true },
				words = { enabled = true },
				styles = {
					notification = {
						-- wo = { wrap = true } -- Wrap notifications
					},
				},
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
			vim.keymap.set("n", "<leader>n", function()
				Snacks.picker.notifications()
			end, { desc = "Notification History" })
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
			vim.keymap.set("n", "<leader>sb", function()
				Snacks.picker.lines()
			end, { desc = "Buffer Lines" })
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
})
