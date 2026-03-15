return {
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
	{
		"nvim-ts-autotag",
		auto_enable = true,
		ft = { "html", "javascriptreact", "typescriptreact", "vue", "svelte", "xml" },
		after = function(_)
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
			})
		end,
	},
}
