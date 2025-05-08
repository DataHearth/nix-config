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
        inherit gdm autostart;
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

    environment.sessionVariables = {
      NIXOS_OZONE_WL = 1;
    };

    services = {
      xserver.desktopManager.gnome.enable = true;
      udev.packages = with pkgs; [ gnome-settings-daemon ];

      xserver.displayManager.gdm.enable = cfg.settings.gdm;
      greetd.enable = !cfg.settings.gdm;
    };

    home-manager.users."${default_user}" = {
      # TODO: enable when 25.05 is released
      # xdg.autostart = {
      #   enable = true;
      #   entries = [ ];
      #   readOnly = true;
      # };
      xdg.configFile = lib.mkIf cfg.settings.autostart {
        "autostart/signal-desktop.desktop".source =
          "${pkgs.signal-desktop}/share/applications/signal-desktop.desktop";
        "autostart/discord.desktop".source = "${pkgs.discord}/share/applications/discord.desktop";
        "autostart/Alacritty.desktop".source = "${pkgs.alacritty}/share/applications/Alacritty.desktop";
        "autostart/zen-beta.desktop".source = "${
          zen-browser.packages."${pkgs.system}".default
        }/share/applications/zen-beta.desktop";
      };

      programs = {
        # Not good looking with Gnome
        alacritty.settings.window.opacity = 1;

        gnome-shell = {
          enable = true;
          extensions = with pkgs; [
            { package = gnomeExtensions.appindicator; }
            { package = gnomeExtensions.vitals; }
            { package = gnomeExtensions.blur-my-shell; }
          ];
        };
      };
    };
  };
}
