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

      # catppuccin/nix only fills in `home.pointerCursor.{name,package}`; Home
      # Manager deprecated inferring `enable` from those, so set it here.
      home.pointerCursor.enable = true;
      # catppuccin/nix's own cursors drv renders all 64 flavor/accent outputs,
      # isn't on cache.nixos.org, and rebuilds (~35 min) on every nixpkgs bump.
      # nixpkgs' package ships the same theme name and is Hydra-cached.
      home.pointerCursor.package = lib.mkForce pkgs.catppuccin-cursors.macchiatoMauve;

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
