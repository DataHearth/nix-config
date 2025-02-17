{ pkgs, config, ... }:
{
  systemd = {
    timers = {
      "storj-backup" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          onActiveSec = "2d";
          OnBootSec = "5min";
          OnCalendar = "*-*-* 02:00:00";
        };
      };
      "gondoline-backup" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          onActiveSec = "2d";
          OnBootSec = "5min";
          OnCalendar = "*-*-* 02:00:00";
        };
      };
    };

    services =
      let
        path = with pkgs; [
          restic
          rclone
          curl
        ];
        environment = {
          HOME = config.users.users.datahearth.home;
          XDG_CACHE_HOME = "${config.users.users.datahearth.home}/.cache";
          XDG_CONFIG_HOME = "${config.users.users.datahearth.home}/.config";
        };
        backups_secrets = "/run/secrets/backups";
      in
      {
        NetworkManager-wait-online.enable = false;
        "storj-backup" =
          let
            storj_secrets = "${backups_secrets}/storj";
          in
          {
            inherit path;

            serviceConfig.Type = "oneshot";
            environment = {
              RESTIC_REPOSITORY_FILE = "${storj_secrets}/repository";
              RESTIC_PASSWORD_FILE = "${storj_secrets}/password";
            } // environment;
            script = ''
              restic backup \
                --files-from ''${XDG_CONFIG_HOME}/systemd-timers/backup/allowed.txt \
                --exclude-file ''${XDG_CONFIG_HOME}/systemd-timers/backup/exclude.txt

              restic forget --keep-last 2 --prune

              curl -fsS -m 10 --retry 5 -o /dev/null $(cat ${storj_secrets}/ping_url)
            '';
          };
        "gondoline-backup" =
          let
            gondoline_secrets = "${backups_secrets}/gondoline";
          in
          {
            inherit path;

            serviceConfig.Type = "oneshot";
            environment = {
              RESTIC_REPOSITORY_FILE = "${gondoline_secrets}/repository";
              RESTIC_PASSWORD_FILE = "${gondoline_secrets}/password";
            } // environment;
            script = ''
              restic backup --files-from ''${XDG_CONFIG_HOME}/systemd-timers/gondoline-backup/allowed.txt

              restic forget --keep-last 2 --prune

              curl -fsS -m 10 --retry 5 -o /dev/null $(cat ${gondoline_secrets}/ping_url)
            '';
          };
      };
  };
}
