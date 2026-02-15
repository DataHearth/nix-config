{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.theme;
in
{
  options.home_modules.theme = {
    enable = lib.mkEnableOption "Catppuccin Macchiato theme";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      flavor = "macchiato";
      accent = "mauve";
    };

    catppuccin.cursors.enable = true;

    gtk = {
      enable = true;
      theme = {
        name = "catppuccin-macchiato-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          variant = "macchiato";
          accents = [ "mauve" ];
        };
      };
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
