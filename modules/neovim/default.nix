{ lib, config, options, fetchFromGithub, pkgs, ...}:
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
      keymaps = [
        {
          action = "<cmd>CHADopen<cr>";
          key = "<C-t>";
        }
      ];
      plugins = import ./plugins { };
    };
  };
}
