{ }:
{
  telescope = import ./telescope.nix;
  treesitter = import ./treesitter.nix;
  trouble = import ./trouble.nix;
  todo-comments = import ./todo-comments.nix;
  lualine = import ./lualine.nix;
  autoclose = import ./autoclose.nix;
  comment-nvim = import ./comment-nvim.nix;
  # harpoon = import ./harpoon.nix { vimUtils = vimUtils; fetchFromGithub = fetchFromGithub; };
  illuminate = import ./illuminate.nix;
  indent-blankline = import ./indent-blankline.nix;
  leap = import ./leap.nix;
  nix = import ./nix.nix;
  dashboard = import ./dashboard.nix;
  gitsigns = import ./gitsigns.nix;
  chadtree = import ./chadtree.nix;
  luasnip = import ./luasnip.nix;

  # Completion
  lsp = import ./lsp.nix;

  ## CMP
  cmp = import ./cmp.nix;
  cmp_luasnip.enable = true;
  cmp-nvim-lsp.enable = true;
  cmp-cmdline.enable = true;
  cmp-path.enable = true;
  cmp-buffer.enable = true;
  crates-nvim.enable = true;

  ### Thirdparties
  copilot-lua = import ./copilot-lua.nix;
  copilot-cmp = import ./copilot-cmp.nix;

  ## COQ
  # coq-nvim = import ./coq-nvim.nix;
  # coq-thirdparty = import ./coq-thirdparty.nix;
}
