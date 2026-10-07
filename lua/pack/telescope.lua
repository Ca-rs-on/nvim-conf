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
			n = { ['qq'] = actions.close }, },
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
local action_state = require('telescope.actions.state')

-- with(defaults) -> picker fn that merges cycle opts over the defaults
local function with(picker, defaults)
	return function(opts) picker(vim.tbl_extend('force', defaults or {}, opts)) end
end

-- <leader>f* pickers, in the order <C-h>/<C-l> cycles through them
local cycle = {
	{ key = 'ff',  desc = 'Find files',             fn = with(builtin.find_files, { hidden = true }) },
	{ key = 'faf', desc = 'Find all files',         fn = with(builtin.find_files, { no_ignore = true, hidden = true }) },
	{ key = 'fg',  desc = 'Live grep',              fn = with(builtin.live_grep) },
	{ key = 'fag', desc = 'Live grep all files',    fn = with(builtin.live_grep, { no_ignore = true, hidden = true }) },
	{ key = 'fs',  desc = 'Search under cursor',    fn = with(builtin.grep_string), mode = { 'n', 'v' } },
	{ key = 'fm',  desc = 'Functions in file',      fn = with(builtin.lsp_document_symbols, { symbols = { 'function', 'method' } }),
		-- needs a language server, else telescope just errors and the cycle dead-ends
		usable = function() return #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/documentSymbol' }) > 0 end },
	{ key = 'fb',  desc = 'Buffers',                fn = with(builtin.buffers) },
	{ key = 'fo',  desc = 'Oldfiles',               fn = with(builtin.oldfiles) },
	{ key = 'fh',  desc = 'Help',                   fn = with(builtin.help_tags) },
	{ key = 'fk',  desc = 'Keymaps',                fn = with(builtin.keymaps) },
	{ key = 'fr',  desc = 'Registers',              fn = with(builtin.registers) },
}

local function usable(p) return not p.usable or p.usable() end

local open
-- close this picker and open its next usable neighbour, carrying the typed prompt over
local function step(prompt_bufnr, i, dir)
	local text = action_state.get_current_line()
	actions.close(prompt_bufnr) -- back in the original buffer, so usable() checks that
	local n = i
	for _ = 1, #cycle do
		n = (n - 1 + dir) % #cycle + 1
		if usable(cycle[n]) then break end
	end
	open(n, text)
end

-- "ff faf [fg] fag ..." so you can see where <C-h>/<C-l> will land
local function tabs(i)
	local keys = {}
	for j, p in ipairs(cycle) do
		if j == i then
			keys[#keys + 1] = '[' .. p.key .. ']'
		elseif usable(p) then
			keys[#keys + 1] = p.key
		end
	end
	return table.concat(keys, ' ')
end

open = function(i, text)
	local p = cycle[i]
	p.fn({
		prompt_title = ('%s  %s'):format(p.desc, tabs(i)),
		default_text = text,
		attach_mappings = function(_, map)
			map({ 'i', 'n' }, '<C-l>', function(bufnr) step(bufnr, i, 1) end)
			map({ 'i', 'n' }, '<C-h>', function(bufnr) step(bufnr, i, -1) end)
			return true
		end,
	})
end

for i, p in ipairs(cycle) do
	vim.keymap.set(p.mode or 'n', '<leader>' .. p.key, function() open(i) end, { desc = 'Telescope ' .. p.desc:lower() })
end

vim.keymap.set('n', '<C-b>', function() builtin.lsp_references({ jump_type = "tab drop", include_declaration = false }) end, { desc = 'Find references' })

vim.keymap.set('n', 'gd', function()
	builtin.lsp_definitions({ jump_type = "tab drop" })
end, { desc = 'Go to definition' })

vim.keymap.set('n', 'gr', function()
	builtin.lsp_references({ include_declaration = false })
end, { desc = 'References' })
