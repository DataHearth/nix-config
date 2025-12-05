{ pkgs, ... }:
{
  services = {
    ssh-agent.enable = true;
    cliphist.enable = true;

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };

    hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock";
          before_sleep_cmd = "playerctl pause --all-players && loginctl lock-session";
        };
        listener = [
          {
            timeout = 450; # 4:30min
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 600; # 10min
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r ";
          }
          {
            timeout = 720; # 12min
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };

    hyprpaper = {
      enable = true;
      settings =
        let
          wallpaper_path = "~/.local/share/backgrounds/2025-10-19-18-43-55-uwp36741.png";
        in
        {
          preload = wallpaper_path;
          wallpaper = ", ${wallpaper_path}";
        };
    };
  };
}
