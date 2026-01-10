return {
  cmd = { 'taplo', 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { '*.toml', 'taplo.toml', '.taplo.toml' },
  settings = {
    evenBetterToml = {
      taplo = {
        configFile = {
          enabled = true,
        },
      },
    },
  },
}