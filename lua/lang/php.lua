vim.lsp.config("intelephense", {
  cmd = { "intelephense", "--stdio" },
  filetypes = { "php" },
  root_markers = { "composer.json", ".git" },
  settings = {
    intelephense = {
      -- e.g. files = { maxSize = 5000000 },  -- bump for large frameworks
      licenceKey = os.getenv("INTELEPHENSE_API_KEY"),  -- only if you have premium (see below)
    },
  },
})

vim.lsp.enable("intelephense")
