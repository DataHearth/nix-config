{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  hypridle-toggle = pkgs.writeShellScriptBin "hypridle-toggle" ''
    # Taking manual control pins the state: hypridle-power-sync stops overriding
    # it on AC/battery changes until the marker clears at logout.
    touch "$XDG_RUNTIME_DIR/hypridle-manual"
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

  hypridle-auto = pkgs.writeShellScriptBin "hypridle-auto" ''
    # Drop the manual pin and restart the sync so hypridle immediately snaps
    # back to whatever the current power source dictates.
    rm -f "$XDG_RUNTIME_DIR/hypridle-manual"
    systemctl --user restart hypridle-power-sync.service
  '';

  hypridle-power-sync = pkgs.writeShellScript "hypridle-power-sync" ''
    cat=${pkgs.coreutils}/bin/cat
    stdbuf=${pkgs.coreutils}/bin/stdbuf
    upower=${pkgs.upower}/bin/upower
    systemctl=${pkgs.systemd}/bin/systemctl
    pkill=${pkgs.procps}/bin/pkill

    # Set by hypridle-toggle when the user takes manual control; while it exists
    # we leave hypridle exactly as they set it. Lives in the runtime dir, so it
    # clears at logout and automatic power control resumes next session.
    marker="$XDG_RUNTIME_DIR/hypridle-manual"

    # Last power state acted on ("" until the first sync). Gating on it means we
    # only start/stop hypridle and poke waybar on an actual AC<->battery flip,
    # not on every UPower percentage tick.
    last=""

    on_ac() {
      for ps in /sys/class/power_supply/*; do
        [ "$("$cat" "$ps/type")" = "Mains" ] || continue
        [ "$("$cat" "$ps/online")" = "1" ] && return 0
      done
      return 1
    }

    sync() {
      # Manual toggle wins: once the user has taken control this session, leave
      # hypridle exactly as they set it.
      [ -e "$marker" ] && return
      if on_ac; then cur="ac"; else cur="battery"; fi
      [ "$cur" = "$last" ] && return
      last="$cur"
      # AC -> stop hypridle (screen never auto-idles/locks); battery -> start it.
      if [ "$cur" = "ac" ]; then
        "$systemctl" --user stop hypridle.service
      else
        "$systemctl" --user start hypridle.service
      fi
      "$pkill" -SIGRTMIN+8 waybar
    }

    # Evaluate once, then block on UPower's event stream: plugging in/out wakes
    # us immediately. Process substitution (not a pipe) keeps $last across
    # iterations; read's timeout is a periodic safety re-check if an event is
    # ever missed.
    sync
    while true; do
      read -t 60 -r _
      rc=$?
      if [ "$rc" -ne 0 ] && [ "$rc" -le 128 ]; then
        break
      fi
      sync
    done < <("$stdbuf" -oL "$upower" --monitor)

    # Reached only if the UPower stream ended; fail so systemd restarts us.
    exit 1
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
    autoScript = lib.mkOption {
      type = lib.types.package;
      default = hypridle-auto;
      readOnly = true;
      description = "Script to re-enable automatic power-based hypridle control";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      hypridle-toggle
      hypridle-status
      hypridle-sleep
      hypridle-auto
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

    # Drive hypridle from power source: off on AC, on on battery. Manual toggles
    # (Super+I / waybar click) still apply between transitions.
    systemd.user.services.hypridle-power-sync = {
      Unit = {
        Description = "Toggle hypridle based on AC/battery power";
        After = [
          "graphical-session.target"
          "hypridle.service"
        ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        Type = "simple";
        ExecStart = "${hypridle-power-sync}";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
