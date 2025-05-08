{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.gnome;

  enable = lib.options.mkEnableOption "gnome";
  settings = lib.options.mkOption {
    description = "Settings for the GNOME desktop environment.";
    type = lib.types.submodule {
      options = {
        inherit gdm;
      };
    };
  };

  gdm = lib.options.mkOption {
    description = "Enable GDM (GNOME Display Manager)";
    type = lib.types.bool;
    default = true;
  };
in
{
  options.nixos_modules.gnome = {
    inherit enable settings;
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = 1;
    };

    services = {
      xserver.desktopManager.gnome.enable = true;
      udev.packages = with pkgs; [ gnome-settings-daemon ];

      xserver.displayManager.gdm.enable = cfg.settings.gdm;
      greetd.enable = !cfg.settings.gdm;
    };

    home-manager.users.datahearth = {
      programs.gnome-shell = {
        enable = true;
        extensions = with pkgs; [ { package = gnomeExtensions.appindicator; } ];
      };
    };
  };
}
