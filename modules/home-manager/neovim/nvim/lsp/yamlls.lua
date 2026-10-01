return {
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml' },
  settings = {
    yaml = {
      schemaStore = {
        enable = false,
        url = '',
      },
    },
  },
  -- Mutate in place: the client already holds a reference to config.settings.
  before_init = function(_, config)
    config.settings.yaml.schemas = require('schemastore').yaml.schemas()
  end,
}
