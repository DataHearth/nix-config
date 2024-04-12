{ lib, config, options, pkgs, ...}:
with lib;
let
  cfg = config.custom.neovim;

  enable = mkEnableOption "neovim";
  defaultEditor = mkOption {
    type = types.bool;
    description = "Make NeoVim the default editor";
    default = true;
  };
  colorscheme = mkOption {
    type = types.str;
    description = "Neovim colorscheme";
    default = "catppuccin";
  };
in
{
  options.custom.neovim = {
    inherit enable colorscheme defaultEditor;
  };

  config = mkIf cfg.enable {
    environment.variables.EDITOR = mkIf cfg.defaultEditor "nvim";

    programs.nixvim = {
      enable = true;
      type = "lua";
      viAlias = true;
      vimAlias = true;
      colorscheme = cfg.colorscheme;
      globals = {
        mapleader = " ";
      };
      opts = {
        tabstop = 2;
        expandtab = true;
        softtabstop = 2;
        shiftwidth = 2;
        number = true;
      };
      colorschemes.catppuccin = {
        enable = true;
        transparentBackground = true;
        flavour = "macchiato";
      };
      keymaps = import ./keymaps;
      plugins = {
        barbecue.enable = true;
        chadtree.enable = true;
        cmp = import ./plugins/cmp.nix { lib = lib; };
        cmp-buffer.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lua.enable = true;
        cmp-path.enable = true;
        cmp_luasnip.enable = true;
        comment.enable = true;
        copilot-cmp.enable = true;
        copilot-lua = import ./plugins/copilot-lua.nix;
        crates-nvim.enable = true;
        dashboard = import ./plugins/dashboard.nix;
        diffview.enable = true;
        gitsigns = import ./plugins/gitsigns.nix;
        illuminate.enable = true;
        indent-blankline = import ./plugins/indent-blankline.nix;
        leap.enable = true;
        lsp = import ./plugins/lsp.nix;
        lspkind.enable = true;
        lualine.enable = true;
        luasnip = {
          enable = true;
          fromVscode = [
            {
              paths = ./snippets;
            }
          ];
        };
        nix.enable = true;
        nvim-autopairs.enable = true;
        telescope = import ./plugins/telescope.nix;
        todo-comments.enable = true;
        treesitter.enable = true;
        trouble = import ./plugins/trouble.nix;

        # Custom
        harpoon = {
          enable = true;
          package = pkgs.vimUtils.buildVimPlugin {
            name = "harpoon2";
            src = pkgs.fetchFromGitHub {
              owner = "ThePrimeagen";
              repo = "harpoon";
              rev = "a38be6e0dd4c6db66997deab71fc4453ace97f9c";
              hash = "sha256-RjwNUuKQpLkRBX3F9o25Vqvpu3Ah1TCFQ5Dk4jXhsbI=";
            };
          };
        };
      };
      extraPlugins = [
        {
          config = ''
          lua require("gotests").setup()
          '';
          plugin = pkgs.vimUtils.buildVimPlugin {
            name = "gotests.nvim";
            src = pkgs.fetchFromGitHub {
              owner = "yanskun";
              repo = "gotests.nvim";
              rev = "2ddd2a3d43a7ab92cc14f6a2f84291d991a30c2d";
              hash = "sha256-OHUK2pv9VHKzSuFRo3e1Y7Akjmjbs+jjxi6NaXHqeCk=";
            };
          };
        }
        {
          plugin = pkgs.vimUtils.buildVimPlugin {
            name = "vim-go-impl";
            src = pkgs.fetchFromGitHub {
              owner = "rhysd";
              repo = "vim-go-impl";
              rev = "74988dc3958f68355b9d4a3ffaa97a74d0006248";
              hash = "sha256-oPjULtIQpIf5qrCbaiybOCaB4zJDmrBuCretyXPViCM=";
            };
          };
        }
      ];
    };
  };
}
