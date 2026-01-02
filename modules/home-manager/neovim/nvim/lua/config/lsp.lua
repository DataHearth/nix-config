-- Add blink.cmp capabilities to all LSP servers
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})

-- Enable LSP servers
vim.lsp.enable({
  'bashls',
  'dockerls',
  'eslint',
  'gopls',
  'html',
  'htmx',
  'jsonls',
  'lua_ls',
  'nixd',
  'pyright',
  'ruff',
  'rust_analyzer',
  'svelte',
  'tailwindcss',
  'taplo',
  'ts_ls',
  'yamlls',
})

-- LSP keymaps on attach
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }

    vim.keymap.set('n', '<S-k>', function()
      vim.lsp.buf.hover({ border = 'rounded' })
    end, opts)
    vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, opts)
  end,
})