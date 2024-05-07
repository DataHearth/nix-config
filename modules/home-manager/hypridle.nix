{ config, lib, ... }:
let
  cfg = config.hm.hypridle;

  enable = lib.mkEnableOption "hypridle";
  enabledListeners = {
    brightness = lib.mkOption {
      type = lib.types.bool;
      description = "Enable brightness control";
      default = true;
    };
    lock = lib.mkOption {
      type = lib.types.bool;
      description = "Enable lock control";
      default = true;
    };
    monitors = lib.mkOption {
      type = lib.types.bool;
      description = "Enable monitors control";
      default = true;
    };
    suspend = lib.mkOption {
      type = lib.types.bool;
      description = "Enable suspend control";
      default = true;
    };
  };
  timeouts = {
    lowerBrightness = lib.mkOption {
      type = lib.types.int;
      description = "Duration before screens brightness is lowered";
      default = 120;
    };
    lock = lib.mkOption {
      type = lib.types.int;
      description = "Duration before locking session";
      default = 180;
    };
    displaysOff = lib.mkOption {
      type = lib.types.int;
      description = "Duration before screens are turned off";
      default = 210;
    };
    suspend = lib.mkOption {
      type = lib.types.int;
      description = "Duration before suspendind sessions";
      default = 300;
    };
  };
in {
  options.hm.hypridle = { inherit enable timeouts enabledListeners; };

  config = lib.mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        lock_cmd = "pidof hyprlock || hyprlock";
        unlock_cmd = "";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        listeners = [
          (lib.mkIf cfg.enabledListeners.brightness {
            timeout = cfg.timeouts.lowerBrightness;
            on_timeout = "brightnessctl -s set 10";
            on_resume = "brightnessctl -r";
          })
          (lib.mkIf cfg.enabledListeners.lock {
            timeout = cfg.timeouts.lock;
            on_timeout = "pidof hyprlock || hyprlock";
          })
          (lib.mkIf cfg.enabledListeners.monitors {
            timeout = cfg.timeouts.displaysOff;
            on_timeout = "hyprctl dispatch dpms off";
            on_resume = "hyprctl dispatch dpms on";
          })
          (lib.mkIf cfg.enabledListeners.suspend {
            timeout = cfg.timeouts.suspend;
            on_timeout = "systemctl suspend";
          })
        ];
      };
    };
  };
}
