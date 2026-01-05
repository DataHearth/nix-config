{ config, nixGL, ... }:
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
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.go/bin"
      "/usr/local/go/bin"
    ];
    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/.go";
      NIXOS_OZONE_WL = 1;
    };
  };

  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = nixGL.packages;
      defaultWrapper = "mesa";
      installScripts = [ "mesa" ];
    };
  };
  xdg = {
    enable = true;
    autostart.enable = true;
  };
}
