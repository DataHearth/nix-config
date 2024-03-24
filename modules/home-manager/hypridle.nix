{ config, options, lib, ...}:
with lib;
let
  cfg = config.hm.hypridle;

  enable = mkEnableOption "hypridle";
  timeouts = {
    lowerBrightness = mkOption {
      type = types.int;
      description = "Duration before screens brightness is lowered";
      default = 120;
    };
    lock = mkOption {
      type = types.int;
      description = "Duration before locking session";
      default = 180;
    };
    displaysOff = mkOption {
      type = types.int;
      description = "Duration before screens are turned off";
      default = 210;
    };
    suspend = mkOption {
      type = types.int;
      description = "Duration before suspendind sessions";
      default = 300;
    };
  };
in
{
  options.hm.hypridle = {
    inherit enable timeouts;
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      lockCmd = "pidof hyprlock || hyprlock";
      unlockCmd = "";
      beforeSleepCmd = "loginctl lock-session";
      afterSleepCmd = "hyprctl dispatch dpms on";
      listeners = [
        {
          timeout = cfg.timeouts.lowerBrightness;
          onTimeout = "brightnessctl -s set 10";
          onResume = "brightnessctl -r";
        }
        {
          timeout = cfg.timeouts.lock;
          onTimeout = "loginctl lock-session";
        }
        {
          timeout = cfg.timeouts.displaysOff;
          onTimeout = "hyprctl dispatch dpms off";
          onResume = "hyprctl dispatch dpms on";
        }
        {
          timeout = cfg.timeouts.suspend;
          onTimeout = "systemctl suspend";
        }
      ];
    };
  };
}
