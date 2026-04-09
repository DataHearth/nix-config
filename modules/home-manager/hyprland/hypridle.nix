{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  hypridle-toggle = pkgs.writeShellScriptBin "hypridle-toggle" ''
    if systemctl --user is-active --quiet hypridle.service; then
      systemctl --user stop hypridle.service
      while systemctl --user is-active --quiet hypridle.service; do sleep 0.1; done
    else
      systemctl --user start hypridle.service
      while ! systemctl --user is-active --quiet hypridle.service; do sleep 0.1; done
    fi
    pkill -SIGRTMIN+8 waybar
  '';

  hypridle-sleep = pkgs.writeShellScriptBin "hypridle-sleep" ''
    if ! systemctl --user is-active --quiet hypridle.service; then
      systemctl --user start hypridle.service
      while ! systemctl --user is-active --quiet hypridle.service; do sleep 0.1; done
      pkill -SIGRTMIN+8 waybar
    fi
    systemctl suspend
  '';

  hypridle-status = pkgs.writeShellScriptBin "hypridle-status" ''
    if systemctl --user is-active --quiet hypridle.service; then
      echo '{"alt": "enabled", "tooltip": "Idle: enabled", "class": "enabled"}'
    else
      echo '{"alt": "disabled", "tooltip": "Idle: disabled", "class": "disabled"}'
    fi
  '';
in
{
  options.home_modules.hyprland.hypridle = {
    toggleScript = lib.mkOption {
      type = lib.types.package;
      default = hypridle-toggle;
      readOnly = true;
      description = "Script to toggle hypridle service";
    };
    statusScript = lib.mkOption {
      type = lib.types.package;
      default = hypridle-status;
      readOnly = true;
      description = "Script to get hypridle status for waybar";
    };
    sleepScript = lib.mkOption {
      type = lib.types.package;
      default = hypridle-sleep;
      readOnly = true;
      description = "Script to ensure hypridle is active before suspending";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      hypridle-toggle
      hypridle-status
      hypridle-sleep
    ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "${pkgs.hyprlock}/bin/hyprlock";
          before_sleep_cmd = "${pkgs.playerctl}/bin/playerctl pause --all-players && loginctl lock-session";
        };
        listener = [
          {
            timeout = 450; # 4:30min
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 600; # 10min
            on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
            on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && brightnessctl -r ";
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
