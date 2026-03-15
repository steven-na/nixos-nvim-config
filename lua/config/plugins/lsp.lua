return {
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
					if client.supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end

					local map = function(key, action, desc)
						vim.keymap.set("n", key, action, { buffer = bufnr, silent = true, desc = desc })
					end

					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("gT", vim.lsp.buf.type_definition, "Type Definition")
					map("K", vim.lsp.buf.hover, "Hover")

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
	{ "vtsls", lsp = { filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue" } } },
	{
		"tailwindcss",
		lsp = {
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"svelte",
			},
			settings = {
				tailwindCSS = {
					experimental = {
						classRegex = {
							{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
							{ "clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
							{ "cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
						},
					},
					validate = true,
				},
			},
		},
	},
	{
		"emmet_ls",
		lsp = {
			filetypes = {
				"html",
				"css",
				"scss",
				"javascriptreact",
				"typescriptreact",
				"vue",
				"svelte",
			},
		},
	},
	{ "html", lsp = { filetypes = { "html" } } },
	{
		"lua_ls",
		lsp = {
			filetypes = { "lua" },
			settings = {
				Lua = {
					signatureHelp = { enabled = true },
					hint = {
						enable = true,
						arrayIndex = "Disable",
						setType = false,
						paramName = "Disable",
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
		lsp = {
			filetypes = { "nix" },
			settings = { ... },
		},
	},
	{ "nil_ls", lsp = { filetypes = { "nix" } } },
	{
		"clangd",
		lsp = {
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=never",
				"--completion-style=detailed",
				"--function-arg-placeholders=true",
			},
			settings = {
				clangd = {
					InlayHints = {
						Designators = true,
						Enabled = true,
						ParameterNames = true,
						DeducedTypes = true,
					},
				},
			},
			on_attach = function(client, bufnr)
				vim.keymap.set("n", "<leader>ch", function()
					local params = vim.lsp.util.make_text_document_params(bufnr)
					client:request("textDocument/switchSourceHeader", params, function(err, result)
						if err or not result then
							vim.notify("No corresponding header/source found", vim.log.levels.WARN)
							return
						end
						vim.cmd.edit(vim.uri_to_fname(result))
					end, bufnr)
				end, { buffer = bufnr, silent = true, desc = "Switch [C]lang [H]eader/Source" })
			end,
		},
	},
	{ "cmake", lsp = { filetypes = { "cmake" } } },
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
	{
		"eslint",
		lsp = {
			filetypes = {
				"javascript",
				"typescript",
				"javascriptreact",
				"typescriptreact",
				"vue",
				"svelte",
			},
			settings = {
				format = true,
			},
			on_attach = function(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePre", {
					buffer = bufnr,
					command = "EslintFixAll",
				})
			end,
		},
	},
}
