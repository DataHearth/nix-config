{ config, ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ]
  ++ (import ../../modules/home-manager);

  fonts.fontconfig.enable = true;

  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "25.05";
    shell.enableShellIntegration = true;
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.cargo/bin"
      "${config.home.homeDirectory}/.go/bin"
    ];

    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/.go";
      NIXOS_OZONE_WL = 1;
    };
  };

  xdg = {
    enable = true;
    autostart.enable = true;
  };
}
