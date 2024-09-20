{ pkgs, ... }:
{
  imports = [ ./plugins ];

  viAlias = true;
  vimAlias = true;
  globals = {
    mapleader = " ";
  };
  colorscheme = "catppuccin";
  opts = {
    tabstop = 2;
    expandtab = true;
    softtabstop = 2;
    shiftwidth = 2;
    number = true;
    foldmethod = "expr";
    foldlevel = 20;
    foldexpr = "nvim_treesitter#foldexpr()";
  };
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      transparent_background = true;
      flavour = "macchiato";
    };
  };
  keymaps = import ./keymaps;
  plugins = {
    barbecue.enable = true; # Symbol bar
    chadtree.enable = true; # Tree navigation
    cmp-buffer.enable = true;
    cmp-nvim-lsp-signature-help.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-nvim-lua.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;
    comment.enable = true; # Comment code
    indent-blankline.enable = true;
    todo-comments.enable = true; # Comments highlighting
    treesitter.enable = true;
    crates-nvim.enable = true; # Crate auto-complete and verification
    diffview.enable = true; # Git diff view
    illuminate.enable = true; # Highlight words
    lspkind.enable = true; # Beautify LSP
    lualine.enable = true; # Status line
    luasnip = {
      enable = true;
      fromVscode = [ { paths = ./snippets; } ];
    }; # Snippets
    neogit.enable = true;
    nix.enable = true;
    nvim-autopairs.enable = true; # Auto close symbols
    which-key.enable = true;

    # Custom
    harpoon = {
      enable = true;
      package = pkgs.vimUtils.buildVimPlugin {
        name = "harpoon2";
        src = pkgs.fetchFromGitHub {
          owner = "ThePrimeagen";
          repo = "harpoon";
          rev = "0378a6c428a0bed6a2781d459d7943843f374bce";
          hash = "sha256-FZQH38E02HuRPIPAog/nWM55FuBxKp8AyrEldFkoLYk=";
        };
      };
    };
  };
  extraPlugins = with pkgs; [
    vimPlugins.nvim-ts-autotag
    (vimUtils.buildVimPlugin {
      name = "earthly.vim";
      src = fetchFromGitHub {
        owner = "earthly";
        repo = "earthly.vim";
        rev = "cb0440a357a09fb9234ece56a6b09e04d25c1b1d";
        hash = "sha256-myMGiOiU9/xmdMJOvaJySLBvXS/xTAMULVaKGaVODw0=";
      };
    })
  ];
  extraConfigLua = ''
    require('nvim-ts-autotag').setup()
  '';
}
