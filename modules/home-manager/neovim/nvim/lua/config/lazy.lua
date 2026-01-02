require("lazy").setup({
  performance = {
    reset_packpath = false,
    rtp = { reset = false },
  },
  checker = { enabled = false },
  spec = {
    { import = "plugins" },
  },
})
