return {
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc' },
  settings = {
    json = { validate = { enable = true } },
  },
  -- Mutate in place: the client already holds a reference to config.settings.
  before_init = function(_, config)
    config.settings.json.schemas = require('schemastore').json.schemas()
  end,
}
