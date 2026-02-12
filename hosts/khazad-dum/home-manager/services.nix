{ pkgs, config, ... }:
let
  mountPoint = "/run/media/datahearth/proton";
in
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/secrets.yml;
    secrets = {
      "rclone/protondrive/username" = { };
      "rclone/protondrive/password" = { };
      "rclone/protondrive/totp-secret" = { };
    };
  };

  systemd.user.services.deeps-tunnel = {
    Unit = {
      Description = "SSH SOCKS proxy tunnel to deeps VM";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.openssh}/bin/ssh -D 1080 -N -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes deeps";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

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
          sleep 2
        done
      '';
      ExecStart = pkgs.writeShellScript "rclone-proton-mount" ''
        export RCLONE_PROTONDRIVE_USERNAME=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."rclone/protondrive/username".path})
        export RCLONE_PROTONDRIVE_PASSWORD=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."rclone/protondrive/password".path})
        export RCLONE_PROTONDRIVE_OTP_SECRET_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."rclone/protondrive/totp-secret".path})
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
