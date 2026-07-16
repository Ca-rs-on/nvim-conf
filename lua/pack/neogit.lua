vim.pack.add({
	{ src = "https://github.com/neogitorg/neogit" },
	{ src = "https://github.com/sindrets/diffview.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" }
})

local neogit = require("neogit")
-- You can map this to a key
vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Open Neogit UI" })
vim.keymap.set("n", "<leader>gd", function()
	local view = require("diffview.lib").get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewOpen")
	end
end, { desc = "Diffview toggle" })

-- all history
vim.keymap.set("n", "<leader>gha", function()
	local view = require("diffview.lib").get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewFileHistory")
	end
end, { desc = "Diffview toggle" })

-- current file history
vim.keymap.set("n", "<leader>ghc", function()
	local view = require("diffview.lib").get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewFileHistory %")
	end
end, { desc = "Diffview toggle" })

-- current section of current file history
vim.keymap.set("v", "<leader>ghc", function()
	local view = require("diffview.lib").get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd(":'<,'>DiffviewFileHistory %")
	end
end, { desc = "Diffview toggle" })


require('gitsigns').setup {
	signs = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	},
	signs_staged = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' },
	},
	signs_staged_enable = true,
	signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
	numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
	linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
	word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
	watch_gitdir = {
		follow_files = true
	},
	auto_attach = true,
	attach_to_untracked = false,
	current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
		delay = 1000,
		ignore_whitespace = false,
		virt_text_priority = 100,
		use_focus = true,
	},
	current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
	blame_formatter = nil, -- Use default
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	max_file_length = 40000, -- Disable if file is longer than this (in lines)
	preview_config = {
		-- Options passed to nvim_open_win
		style = 'minimal',
		relative = 'cursor',
		row = 0,
		col = 1
	},
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local function map(l, r, desc)
			vim.keymap.set("n", l, r, { buffer = bufnr, desc = desc })
		end
		map("]c", function() gs.nav_hunk("next") end, "Next hunk")
		map("[c", function() gs.nav_hunk("prev") end, "Prev hunk")
		map("<leader>gp", gs.preview_hunk, "Preview hunk")
		map("<leader>gr", gs.reset_hunk, "Reset hunk")
		map("<leader>gb", gs.blame, "Blame line")
	end,
}
