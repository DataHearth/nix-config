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
    systemd.user = {
      # logind emits Lock/Unlock/PrepareForSleep on D-Bus but locks nothing
      # itself; something has to listen. hypridle used to be that listener, and
      # it is stopped on AC, so every lock path died with it. This daemon
      # listens unconditionally and translates the signals into user targets.
      # Since 2.4.0 it also holds a sleep inhibitor for as long as it runs, so
      # units pulled in by sleep.target get to finish before the machine goes
      # down rather than racing the suspend.
      services.systemd-lock-handler = {
        Unit = {
          Description = "Logind lock event to systemd target translation";
          Documentation = "https://sr.ht/~whynothugo/systemd-lock-handler";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "notify";
          Slice = "session.slice";
          ExecStart = "${pkgs.systemd-lock-handler}/lib/systemd-lock-handler";
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      services.hyprlock = {
        Unit = {
          Description = "Screen locker";
          # hyprlock exits 0 once the password is accepted; unlock.target then
          # stops lock.target, and PartOf drags the locker down with it. That is
          # also what makes an external `loginctl unlock-session` work.
          OnSuccess = [ "unlock.target" ];
          PartOf = [ "lock.target" ];
          After = [ "lock.target" ];
        };
        Service = {
          # Upstream's recommended readiness trick is Type=forking with a locker
          # that forks only once the screen is actually covered (swaylock -f).
          # hyprlock has no such flag, so systemd calls this started at exec and
          # the lock is merely very likely -- not guaranteed -- to be painted
          # before the suspend proceeds.
          Type = "simple";
          ExecStart = lib.getExe pkgs.hyprlock;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "lock.target" ];
      };

      # WantedBy sleep.target rather than lock.target: pausing playback belongs
      # to suspending, not to every idle lock, where the music should keep going.
      # The `-` prefix tolerates playerctl's non-zero exit when no player is up.
      services.playerctl-pause = {
        Unit = {
          Description = "Pause all media players before sleep";
          PartOf = [ "sleep.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "-${lib.getExe pkgs.playerctl} pause --all-players";
        };
        Install.WantedBy = [ "sleep.target" ];
      };

      targets = {
        lock.Unit = {
          Description = "Lock the current session";
          Conflicts = [ "unlock.target" ];
        };
        unlock.Unit = {
          Description = "Unlock the current session";
          Conflicts = [ "lock.target" ];
        };
        sleep.Unit = {
          Description = "System is about to sleep";
          # Pulling lock.target in here is what makes the screen lock on the way
          # into a suspend -- including a lid close on AC, where hypridle is
          # stopped and nothing else would have fired.
          Requires = [ "lock.target" ];
          After = [ "lock.target" ];
        };
      };
    };
  };
}
