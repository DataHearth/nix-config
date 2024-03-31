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
        diffview.enable = true;
        chadtree.enable = true;
        leap.enable = true;
        nix.enable = true;
        comment.enable = true;
        todo-comments.enable = true;
        lualine.enable = true;
        luasnip.enable = true;
        nvim-autopairs.enable = true;
        illuminate.enable = true;
        copilot-cmp.enable = true;
        cmp_luasnip.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-cmdline.enable = true;
        cmp-path.enable = true;
        cmp-buffer.enable = true;
        crates-nvim.enable = true;
        treesitter.enable = true;
        telescope = import ./plugins/telescope.nix;
        trouble = import ./plugins/trouble.nix;
        indent-blankline = import ./plugins/indent-blankline.nix;
        dashboard = import ./plugins/dashboard.nix;
        gitsigns = import ./plugins/gitsigns.nix;
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

        # Completion
        lsp = import ./plugins/lsp.nix;

        ## CMP
        cmp = import ./plugins/cmp.nix;

        ### Thirdparties
        copilot-lua = import ./plugins/copilot-lua.nix;
      };
    };
  };
}
