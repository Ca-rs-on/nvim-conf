vim.pack.add({
  { src = "https://github.com/neogitorg/neogit" },
})

local neogit = require("neogit")
-- You can map this to a key
vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Open Neogit UI" })
