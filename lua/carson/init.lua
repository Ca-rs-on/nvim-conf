vim.g.mapleader = " "

vim.cmd('colorscheme catppuccin')

require("carson.opt")
require("carson.keymap")

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
