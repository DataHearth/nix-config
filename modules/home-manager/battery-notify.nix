{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.battery-notify;

  soundDir = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo";

  notifyScript = pkgs.writeShellScript "battery-notify" ''
    notify=${pkgs.libnotify}/bin/notify-send
    play=${pkgs.pipewire}/bin/pw-play
    cat=${pkgs.coreutils}/bin/cat
    stdbuf=${pkgs.coreutils}/bin/stdbuf
    gdbus=${pkgs.glib}/bin/gdbus
    upower=${pkgs.upower}/bin/upower

    low=${toString cfg.lowLevel}
    critical=${toString cfg.criticalLevel}
    interval=${toString cfg.interval}
    playSound=${lib.boolToString cfg.sound}
    lowSound=${cfg.lowSound}
    criticalSound=${cfg.criticalSound}

    # Highest alert already delivered this discharge episode
    # (0 = none, 1 = low, 2 = critical). Reset when plugged in or recovered,
    # so each threshold notifies exactly once per drain instead of on every wake.
    notified=0

    # D-Bus id of the critical notification currently on screen, so it can be
    # closed automatically as soon as the charger is plugged back in.
    criticalId=""

    # Read the battery once and act. Called at startup and on every UPower event.
    check_battery() {
      bat=""
      for candidate in /sys/class/power_supply/BAT*; do
        if [ -d "$candidate" ]; then
          bat=$candidate
          break
        fi
      done

      if [ -z "$bat" ]; then
        return
      fi

      capacity=$("$cat" "$bat/capacity")
      status=$("$cat" "$bat/status")

      if [ "$status" != "Discharging" ]; then
        # Plugged in / full: dismiss any lingering critical alert, then re-arm.
        if [ -n "$criticalId" ]; then
          "$gdbus" call --session --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.CloseNotification "$criticalId"
          criticalId=""
        fi
        notified=0
        return
      fi

      level=0
      if [ "$capacity" -le "$critical" ]; then
        level=2
      elif [ "$capacity" -le "$low" ]; then
        level=1
      fi

      if [ "$level" -eq 0 ]; then
        notified=0
      elif [ "$level" -gt "$notified" ]; then
        if [ "$level" -eq 2 ]; then
          # Critical urgency: swaync keeps it on screen until dismissed.
          # Capture the id so it can be auto-closed when the charger returns.
          criticalId=$("$notify" --app-name=Battery --urgency=critical \
            --icon=battery-caution --print-id \
            "Battery critically low" "$capacity% remaining — plug in now.")
          if [ "$playSound" = "true" ]; then
            "$play" "$criticalSound"
          fi
        else
          "$notify" --app-name=Battery --urgency=normal --icon=battery-low \
            "Battery low" "$capacity% remaining."
          if [ "$playSound" = "true" ]; then
            "$play" "$lowSound"
          fi
        fi
        notified=$level
      fi
    }

    # Evaluate once, then block on UPower's event stream: plugging in/out and
    # percentage updates each emit a line and wake us immediately. read's
    # timeout adds a periodic safety re-check in case an event is ever missed.
    # stdbuf forces line buffering so events aren't held in a pipe. The loop
    # runs in this shell (process substitution, not a pipe) so state persists.
    check_battery
    while true; do
      read -t "$interval" -r _
      rc=$?
      # rc 0 = event line; rc > 128 = read timeout (periodic re-check). Any
      # other code means the monitor stream closed — exit so systemd restarts
      # us and reconnects.
      if [ "$rc" -ne 0 ] && [ "$rc" -le 128 ]; then
        break
      fi
      check_battery
    done < <("$stdbuf" -oL "$upower" --monitor)

    # Reached only if the UPower stream ended; fail so the unit restarts.
    exit 1
  '';
in
{
  options.home_modules.battery-notify = {
    enable = lib.mkEnableOption "low/critical battery notifications with sound";

    lowLevel = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 20;
      description = "Battery percentage at or below which the low-battery notification fires.";
    };

    criticalLevel = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 10;
      description = "Battery percentage at or below which the persistent critical notification fires.";
    };

    interval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = ''
        Seconds between fallback battery re-checks. UPower events drive
        real-time reactions (plug in/out, percentage changes); this is only a
        safety net in case an event is ever missed.
      '';
    };

    sound = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Play a sound alongside each notification.";
    };

    lowSound = lib.mkOption {
      type = lib.types.str;
      default = "${soundDir}/dialog-warning.oga";
      defaultText = lib.literalExpression ''"''${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga"'';
      description = "Sound file played with the low-battery notification.";
    };

    criticalSound = lib.mkOption {
      type = lib.types.str;
      default = "${soundDir}/dialog-error.oga";
      defaultText = lib.literalExpression ''"''${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-error.oga"'';
      description = "Sound file played with the critical-battery notification.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.criticalLevel < cfg.lowLevel;
        message = "home_modules.battery-notify: criticalLevel (${toString cfg.criticalLevel}) must be below lowLevel (${toString cfg.lowLevel}).";
      }
    ];

    systemd.user.services.battery-notify = {
      Unit = {
        Description = "Low/critical battery notifications";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "simple";
        ExecStart = "${notifyScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
