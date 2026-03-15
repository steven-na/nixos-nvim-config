return {
	{
		"nvim-lint",
		auto_enable = true,
		event = "FileType",
		after = function(_)
			require("lint").linters_by_ft = {
				c = { "cppcheck" },
				cpp = { "cppcheck" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				vue = { "eslint_d" },
				svelte = { "eslint_d" },
			}
			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
}
