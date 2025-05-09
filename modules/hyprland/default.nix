{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixos_modules.hyprland;

  enable = lib.options.mkEnableOption "hyprland";
  settings = lib.options.mkOption {
    description = "Settings for the Hyprland window manager.";
    type = lib.types.submodule {
      options = {
        inherit default_user;
        inherit xwayland nvidia wallpaper;
        inherit waybar hyprlock kanshi;

        config = lib.options.mkOption {
          type = lib.types.attrs;
          description = "Custom Hyprland configuration";
          default = { };
        };
      };
    };
  };

  default_user = lib.options.mkOption {
    type = lib.types.str;
    description = "Default user across NixOS configuration (NixOS and Home-Manager)";
  };
  xwayland = lib.options.mkEnableOption "xwayland";
  nvidia = lib.mkEnableOption "nvidia";
  wallpaper = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    description = "Set wallpaper on Hyprland startup. String must be a valid path pointing to a file";
    default = null;
    example = "~/Pictures/wallpaper.jpg";
  };
  waybar = lib.mkEnableOption "waybar";
  hyprlock = lib.mkEnableOption "hyprlock";
  kanshi = lib.mkEnableOption "kanshi";
in
{
  options.nixos_modules.hyprland = {
    inherit enable settings;
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;

    services = {
      blueman.enable = true;
      power-profiles-daemon.enable = true;
      gnome.gnome-keyring.enable = true;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = 1;
    };

    home-manager.users."${cfg.settings.default_user}" = {
      imports = import ../home-manager;

      home.packages = with pkgs; [
        # GUI
        eog
        gnome-calculator
        nautilus

        # CLI
        alsa-utils
        playerctl
        brightnessctl
        wl-clipboard
        cliphist
        swww
      ];

      wayland.windowManager.hyprland =
        let
          baseCfg = builtins.fromJSON (builtins.readFile ./hyprland.json);
        in
        {
          enable = true;
          xwayland.enable = cfg.settings.xwayland;

          settings =
            baseCfg
            // cfg.settings.config
            // {
              env = lib.mkIf cfg.settings.nvidia [
                "WLR_NO_HARDWARE_CURSORS,1"
                "LIBVA_DRIVER_NAME,nvidia"
                "__GLX_VENDOR_LIBRARY_NAME,nvidia"
              ];
              exec-once =
                [
                  "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
                  "${pkgs.swww}/bin/swww-daemon"
                ]
                ++ lib.mkIf cfg.settings.wallpaper
                != null [ "${pkgs.swww}/bin/swww img ${cfg.settings.wallpaper}" ];
            };
        };

      home_modules = {
        hyprland.enable = true;
        rofi-wayland.enable = true; # Required for menus

        swaync.enable = cfg.settings.waybar; # Default notification daemon in waybar settings
        waybar = cfg.settings.waybar;
        hyprlock = cfg.settings.hyprlock;
      };

      services = {
        blueman-applet.enable = true;
        network-manager-applet.enable = true;
        kanshi.enable = cfg.settings.kanshi;
      };
    };
  };
}
