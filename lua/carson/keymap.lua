vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("n", "<leader>ev", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/lua/carson/keymap.lua")
end)

-- System clipboard yank/paste.
vim.keymap.set("x", "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })
vim.keymap.set("x", "<leader>Y", '"+d', { desc = "Cut selection to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Toggle comment on the visual selection (uses built-in `gc` + commentstring).
vim.keymap.set("x", "<leader>//", "gc", { remap = true, desc = "Toggle comment on selection" })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'View line diagnostics' })
vim.keymap.set('n', '<leader>ch', function() 
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	vim.notify(string.format("Inlay Hint Enabled? %s", vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })))
 end )
vim.keymap.set('n', '<leader>cl', function() 
	vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled()) 
	vim.notify(string.format("Code Lens Enabled? %s", vim.lsp.codelens.is_enabled({ bufnr = 0 })))
 end )

vim.keymap.set('n', 'n', 'nzz', { remap = true } )
vim.keymap.set('n', 'N', 'Nzz', { remap = true } )

vim.keymap.set('n', ']c', ']czz', { remap = true } )
vim.keymap.set('n', '[c', '[czz', { remap = true } )


-- Visual mode (move selection)
vim.keymap.set("n", "<A-j>", ":move +1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":move -2<CR>==", { noremap = true, silent = true })

vim.keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv", { noremap = true, silent = true })
