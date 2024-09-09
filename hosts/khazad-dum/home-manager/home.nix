{ pkgs, ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ] ++ (import ../../../modules/home-manager);
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.05";
  };

  xdg.enable = true;

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
    theme = {
      name = "Adwaita";
      package = pkgs.gnome.gnome-themes-extra;
    };
  };
}
