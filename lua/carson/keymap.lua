-- CAPS is mapped from zshrc
vim.keymap.set("i", "jk", "<ESC>")
-- conf stuff
vim.keymap.set("n", "<leader>ev", function()
	vim.cmd.edit(vim.fn.stdpath("config") .. "/lua/carson/keymap.lua")
end)
vim.keymap.set("n", "<leader>ez", function()
	vim.cmd.edit("~/.zshrc")
end)
vim.keymap.set("n", "<leader>ei", function()
	vim.cmd.edit("~/.config/i3/config")
end)
vim.keymap.set("n", "<leader>es", function()
	vim.cmd.edit("~/.config/i3status/config")
end)
vim.keymap.set("n", "<leader>ex", "<cmd>Ex<cr>", { desc = "Open netrw" })

-- System clipboard yank/paste.
vim.keymap.set("x", "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })
vim.keymap.set("x", "<leader>Y", '"+d', { desc = "Cut selection to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("t", "<C-\\><C-\\>", "<C-\\><C-n><C-w><C-w>", { desc = "Escape Terminal and switch tabs" })
vim.keymap.set("n", "<leader>ai", "<cmd>60vsplit | term claude<cr>i", { desc = "split and open claude"})

vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'View line diagnostics' })
vim.keymap.set('n', '<leader>ch', function() 
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	vim.notify(string.format("Inlay Hint Enabled? %s", vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })))
end )
vim.keymap.set('n', '<leader>cl', function() 
	vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled()) 
	vim.notify(string.format("Code Lens Enabled? %s", vim.lsp.codelens.is_enabled({ bufnr = 0 })))
end )
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "List available Code Actions" })
vim.keymap.set('n', 'n', 'nzz', { remap = true } )
vim.keymap.set('n', 'N', 'Nzz', { remap = true } )

vim.keymap.set('n', ']c', ']czz', { remap = true } )
vim.keymap.set('n', '[c', '[czz', { remap = true } )

vim.keymap.set('t', '<ESC><ESC>', "<C-\\><C-n>", { desc = 'Easy Escape from terminal' }) 

-- Visual mode (move selection)
vim.keymap.set("n", "<A-j>", ":move +1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":move -2<CR>==", { noremap = true, silent = true })

vim.keymap.set("v", "<A-j>", ":move '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":move '<-2<CR>gv=gv", { noremap = true, silent = true })

-- TJ Deevs!
vim.keymap.set("n", "<leader>st", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0,15)
end)
