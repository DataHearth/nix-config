{ ... }:
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

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    openFirewall = true;
  };

  # Firmware updates
  services.fwupd.enable = true;
}
