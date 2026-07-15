vim.lsp.config("intelephense", {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = { "composer.json", ".git" },
  settings = {
    intelephense = {
      licenceKey = os.getenv("INTELEPHENSE_PRO_KEY"),  
    },
  },
})

vim.lsp.enable("intelephense")
