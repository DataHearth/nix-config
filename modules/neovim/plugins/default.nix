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
  coq-nvim = import ./coq-nvim.nix;
  coq-thirdparty = import ./coq-thirdparty.nix;
  copilot-vim = import ./copilot-vim.nix;
  lsp = import ./lsp.nix;
}
