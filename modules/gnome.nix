{
  config,
  lib,
  pkgs,
  zen-browser,
  default_user,
  ...
}:
let
  cfg = config.nixos_modules.gnome;

  enable = lib.options.mkEnableOption "gnome";
  settings = lib.options.mkOption {
    description = "Settings for the GNOME desktop environment.";
    type = lib.types.submodule {
      options = {
        inherit gdm autostart extensions;
      };
    };
  };

  gdm = lib.options.mkOption {
    description = "Enable GDM (GNOME Display Manager)";
    type = lib.types.bool;
    default = true;
  };
  autostart = lib.options.mkOption {
    description = "Enable auto-start for applications";
    type = lib.types.bool;
    default = true;
  };
  extensions = lib.options.mkOption {
    description = "GNOME Shell extensions to enable";
    type = lib.types.listOf lib.types.package;
    default = with pkgs.gnomeExtensions; [
      appindicator
      vitals
      blur-my-shell
      clipboard-indicator
    ];
  };
in
{
  options.nixos_modules.gnome = {
    inherit enable settings;
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !(
            config.services.blueman.enable
            || config.home-manager.users."${default_user}".services.blueman-applet.enable
          );
        message = "Gnome already ships a bluetooth software and applet. Please disable blueman service and/or its applet service";
      }
    ];

    services = {
      xserver.desktopManager.gnome.enable = true;
      udev.packages = with pkgs; [ gnome-settings-daemon ];
      pipewire.enable = true; # enable screen sharing

      xserver.displayManager.gdm.enable = cfg.settings.gdm;
      greetd.enable = !cfg.settings.gdm;
    };

    # enable screen sharing
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    home-manager.users."${default_user}" = {
      home = {
        sessionVariables = {
          NIXOS_OZONE_WL = 1;
        };
        packages = with pkgs; [
          wl-clipboard
        ];
      };

      xdg.autostart = {
        enable = true;
        readOnly = true;
        entries = [
          "${pkgs.signal-desktop}/share/applications/signal.desktop"
          "${pkgs.discord}/share/applications/discord.desktop"
          "${pkgs.alacritty}/share/applications/Alacritty.desktop"
          "${zen-browser.packages."${pkgs.system}".default}/share/applications/zen-beta.desktop"
        ];
      };

      programs = {
        # Not good looking with Gnome
        alacritty.settings.window.opacity = 1;

        gnome-shell = {
          enable = true;
          extensions = builtins.map (pkg: { package = pkg; }) cfg.settings.extensions;
        };
      };
    };
  };
}
