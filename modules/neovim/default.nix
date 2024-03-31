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
      options = {
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
        cmp-cmdline.enable = true;
        cmp-nvim-lsp.enable = true;
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
        luasnip.enable = true;
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
    };
  };
}
