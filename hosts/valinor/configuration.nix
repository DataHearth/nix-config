{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    ./users.nix
    ./locales.nix
    ./services.nix
    ./systemd.nix
    ../../modules/nh.nix
  ];

  time.timeZone = "Europe/Paris";
  virtualisation.docker.enable = true;
  system.stateVersion = "24.05";

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

  boot =
    let
      kernel_modules = [
        "md-mod"
        "dm-mod"
        "dm-raid"
        "dm-mirror"
        "dm-region-hash"
        "dm-log"
        "raid1"
        "raid456"
        "async_raid6_recov"
        "async_memcpy"
        "async_pq"
        "async_xor"
        "async_tx"
      ];
    in
    {
      loader.systemd-boot.enable = true;
      kernelPackages = pkgs.linuxPackages_latest;
      # If I have the knowledge of which one is needed at boot
      # and the one only once mounted and checked, some kernel modules
      # could move the initrd.availableKernelModules
      initrd.kernelModules = kernel_modules;
      initrd.availableKernelModules = kernel_modules;
    };

  networking = {
    hostName = "valinor";
    networkmanager.enable = true;

    firewall =
      let
        tcp_udp = [
          53 # AdGuardHome DNS
        ];
      in
      {
        allowedUDPPorts =
          [
          ]
          ++ tcp_udp;
        allowedTCPPorts = [
          3000 # AdGuardHome WebUI
        ] ++ tcp_udp;
      };
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.users.users.datahearth.home}/.config/sops/age/keys.txt";

    secrets = {
      "backups/gondoline/password" = { };
      "backups/gondoline/repository" = { };
      "backups/gondoline/ping_url" = { };
      "backups/storj/password" = { };
      "backups/storj/repository" = { };
      "backups/storj/ping_url" = { };
      "tailscale_keys/valinor" = { };
    };
  };

  nixos_modules.nh.enable = true;
}
