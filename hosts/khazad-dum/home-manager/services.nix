{ pkgs, lib, ... }:
{
  services = {
    playerctld.enable = true;
    ssh-agent.enable = true;
    blueman-applet.enable = lib.mkDefault true;
    network-manager-applet.enable = true;

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

    kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "nomad";
          profile.exec = [
            "notify-send -i $HOME/Pictures/icons/docked.svg 'Docked mode' 'Hyprland displays switched to docked configuration' -a 'Kanshi' -t 4000"
          ];
          profile.outputs = [ { criteria = "eDP-1"; } ];
        }
        {
          profile.name = "docked";
          profile.exec = [
            "hyprctl dispatch moveworkspacetomonitor 1 DP-4"
            "hyprctl dispatch moveworkspacetomonitor 2 DP-3"
            "hyprctl dispatch moveworkspacetomonitor 3 DP-4"
            "hyprctl dispatch moveworkspacetomonitor 4 DP-3"
            "hyprctl dispatch moveworkspacetomonitor 6 eDP-1"
            "hyprctl dispatch workspace 1"
            "notify-send -i $HOME/Pictures/icons/docked.svg 'Docked mode' 'Hyprland displays switched to docked configuration' -a 'Kanshi' -t 4000"
          ];
          profile.outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
            }
            {
              criteria = "AOC U2790B 0x0001E2B5";
              mode = "3840x2160@60.00Hz";
              scale = 2.0;
              position = "1600,0";
            }
            {
              criteria = "Dell Inc. DELL S2715H PP92G5CH281L";
              mode = "1920x1080@60.00Hz";
              position = "3510,0";
            }
          ];
        }
      ];
    };
  };
}
