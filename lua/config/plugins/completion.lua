return {
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
}
