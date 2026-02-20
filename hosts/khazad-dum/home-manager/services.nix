{ pkgs, ... }:
let
  mountPoint = "/run/media/datahearth/proton";
  secretsPath = "/run/secrets";
in
{
  systemd.user.services.rclone-proton = {
    Unit = {
      Description = "Mount ProtonDrive via rclone";
    };
    Service = {
      Type = "notify";
      ExecStartPre = pkgs.writeShellScript "rclone-proton-pre" ''
        # Clean up stale FUSE mount from a previous crash
        ${pkgs.fuse}/bin/fusermount -u ${mountPoint} 2>/dev/null || true
        # Wait for network connectivity
        until ${pkgs.iputils}/bin/ping -c 1 -W 2 proton.me > /dev/null 2>&1; do
          ${pkgs.coreutils}/bin/sleep 2
        done
      '';
      ExecStart = pkgs.writeShellScript "rclone-proton-mount" ''
        export RCLONE_PROTONDRIVE_USERNAME=$(${pkgs.coreutils}/bin/cat ${secretsPath}/rclone/protondrive/username)
        export RCLONE_PROTONDRIVE_PASSWORD=$(${pkgs.coreutils}/bin/cat ${secretsPath}/rclone/protondrive/password)
        export RCLONE_PROTONDRIVE_OTP_SECRET_KEY=$(${pkgs.coreutils}/bin/cat ${secretsPath}/rclone/protondrive/totp-secret)
        exec ${pkgs.rclone}/bin/rclone mount :protondrive: ${mountPoint} \
          --vfs-cache-mode full \
          --vfs-read-chunk-size 16M \
          --vfs-read-chunk-size-limit 256M \
          --buffer-size 64M \
          --log-file /tmp/rclone-proton.log \
          --log-level INFO
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  services = {
    udiskie.enable = true;

    ssh-agent.enable = true;

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-gnome3;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
