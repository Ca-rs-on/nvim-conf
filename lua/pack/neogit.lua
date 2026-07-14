vim.pack.add({
  { src = "https://github.com/neogitorg/neogit" },
  { src = "https://github.com/sindrets/diffview.nvim" }
})

local neogit = require("neogit")
-- You can map this to a key
vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Open Neogit UI" })
