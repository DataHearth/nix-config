{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "hyprlock";
          before_sleep_cmd = "${pkgs.playerctl}/bin/playerctl pause --all-players && loginctl lock-session";
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
  };
}
