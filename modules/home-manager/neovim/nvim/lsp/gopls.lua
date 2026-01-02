return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.work', 'go.mod' },
  settings = {
    gopls = {
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      analyses = {
        shadow = true,
      },
    },
  },
}