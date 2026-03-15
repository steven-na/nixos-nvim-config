return {
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
					if _G.slow_format_filetypes[vim.bo[bufnr].filetype] then
						return
					end
					local function on_format(err)
						if err and err:match("timeout$") then
							_G.slow_format_filetypes[vim.bo[bufnr].filetype] = true
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
					javascriptreact = { "prettierd", "prettier" },
					typescriptreact = { "prettierd", "prettier" },
					vue = { "prettierd", "prettier" },
					svelte = { "prettierd", "prettier" },
					graphql = { "prettierd", "prettier" },
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
				cmake = { "cmake_format" },
					["_"] = { "trim_whitespace" },
				},

				formatters = {
					nixfmt = {
						command = "nixfmt",
						prepend_args = { "--indent=4" },
					},
					clang_format = {
						command = "clang-format",
						prepend_args = { "--style={IndentWidth: 4, TabWidth: 4, UseTab: Never}" },
					},
				},
			})
		end,
	},
}
