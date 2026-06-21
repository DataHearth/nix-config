{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.greetd;

  enable = lib.mkEnableOption "greetd display manager";
in
{
  options.nixos_modules.greetd = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.greetd.enableGnomeKeyring = true;
    services.gnome.gnome-keyring.enable = true;

    programs.regreet = {
      enable = true;
      theme = {
        name = "catppuccin-macchiato-mauve-standard";
        package = pkgs.catppuccin-gtk.override {
          variant = "macchiato";
          accents = [ "mauve" ];
        };
      };
      cursorTheme = {
        name = "catppuccin-macchiato-mauve-cursors";
        package = pkgs.catppuccin-cursors.macchiatoMauve;
      };
    };
  };
}
