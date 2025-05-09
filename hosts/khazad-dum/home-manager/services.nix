{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    ssh-agent.enable = true;

    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };

    gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };

    kanshi.settings = lib.mkIf config.services.kanshi.enable [
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
            "${pkgs.hyprland}/bin/hyprctl dispatch workspace 1"
            "notify-send -i $HOME/Pictures/icons/nomad.svg 'Nomad mode' 'Hyprland displays switched to nomad configuration' -a 'Kanshi' -t 4000"
            (lib.mkIf config.nixos_modules.hyprland.setttings.waybar "${pkgs.killall}/bin/killall -SIGUSR2 .waybar-wrapped")
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
            "${pkgs.hyprland}/bin/hyprctl dispatch workspace 1"
            "notify-send -i $HOME/Pictures/icons/docked.svg 'Docked mode' 'Hyprland displays switched to docked configuration' -a 'Kanshi' -t 4000"
            (lib.mkIf config.nixos_modules.hyprland.setttings.waybar "${pkgs.killall}/bin/killall -SIGUSR2 .waybar-wrapped")
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
}
