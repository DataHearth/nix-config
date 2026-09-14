{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.power-profile;

  syncScript = pkgs.writeShellScript "power-profile-sync" ''
    cat=${pkgs.coreutils}/bin/cat
    stdbuf=${pkgs.coreutils}/bin/stdbuf
    upower=${pkgs.upower}/bin/upower
    powerprofilesctl=${pkgs.power-profiles-daemon}/bin/powerprofilesctl

    onAC=${cfg.onAC}
    onBattery=${cfg.onBattery}

    # Last power state acted on ("" until the first sync). Gating on it means we
    # only set a profile on an actual AC<->battery flip, not on every UPower
    # percentage tick -- which is also what lets a manual pick from the waybar
    # battery menu stand until the next transition.
    last=""

    on_ac() {
      for ps in /sys/class/power_supply/*; do
        [ "$("$cat" "$ps/type")" = "Mains" ] || continue
        [ "$("$cat" "$ps/online")" = "1" ] && return 0
      done
      return 1
    }

    sync() {
      if on_ac; then cur="ac"; else cur="battery"; fi
      [ "$cur" = "$last" ] && return
      last="$cur"
      if [ "$cur" = "ac" ]; then
        "$powerprofilesctl" set "$onAC"
      else
        "$powerprofilesctl" set "$onBattery"
      fi
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

  profileType = lib.types.enum [
    "power-saver"
    "balanced"
    "performance"
  ];
in
{
  options.home_modules.power-profile = {
    enable = lib.mkEnableOption "power-profiles-daemon profile switching on AC/battery transitions";

    onAC = lib.mkOption {
      type = profileType;
      default = "performance";
      description = "Profile selected when the charger is plugged in.";
    };

    onBattery = lib.mkOption {
      type = profileType;
      default = "power-saver";
      description = "Profile selected when running on battery.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.power-profile-sync = {
      Unit = {
        Description = "Select a power profile based on AC/battery power";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        # powerprofilesctl's polkit action (switch-profile) is allow_active, so
        # the caller needs a live graphical session -- not just the user bus.
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "simple";
        ExecStart = "${syncScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
