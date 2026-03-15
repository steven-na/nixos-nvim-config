if vim.loop.os_uname().sysname == "Windows_NT" then
	vim.o.shell = vim.fn.executable("pwsh") and "pwsh" or "powershell"
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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

vim.diagnostic.config({
	underline = true,
	virtual_text = {
		prefix = "",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅙",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "󰋼",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
	float = {
		border = "single",
	},
})
