{ config, pkgs, ... }:
{
  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Fingerprint reader
  services.fprintd.enable = true;

  security.pam.services = {
    # Hyprlock PAM (required for password + fingerprint unlock)
    hyprlock = { };

    # Skip the fingerprint prompt for sudo while on AC, falling straight through
    # to the password prompt. Evaluated live at every sudo via pam_exec: on AC
    # the guard exits 0 and success=1 jumps over the fprintd line; on battery it
    # exits non-zero and default=ignore leaves fingerprint auth in place.
    sudo.rules.auth.gate-fprint-on-ac = {
      order = config.security.pam.services.sudo.rules.auth.fprintd.order - 1;
      control = "[success=1 default=ignore]";
      modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
      args = [
        "quiet"
        (toString (pkgs.writeShellScript "sudo-fprint-ac-guard" ''
          # exit 0 = on AC power -> PAM skips the fingerprint line (password prompt)
          # exit 1 = on battery -> fingerprint stays enabled
          for ps in /sys/class/power_supply/*; do
            [ "$(cat "$ps/type")" = "Mains" ] || continue
            [ "$(cat "$ps/online")" = "1" ] && exit 0
          done
          exit 1
        ''))
      ];
    };
  };

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    openFirewall = true;
  };

  # Removable device automounting
  services.udisks2.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Antivirus
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
}
