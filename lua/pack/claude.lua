-- requires claude on system
-- opens claude in a centered floating window. hooks are injected at launch via
-- --settings (inline json) so nothing has to live outside this repo: they call
-- back into this nvim instance through $NVIM, which claude inherits from the
-- terminal buffer.
local M = {}

local state = {
	claude = {
		buf = nil,
		win = nil,
	}
}

local hook_cmd = function(kind)
	return string.format(
		[=[[ -z "$NVIM" ] || nvim --server "$NVIM" --remote-expr "v:lua.require'pack.claude'.on_hook('%s')" >/dev/null 2>&1 || true]=],
		kind)
end

local settings = vim.json.encode({
	hooks = {
		Stop = { { hooks = { { type = "command", command = hook_cmd("done") } } } },
		Notification = { { matcher = "permission_prompt", hooks = { { type = "command", command = hook_cmd("approval") } } } },
		PostToolUse = { { matcher = "Edit|Write", hooks = { { type = "command", command = hook_cmd("edit") } } } },
	},
})

function M.on_hook(kind)
	vim.schedule(function()
		if kind == "approval" then
			vim.notify("Claude is waiting on approval", vim.log.levels.WARN)
		elseif kind == "done" then
			vim.notify("Claude finished responding")
		elseif kind == "edit" then
			vim.cmd("checktime")
		end
	end)
	return ""
end

local on_exit = function()
	state.claude.buf = nil
	state.claude.win = nil
end

local win_opts = function()
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	return {
		relative = 'editor',
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		title = 'Claude',
		border = "double",
	}
end

local toggle = function()
	if state.claude.win and vim.api.nvim_win_is_valid(state.claude.win) then
		vim.api.nvim_win_hide(state.claude.win)
		state.claude.win = nil
		return
	end
	if not state.claude.buf or not vim.api.nvim_buf_is_valid(state.claude.buf) then
		state.claude.buf = vim.api.nvim_create_buf(false, true)
		state.claude.win = vim.api.nvim_open_win(state.claude.buf, true, win_opts())
		vim.fn.jobstart({ 'claude', '--settings', settings }, { term = true, on_exit = on_exit })
	else
		state.claude.win = vim.api.nvim_open_win(state.claude.buf, true, win_opts())
	end
end

vim.keymap.set("n", "<leader>ai", toggle)

return M
