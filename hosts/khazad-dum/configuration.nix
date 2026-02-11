{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./users.nix
    ./locales.nix
    ./services.nix
    ../../modules/nh.nix
    ../../modules/greetd.nix
  ];

  time.timeZone = "Europe/Paris";
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "datahearth"
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices."cryptroot" = {
      device = "/dev/disk/by-partlabel/LUKS";
    };
  };

  networking = {
    hostName = "khazad-dum";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd.enable = true;
    nftables.enable = true;
    firewall.enable = true;
  };

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

  # Desktop sessions
  programs.hyprland.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Display manager
  nixos_modules.greetd = {
    enable = true;
    greeter = "tuigreet";
  };

  # Docker
  virtualisation.docker.enable = true;

  # Polkit authentication agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Firmware updates
  services.fwupd.enable = true;

  # nh
  nixos_modules.nh = {
    enable = true;
    settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
  };
}
