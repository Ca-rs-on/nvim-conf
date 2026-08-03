vim.lsp.config('lua_ls', {
	filetypes = { "lua" },
	cmd = { '/home/carson/.config/nvim/lua/lang/lua_ls/bin/lua-language-server' },
	root_markers = { '.git' },
	settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			diagnostics = { globals = { 'vim' } },
		},
	},
})
vim.lsp.enable('lua_ls')
