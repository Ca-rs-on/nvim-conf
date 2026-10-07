vim.lsp.config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
  -- only start where an eslint config exists, rooted at that config
  root_markers = {
    'eslint.config.js', 'eslint.config.mjs', 'eslint.config.cjs',
    'eslint.config.ts', 'eslint.config.mts', 'eslint.config.cts',
    '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml',
  },
  -- the server reads these keys without nil checks, so they all need a value
  settings = {
    validate = 'on',
    run = 'onType',            -- or 'onSave'
    format = true,
    quiet = false,
    onIgnoredFiles = 'off',
    useESLintClass = false,
    experimental = {},         -- do NOT set experimental.useFlatConfig on ESLint 9+
    rulesCustomizations = {},
    problems = { shortenToSingleLine = false },
    nodePath = '',
    codeActionOnSave = { enable = false, mode = 'all' },
    workingDirectory = { mode = 'auto' },  -- finds config in subfolders, not just cwd
    codeAction = {
      disableRuleComment = { enable = true, location = 'separateLine' },
      showDocumentation = { enable = true },
    },
  },
  -- workspaceFolder is a VS Code concept the server needs to bound its config search
  before_init = function(_, config)
    if config.root_dir then
      config.settings.workspaceFolder = {
        uri = config.root_dir,
        name = vim.fn.fnamemodify(config.root_dir, ':t'),
      }
    end
  end,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspEslintFixAll', function()
      client:request_sync('workspace/executeCommand', {
        command = 'eslint.applyAllFixes',
        arguments = { { uri = vim.uri_from_bufnr(bufnr), version = vim.lsp.util.buf_versions[bufnr] } },
      }, nil, bufnr)
    end, { desc = 'apply all eslint fixes' })
  end,
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
