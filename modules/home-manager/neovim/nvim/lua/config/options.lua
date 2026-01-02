-- Basic options
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.undofile = true
opt.clipboard = "unnamedplus"
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable treesitter highlighting
vim.api.nvim_create_autocmd('FileType', {
  callback = function() pcall(vim.treesitter.start) end,
})
