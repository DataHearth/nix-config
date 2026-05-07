local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Nix-shipped plugins live in pack/hm/start/* and are stripped by lazy's
-- default rtp reset. Re-add them so treesitter parsers/queries stay reachable.
local nix_pack_paths = vim.split(
  vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/hm/start/*"),
  "\n",
  { trimempty = true }
)

require("lazy").setup({
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
