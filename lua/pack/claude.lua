-- requires claude on system
-- idea is that you can open it up in a floating window instead of term on a split
local state = {
	claude = {
		buf = nil,
		win = nil,
	}
}

local on_exit = function()
	state.claude.buf = nil
	state.claude.win = nil
end
local toggle = function()
	local width = math.floor(vim.o.columns / 2)
	local height = vim.o.lines
	local opts = { relative= 'editor', width=width, height=height, col=0, row=0, anchor= 'NE', title='Claude', border = { "╔", "═" ,"╗", "║", "╝", "═", "╚", "║"  } }

	if not state.claude.buf or state.claude.claude == 0 then
		state.claude.buf = vim.api.nvim_create_buf(false, true)
		state.claude.win = vim.api.nvim_open_win(state.claude.buf, true, opts)
		vim.fn.jobstart({ 'claude' }, { term = true, on_exit = on_exit })
	elseif not state.claude.win or not vim.api.nvim_win_is_valid(state.claude.win) then
		state.claude.win = vim.api.nvim_open_win(state.claude.buf, true, opts)
	end

end

vim.keymap.set("n", "<leader>ai", toggle)
