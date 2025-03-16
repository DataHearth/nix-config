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
  system.stateVersion = "24.11";

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

    firewall = {
      extraCommands = ''
        iptables -I INPUT 1 -s 172.16.0.0/12 -p tcp -d 192.168.1.0/24 -j ACCEPT
        iptables -I INPUT 2 -s 172.16.0.0/12 -p udp -d 192.168.1.0/24 -j ACCEPT
      '';
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
      "backups/storj/include.txt" = {
        format = "binary";
        sopsFile = ../../secrets/storj/include.txt;
      };
      "backups/storj/exclude.txt" = {
        format = "binary";
        sopsFile = ../../secrets/storj/exclude.txt;
      };
      "backups/gondoline/include.txt" = {
        format = "binary";
        sopsFile = ../../secrets/gondoline/include.txt;
      };
    };
  };

  nixos_modules.nh.enable = true;
}
