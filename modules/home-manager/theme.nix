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
    enable = lib.mkEnableOption "Nordic GTK theme with Papirus icons";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;

      theme = {
        name = "Nordic";
        package = pkgs.nordic;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
        size = 24;
      };
    };

    home.pointerCursor = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    dconf.settings."org/gnome/desktop/interface" = {
      gtk-theme = "Nordic";
      icon-theme = "Papirus-Dark";
      cursor-theme = "Nordzy-cursors";
      color-scheme = "prefer-dark";
    };
  };
}
