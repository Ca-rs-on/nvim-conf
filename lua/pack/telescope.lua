vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim'
})
telescope = require('telescope')
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set({ 'n', 'v' }, '<leader>fs', builtin.grep_string, { desc = 'Search under cursor' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help' })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Telescope oldfiles' })
vim.keymap.set('n', '<C-b>', function() builtin.lsp_references({ jump_type = "tab drop", include_declaration = false }) end, { desc = 'Find references' })
vim.keymap.set('n', '<C-f>', builtin.current_buffer_fuzzy_find, { desc = 'Search file' })

vim.keymap.set('n', 'gd', function()
	builtin.lsp_definitions({ jump_type = "tab drop" })
end, { desc = 'Go to definition' })

vim.keymap.set('n', 'gr', function()
	builtin.lsp_references({ include_declaration = false })
end, { desc = 'References' })
