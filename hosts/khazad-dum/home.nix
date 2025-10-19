{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ]
  ++ (import ../../modules/home-manager);
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "25.05";
    shell.enableShellIntegration = true;
  };

  targets.genericLinux.enable = true;
  xdg = {
    enable = true;
    autostart.enable = true;
  };
}
