{
  pkgs,
  default_user,
  state_version,
  ...
}:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
    ./ui.nix
  ] ++ (import ../../../modules/home-manager);
  home = {
    username = default_user;
    homeDirectory = "/home/${default_user}";
    stateVersion = state_version;
    shell.enableZshIntegration = true;
  };

  xdg = {
    enable = true;

    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      configPackages = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
