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
