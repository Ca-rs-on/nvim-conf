vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("n", "<leader>bn", function() vim.cmd.sbnext() end)
vim.keymap.set("n", "<leader>bN", function() vim.cmd.sbNext() end)
vim.keymap.set("n", "<leader>ev", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
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
