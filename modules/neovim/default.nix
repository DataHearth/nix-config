{ lib, config, pkgs, ... }:
let
  cfg = config.custom.neovim;

  enable = lib.mkEnableOption "neovim";
  defaultEditor = lib.mkOption {
    type = lib.types.bool;
    description = "Make NeoVim the default editor";
    default = true;
  };
  colorscheme = lib.mkOption {
    type = lib.types.str;
    description = "Neovim colorscheme";
    default = "catppuccin";
  };
in {
  options.custom.neovim = { inherit enable colorscheme defaultEditor; };

  config = lib.mkIf cfg.enable {
    environment = {
      variables.EDITOR = lib.mkIf cfg.defaultEditor "nvim";
      systemPackages = with pkgs; [
        nodePackages.prettier
        eslint_d
        gofumpt
        golines
        ruff
        stylua
        nixfmt-classic
        taplo
        rustfmt
        prettierd
      ];
    };

    programs.nixvim = {
      enable = true;
      type = "lua";
      viAlias = true;
      vimAlias = true;
      globals = { mapleader = " "; };
      colorscheme = cfg.colorscheme;
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
        cmp = import ./plugins/cmp.nix { lib = lib; };
        cmp-buffer.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lua.enable = true;
        cmp-path.enable = true;
        cmp_luasnip.enable = true;
        comment.enable = true; # Comment code
        conform-nvim = import ./plugins/conform-nvim.nix; # Formatting
        crates-nvim.enable = true; # Crate auto-complete and verification
        diffview.enable = true; # Git diff view
        gitsigns = import ./plugins/gitsigns.nix; # Git signs in status line
        illuminate.enable = true; # Highlight words
        indent-blankline = import ./plugins/indent-blankline.nix;
        lsp = import ./plugins/lsp.nix;
        lspkind.enable = true; # Beautify LSP
        lualine.enable = true; # Status line
        luasnip = {
          enable = true;
          fromVscode = [{ paths = ./snippets; }];
        }; # Snippets
        neogit.enable = true;
        nix.enable = true;
        nvim-autopairs.enable = true; # Auto close symbols
        telescope = import ./plugins/telescope.nix; # Find files
        todo-comments.enable = true; # Comments highlighting
        treesitter.enable = true;
        trouble = import ./plugins/trouble.nix; # Diagnotic

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
    };
  };
}
