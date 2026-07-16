vim.lsp.config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'ts', 'vue', 'js' },
  root_markers = {
    'eslint.config.js', 'eslint.config.mjs', 'eslint.config.ts',
    '.eslintrc', '.eslintrc.js', '.eslintrc.json', 'package.json', '.git',
  },
  settings = {
    validate = 'on',
    run = 'onType',            -- or 'onSave'
    format = true,
    workingDirectory = { mode = 'auto' },  -- finds config in subfolders, not just cwd
    -- do NOT set experimental.useFlatConfig on ESLint 9+ (see below)
    codeAction = {
      disableRuleComment = { enable = true, location = 'separateLine' },
      showDocumentation = { enable = true },
    },
  },
  handlers = {
    ['eslint/confirmESLintExecution'] = function(_, result)
      if not result then return end
      return 4 -- approved; without this it silently won't lint
    end,
    ['eslint/openDoc'] = function(_, result)
      if result then vim.ui.open(result.url) end
      return {}
    end,
    ['eslint/probeFailed'] = function()
      vim.notify('ESLint probe failed', vim.log.levels.WARN)
      return {}
    end,
    ['eslint/noLibrary'] = function()
      vim.notify('ESLint library not found for this project', vim.log.levels.WARN)
      return {}
    end,
  },
})
vim.lsp.enable('eslint')
