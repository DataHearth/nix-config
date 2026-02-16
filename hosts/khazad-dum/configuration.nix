{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./lanzaboote.nix
    ./users.nix
    ./locales.nix
    ./modules.nix
    ./packages.nix
    ./services.nix
    ./systemd.nix
  ]
  ++ (import ../../modules/nixos);

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    age.keyFile = "${config.users.users.datahearth.home}/.config/sops/age/keys.txt";
    secrets = {
      "rclone/protondrive/username" = {
        owner = config.users.users.datahearth.name;
      };
      "rclone/protondrive/password" = {
        owner = config.users.users.datahearth.name;
      };
      "rclone/protondrive/totp-secret" = {
        owner = config.users.users.datahearth.name;
      };
    };
  };

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
  };

  security.pki.certificateFiles = [
    /mnt/development/cert1.pem
  ];

  networking = {
    hostName = "khazad-dum";
    wireless.iwd.enable = true;
    nftables.enable = true;
    firewall.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      unmanaged = [ "interface-name:tun*" ];
      insertNameservers = [
        # Cloudflare
        "1.1.1.1"
        "2606:4700:4700::1111"
        "1.0.0.1"
        "2606:4700:4700::1001"

        # Quad9
        "9.9.9.9"
        "2620:fe::fe"
        "149.112.112.112"
        "2620:fe::9"
      ];
    };
  };
}
