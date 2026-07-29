vim.lsp.config('lua_ls', {
	filetypes = { "lua" },
	cmd = { 'lua-language-server' },
	settings = {
		Lua = {
			runtime = { version = 'LuaJIT' },
			diagnostics = { globals = { 'vim' } },
		},
	},
})
vim.lsp.enable('lua_ls')
