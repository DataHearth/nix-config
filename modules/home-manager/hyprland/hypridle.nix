{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.hyprland;

  hypridle-toggle = pkgs.writeShellScriptBin "hypridle-toggle" ''
    # A toggle holds only until the next AC<->battery transition, at which point
    # hypridle-power-sync takes the state back.
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
    # hypridle owns before_sleep_cmd and the logind lock signal, so it has to be
    # running for the suspend to pause media and lock the session.
    if ! systemctl --user is-active --quiet hypridle.service; then
      systemctl --user start hypridle.service
      while ! systemctl --user is-active --quiet hypridle.service; do sleep 0.1; done
      pkill -SIGRTMIN+8 waybar
    fi

    # The suspend job only completes once the machine has resumed, so systemctl
    # blocks here and everything below runs after the wake.
    systemctl suspend

    # Starting hypridle above may have contradicted the power state, and the sync
    # only acts on transitions -- so it would sit on a stale decision. Restarting
    # it forces a fresh evaluation, and it pokes waybar itself.
    systemctl --user restart hypridle-power-sync.service
  '';

  hypridle-status = pkgs.writeShellScriptBin "hypridle-status" ''
    if systemctl --user is-active --quiet hypridle.service; then
      echo '{"alt": "enabled", "tooltip": "Idle: enabled", "class": "enabled"}'
    else
      echo '{"alt": "disabled", "tooltip": "Idle: disabled", "class": "disabled"}'
    fi
  '';

  hypridle-power-sync = pkgs.writeShellScript "hypridle-power-sync" ''
    cat=${pkgs.coreutils}/bin/cat
    sleep=${pkgs.coreutils}/bin/sleep
    stdbuf=${pkgs.coreutils}/bin/stdbuf
    upower=${pkgs.upower}/bin/upower
    systemctl=${pkgs.systemd}/bin/systemctl
    awk=${pkgs.gawk}/bin/awk
    pgrep=${pkgs.procps}/bin/pgrep
    pkill=${pkgs.procps}/bin/pkill

    # Last power state acted on ("" until the first sync). Gating on it means we
    # only touch hypridle on an actual AC<->battery flip, not on every UPower
    # percentage tick -- which is also what lets a manual toggle stand until the
    # next transition.
    last=""

    on_ac() {
      for ps in /sys/class/power_supply/*; do
        [ "$("$cat" "$ps/type")" = "Mains" ] || continue
        [ "$("$cat" "$ps/online")" = "1" ] && return 0
      done
      return 1
    }

    # Waybar arms its SIGRTMIN+8 handler only after it has finished loading its
    # modules, roughly a second after exec. Until then the signal hits the
    # default disposition for a real-time signal -- terminate -- so poking a
    # still-initialising waybar kills it outright: no crash, no core dump, no
    # log line. The first sync below runs ~1s into the session, squarely inside
    # that window, which is why waybar never survived login. Wait for the
    # handler to actually appear (SigCgt bit) before signalling.
    poke_waybar() {
      i=0
      while [ "$i" -lt 50 ]; do
        i=$((i + 1))
        # comm is ".waybar-wrapped", so match on a substring rather than -x.
        pid="$("$pgrep" -o waybar)"
        # No waybar process at all: either it is not the configured bar, or it
        # has yet to be exec'd -- in which case it reads hypridle's state itself
        # on startup. Nothing to poke, and nothing to wait for.
        [ -n "$pid" ] || return
        if [ -r "/proc/$pid/status" ]; then
          # SigCgt is a 64-bit hex mask of caught signals: bit N-1 is signal N,
          # and SIGRTMIN+8 is signal 42 under glibc (where SIGRTMIN is 34).
          cgt="$("$awk" '/^SigCgt:/ { print $2 }' "/proc/$pid/status")"
          if [ -n "$cgt" ] && [ "$((0x$cgt >> 41 & 1))" -eq 1 ]; then
            "$pkill" -SIGRTMIN+8 waybar
            return
          fi
        fi
        "$sleep" 0.1
      done
    }

    sync() {
      if on_ac; then cur="ac"; else cur="battery"; fi
      [ "$cur" = "$last" ] && return
      last="$cur"
      # AC -> stop hypridle (screen never auto-idles/locks); battery -> start it.
      if [ "$cur" = "ac" ]; then
        "$systemctl" --user stop hypridle.service
      else
        "$systemctl" --user start hypridle.service
      fi
      poke_waybar
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

    # Drive hypridle from power source: off on AC, on on battery.
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
