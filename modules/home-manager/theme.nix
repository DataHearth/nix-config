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

  config = lib.mkMerge [
    {
      # Pin autoEnable to suppress catppuccin/nix's auto-enroll deprecation
      # warning on every profile that imports this module (incl. ones that
      # leave the theme disabled, e.g. root). It tracks the theme module's
      # own enable state, so port enrollment is unchanged.
      catppuccin.autoEnable = cfg.enable;
    }
    (lib.mkIf cfg.enable {
      catppuccin = {
        enable = true;
        flavor = "macchiato";
        accent = "mauve";
      };

      catppuccin.cursors.enable = true;

      gtk = {
        enable = true;
        gtk4.theme = null;
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
    })
  ];
}
