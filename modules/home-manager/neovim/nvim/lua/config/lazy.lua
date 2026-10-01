local nix = require("nix-paths")
vim.opt.rtp:prepend(nix.lazy)

-- Nix-shipped plugins live in pack/hm/start/* and are stripped by lazy's
-- default rtp reset. Re-add them so treesitter parsers/queries stay reachable.
local nix_pack_paths = vim.split(
  vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/hm/start/*"),
  "\n",
  { trimempty = true }
)

require("lazy").setup({
  -- Every plugin comes from the nix store (see ../../default.nix); a spec
  -- without a matching store entry fails instead of being cloned.
  dev = { path = nix.plugins, patterns = { "" }, fallback = false },
  install = { missing = false },
  rocks = { enabled = false },
  performance = {
    rtp = {
      paths = nix_pack_paths,
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  spec = {
    { import = "plugins" },
  },
})
