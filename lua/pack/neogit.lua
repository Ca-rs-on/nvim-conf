vim.pack.add({
  { src = "https://github.com/neogitorg/neogit" },
  { src = "https://github.com/sindrets/diffview.nvim" }
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
