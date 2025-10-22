{ config, ... }:
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
    sessionVariables = {
      NIXOS_OZONE_WL = 1;
    };
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.go/bin"
      "/usr/local/go/bin"
    ];
    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/.go";
    };
  };

  targets.genericLinux.enable = true;
  xdg = {
    enable = true;
    autostart.enable = true;
  };
}
