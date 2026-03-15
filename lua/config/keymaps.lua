local map = vim.keymap.set

map("n", "<Space>", "<Nop>", { noremap = true, silent = true })
map({ "n", "i" }, "<Insert>", "<Nop>", { noremap = true, silent = true })
map("n", "<C-s>", ":w<CR>", { noremap = true, silent = true })
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

local slow_format_filetypes = {}
_G.slow_format_filetypes = slow_format_filetypes

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
