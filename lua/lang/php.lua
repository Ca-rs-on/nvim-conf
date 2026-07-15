vim.lsp.config("intelephense", {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git" },
	init_options = { licenceKey = os.getenv("INTELEPHENSE_PRO_KEY") },
	settings = {
		intelephense = {
			files = {
				exclude = {
					"**/tmp/phpstan/**",
					"**/.git/**",
					"**/vendor/**/{Tests,tests}/**",
					"**/node_modules/**",
				},
			},
		},
	},
})

vim.lsp.enable("intelephense")
