vim.g.mapleader = " "

vim.cmd('colorscheme catppuccin')

require("carson.opt")
require("carson.keymap")

vim.api.nvim_create_user_command("ProjCwd", function()
	local root = vim.fs.root(0, {".git"})
	if not root then
		return vim.notify("no project root found", vim.log.levels.WARN)
	end
	vim.cmd.cd(root)
end, { desc = "change cwd to project root" })
