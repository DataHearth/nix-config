{ config, ... }:
{
  imports = [
    ./modules.nix
    ./packages.nix
    ./services.nix
  ]
  ++ (import ../../../modules/home-manager);

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
    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/chrome" = "zen-beta.desktop";

        "text/html" = "zen-beta.desktop";

        "application/x-extension-htm" = "zen-beta.desktop";
        "application/x-extension-html" = "zen-beta.desktop";
        "application/x-extension-shtml" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "application/x-extension-xhtml" = "zen-beta.desktop";
        "application/x-extension-xht" = "zen-beta.desktop";
      };
    };
  };
}
