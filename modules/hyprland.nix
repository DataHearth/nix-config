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
      };
    };
  };

  default_user = lib.mkOption {
    type = lib.types.str;
    description = "Default user across NixOS configuration (NixOS and Home-Manager)";
  };
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
      home.packages = with pkgs; [
        eog
        gnome-calculator
        nautilus
      ];

      hm = {
        hyprland.enable = true;
        rofi-wayland.enable = true;
        swaync.enable = true;

        waybar = {
          enable = true;
          right = [
            "pulseaudio#output"
            "pulseaudio#input"
            "custom/spacer"
            "backlight"
            "custom/spacer"
            "battery"
            "custom/spacer"
            "custom/notification"
            "custom/spacer"
            "tray"
          ];
        };

        hyprlock = {
          enable = true;
          lockBackgroundImage = "~/Pictures/assets/locks/1.png";
          defaultDisplay = "eDP-1";
        };
      };

      services = {
        blueman-applet.enable = true;
        network-manager-applet.enable = true;

        kanshi = {
          enable = true;
          settings =
            let
              reload_waybar = "${pkgs.killall}/bin/killall -SIGUSR2 .waybar-wrapped";
            in
            [
              {
                profile.name = "nomad";
                profile.exec =
                  (map (v: "hyprctl dispatch moveworkspacetomonitor ${v} eDP-1") [
                    "1"
                    "2"
                    "3"
                    "4"
                    "5"
                    "6"
                    "7"
                    "8"
                    "9"
                    "0"
                  ])
                  ++ [
                    "hyprctl dispatch workspace 1"
                    "notify-send -i $HOME/Pictures/icons/nomad.svg 'Nomad mode' 'Hyprland displays switched to nomad configuration' -a 'Kanshi' -t 4000"
                    reload_waybar
                  ];
                profile.outputs = [ { criteria = "eDP-1"; } ];
              }
              {
                profile.name = "docked";
                profile.exec =
                  (map (v: "hyprctl dispatch moveworkspacetomonitor ${v.workspace} ${v.monitor}") [
                    {
                      workspace = "1";
                      monitor = "DP-4";
                    }
                    {
                      workspace = "2";
                      monitor = "DP-3";
                    }
                    {
                      workspace = "3";
                      monitor = "DP-4";
                    }
                    {
                      workspace = "4";
                      monitor = "DP-3";
                    }
                    {
                      workspace = "6";
                      monitor = "eDP-1";
                    }

                  ])
                  ++ [
                    "hyprctl dispatch workspace 1"
                    "notify-send -i $HOME/Pictures/icons/docked.svg 'Docked mode' 'Hyprland displays switched to docked configuration' -a 'Kanshi' -t 4000"
                    reload_waybar
                  ];
                profile.outputs = [
                  {
                    criteria = "eDP-1";
                  }
                  {
                    criteria = "AOC U2790B 0x0001E2B5";
                    scale = 2.0;
                  }
                  {
                    criteria = "Dell Inc. DELL S2715H PP92G5CH281L";
                  }
                ];
              }
            ];
        };
      };
    };
  };
}
