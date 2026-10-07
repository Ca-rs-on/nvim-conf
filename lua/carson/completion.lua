-- Completion itself is vim.lsp.completion (enabled per client in lua/lang/init.lua);
-- LSP snippets expand through vim.snippet.
vim.opt.completeopt = 'menu,menuone,noselect,popup'

vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { desc = 'trigger completion' })

-- Only accept with <CR> when an item was explicitly selected.
vim.keymap.set('i', '<CR>', function()
	if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected ~= -1 then
		return '<C-y>'
	end
	return '<CR>'
end, { expr = true, desc = 'accept selected completion' })

-- <Tab>: cycle the menu, else jump in the active snippet, else a literal tab.
vim.keymap.set({ 'i', 's' }, '<Tab>', function()
	if vim.fn.pumvisible() == 1 then
		return '<C-n>'
	elseif vim.snippet.active({ direction = 1 }) then
		return '<Cmd>lua vim.snippet.jump(1)<CR>'
	end
	return '<Tab>'
end, { expr = true, desc = 'next completion / snippet tabstop' })

vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
	if vim.fn.pumvisible() == 1 then
		return '<C-p>'
	elseif vim.snippet.active({ direction = -1 }) then
		return '<Cmd>lua vim.snippet.jump(-1)<CR>'
	end
	return '<S-Tab>'
end, { expr = true, desc = 'prev completion / snippet tabstop' })

-- Popup menu while typing on the command line (replaces cmp-cmdline).
vim.opt.wildmode = 'noselect:lastused,full'
vim.opt.wildoptions = 'pum'
vim.api.nvim_create_autocmd('CmdlineChanged', {
	pattern = { ':', '/', '?' },
	callback = function() vim.fn.wildtrigger() end,
})
