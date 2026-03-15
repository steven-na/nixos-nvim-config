local specs = {}

local modules = {
	"config.plugins.lsp",
	"config.plugins.treesitter",
	"config.plugins.completion",
	"config.plugins.formatting",
	"config.plugins.linting",
	"config.plugins.ui",
	"config.plugins.debug",
}

for _, mod in ipairs(modules) do
	for _, spec in ipairs(require(mod)) do
		specs[#specs + 1] = spec
	end
end

nixInfo.lze.load(specs)
