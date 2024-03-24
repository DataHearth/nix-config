{ config, options, lib, ...}:
with lib;
let
  cfg = config.hm.hypridle;

  enable = mkEnableOption "hypridle";
  enabledListeners = {
    brightness = mkOption {
      type = types.bool;
      description = "Enable brightness control";
      default = true;
    };
    lock = mkOption {
      type = types.bool;
      description = "Enable lock control";
      default = true;
    };
    monitors = mkOption {
      type = types.bool;
      description = "Enable monitors control";
      default = true;
    };
    suspend = mkOption {
      type = types.bool;
      description = "Enable suspend control";
      default = true;
    };
  };
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
    inherit enable timeouts enabledListeners;
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      lockCmd = "pidof hyprlock || hyprlock";
      unlockCmd = "";
      beforeSleepCmd = "loginctl lock-session";
      afterSleepCmd = "hyprctl dispatch dpms on";
      listeners = [
        (mkIf cfg.enabledListeners.brightness {
          timeout = cfg.timeouts.lowerBrightness;
          onTimeout = "brightnessctl -s set 10";
          onResume = "brightnessctl -r";
        })
        (mkIf cfg.enabledListeners.lock {
          timeout = cfg.timeouts.lock;
          onTimeout = "pidof hyprlock || hyprlock";
        })
        (mkIf cfg.enabledListeners.monitors {
          timeout = cfg.timeouts.displaysOff;
          onTimeout = "hyprctl dispatch dpms off";
          onResume = "hyprctl dispatch dpms on";
        })
        (mkIf cfg.enabledListeners.suspend {
          timeout = cfg.timeouts.suspend;
          onTimeout = "systemctl suspend";
        })
      ];
    };
  };
}
