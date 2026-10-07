vim.lsp.config("intelephense", {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php" },
	root_markers = { "composer.json", ".git" },
	init_options = { licenceKey = os.getenv("INTELEPHENSE_PRO_KEY") },
	settings = {
		intelephense = {
			telemetry = { enabled = false },
			files = {
				exclude = {
					"**/tmp/**",
					"**/.git/**",
					"**/vendor/**/{Tests,tests}/**",
					"**/node_modules/**",
					"**/templates/cached/**"
				},
			},
		},
	},
})

vim.lsp.enable("intelephense")
