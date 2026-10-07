vim.g.mapleader = " "

vim.cmd('colorscheme catppuccin')

require("carson.opt")
require("carson.keymap")
require("carson.completion")
require("carson.snippets")

-- insert with CTRL-K in insert mode, e.g. <C-k>fi
vim.cmd("digraphs fi 128293") -- 🔥
vim.cmd("digraphs pu 129326") -- 🤮
vim.cmd("digraphs ro 128640") -- 🚀
vim.cmd("digraphs ai 10024") -- ✨

vim.api.nvim_create_user_command("ProjCwd", function()
	local root = vim.fs.root(0, {".git"})
	if not root then
		return vim.notify("no project root found", vim.log.levels.WARN)
	end
	vim.cmd.cd(root)
end, { desc = "change cwd to project root" })

-- like vim's :DiffOrig: diff the buffer against the file on disk (:diffoff! to end)
vim.api.nvim_create_user_command("DiffOrig", function()
	local ft = vim.bo.filetype
	vim.cmd("vert new | set buftype=nofile bufhidden=wipe noswapfile | read ++edit # | 0d_")
	vim.bo.filetype = ft
	vim.cmd("diffthis | wincmd p | diffthis")
end, { desc = "diff buffer against file on disk" })
