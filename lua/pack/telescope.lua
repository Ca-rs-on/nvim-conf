vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim'
})
local actions = require('telescope.actions')

require('telescope').setup({
	defaults = {
		-- merged into the defaults, not a replacement for them
		mappings = {
			-- insert mode already has <Esc> and <C-c> closing the picker
			n = { ['qq'] = actions.close },
		},
	},
})

-- auto-generated theme pack
local wood = {
	bark  = '#7a5c3e', honey = '#d9a05b', moss  = '#97a06a',
	cream = '#ddcbb0', taupe = '#8a7863', ember = '#33261a',
	rust  = '#c2703f',
}
local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

hl('TelescopeNormal',        { fg = wood.cream, bg = 'NONE' })
hl('TelescopePromptNormal',  { fg = wood.cream, bg = 'NONE' })
hl('TelescopeResultsNormal', { fg = wood.cream, bg = 'NONE' })
hl('TelescopePreviewNormal', { bg = 'NONE' })

hl('TelescopeBorder',        { fg = wood.bark,  bg = 'NONE' })
hl('TelescopePromptBorder',  { fg = wood.honey, bg = 'NONE' })
hl('TelescopeTitle',         { fg = wood.taupe, bg = 'NONE' })
hl('TelescopePromptTitle',   { fg = wood.rust,  bold = true })
hl('TelescopeResultsTitle',  { fg = wood.bark })
hl('TelescopePreviewTitle',  { fg = wood.moss })
hl('TelescopePromptPrefix',  { fg = wood.rust })
hl('TelescopePromptCounter', { fg = wood.taupe })

hl('TelescopeSelection',         { fg = wood.cream, bg = wood.ember, bold = true })
hl('TelescopeSelectionCaret',    { fg = wood.rust,  bg = wood.ember })
hl('TelescopeMultiSelection',    { fg = wood.moss })
hl('TelescopeMultiIcon',         { fg = wood.moss })
hl('TelescopeResultsComment',    { fg = wood.taupe, italic = true })
hl('TelescopeResultsLineNr',     { fg = wood.bark })
hl('TelescopeResultsIdentifier', { fg = wood.moss })
hl('TelescopeResultsNumber',     { fg = wood.honey })

hl('TelescopeMatching',     { fg = wood.honey, bold = true })
hl('TelescopePreviewMatch', { fg = wood.ember, bg = wood.honey })
hl('TelescopePreviewLine',  { bg = wood.ember })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', function() builtin.find_files({ hidden = true }) end, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>faf', function()
	builtin.find_files( { no_ignore="true" } )
end, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fag', function()
	builtin.live_grep( { no_ignore="true" } )
end, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set({ 'n', 'v' }, '<leader>fs', builtin.grep_string, { desc = 'Search under cursor' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help' })
vim.keymap.set('n', '<leader>fo', builtin.oldfiles, { desc = 'Telescope oldfiles' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope keymaps' })
vim.keymap.set('n', '<leader>fr', builtin.registers, { desc = 'Telescope Registers' })
vim.keymap.set('n', '<C-b>', function() builtin.lsp_references({ jump_type = "tab drop", include_declaration = false }) end, { desc = 'Find references' })

vim.keymap.set('n', 'gd', function()
	builtin.lsp_definitions({ jump_type = "tab drop" })
end, { desc = 'Go to definition' })

vim.keymap.set('n', 'gr', function()
	builtin.lsp_references({ include_declaration = false })
end, { desc = 'References' })
