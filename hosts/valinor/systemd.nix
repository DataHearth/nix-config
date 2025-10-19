{ pkgs, config, ... }:
{
  systemd = {
    timers = {
      "critical-backup" = {
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
          docker
        ];
        environment = {
          HOME = config.users.users.datahearth.home;
          XDG_CACHE_HOME = "${config.users.users.datahearth.home}/.cache";
          XDG_CONFIG_HOME = "${config.users.users.datahearth.home}/.config";
        };
        backups_secrets = "/run/secrets/backups";
        pgsql16_bak = "/tmp/pgsql16-backup.sql";
        pgsql17_bak = "/tmp/pgsql17-backup.sql";
      in
      {
        NetworkManager-wait-online.enable = false;
        "critical-backup" =
          let
            protondrive_secrets = "${backups_secrets}/protondrive";
          in
          {
            inherit path;

            serviceConfig.Type = "oneshot";
            environment = {
              RESTIC_REPOSITORY_FILE = "${protondrive_secrets}/repository";
              RESTIC_PASSWORD_FILE = "${protondrive_secrets}/password";
              RCLONE_PROTONDRIVE_REPLACE_EXISTING_DRAFT = "true";
            }
            // environment;
            script = ''
              docker compose -f /mnt/Erebor/War-goats/appdata/docker-compose.yml exec -it postgresql16 pg_dumpall -U postgres > ${pgsql16_bak}
              docker compose -f /mnt/Erebor/War-goats/appdata/docker-compose.yml exec -it postgresql17 pg_dumpall -U postgres > ${pgsql17_bak}

              restic backup \
                --files-from ${protondrive_secrets}/include.txt \
                --exclude-file ${protondrive_secrets}/exclude.txt \
                ${pgsql16_bak} ${pgsql17_bak}

              restic forget --keep-last 2 --prune

              curl -fsS -m 10 --retry 5 -o /dev/null $(cat ${protondrive_secrets}/ping_url)
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
            }
            // environment;
            script = ''
              docker compose -f /mnt/Erebor/War-goats/appdata/docker-compose.yml exec -it postgresql16 pg_dumpall -U postgres > ${pgsql16_bak}
              docker compose -f /mnt/Erebor/War-goats/appdata/docker-compose.yml exec -it postgresql17 pg_dumpall -U postgres > ${pgsql17_bak}

              restic backup \
                --files-from ${gondoline_secrets}/include.txt \
                --exclude-file ${gondoline_secrets}/exclude.txt \
                ${pgsql16_bak} ${pgsql17_bak}

              restic forget --keep-last 2 --prune

              curl -fsS -m 10 --retry 5 -o /dev/null $(cat ${gondoline_secrets}/ping_url)
            '';
          };
      };
  };
}
