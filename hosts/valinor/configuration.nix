{
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
        "raid1"
        "dm-raid"
        "dm-mirror"

        "raid456" # required by dm-raid

        "dm-mod" # required by dm-raid,dm-mirror,dm-log
        "dm-region-hash" # required by dm-mirror
        "dm-log" # required by dm-mirror,dm-region-hash

        "md-mod" # required by raid1,raid456,dm-raid

        "dax" # required by dm-mod
        "xor" # required by async_xor
        "async_raid6_recov" # required by raid456
        "raid6_pq" # required by raid456,async_raid6_recov,async_pq
        "libcrc32c" # required by raid456
        "async_memcpy" # required by raid456
        "async_pq" # required by raid456
        "async_xor" # required by raid456,async_pq
        "async_tx" # required by raid456,async_raid6_recov,async_pq,async_xor,async_memcpy
      ];
    in
    {
      loader.systemd-boot.enable = true;
      # If I have the knowledge of which one is needed at boot
      # and the one only once mounted and checked, some kernel modules
      # could move the initrd.availableKernelModules
      initrd.kernelModules = kernel_modules;
      initrd.availableKernelModules = kernel_modules;
    };

  networking = {
    hostName = "Valinor";
    networkmanager.enable = true;

    firewall = {
      extraCommands = ''
        iptables -I INPUT 1 -s 172.16.0.0/12 -p tcp -d 192.168.1.0/24 -j ACCEPT
        iptables -I INPUT 2 -s 172.16.0.0/12 -p udp -d 192.168.1.0/24 -j ACCEPT
      '';
      allowedUDPPorts = [
        5353
        5540
      ];
      allowedTCPPorts = [
        5540
        9999
        5001
      ];
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
      "backups/gondoline/include.txt" = {
        format = "binary";
        sopsFile = ../../secrets/gondoline/include.txt;
      };
      "backups/gondoline/exclude.txt" = {
        format = "binary";
        sopsFile = ../../secrets/gondoline/exclude.txt;
      };
      "backups/protondrive/password" = { };
      "backups/protondrive/repository" = { };
      "backups/protondrive/ping_url" = { };
      "backups/protondrive/include.txt" = {
        format = "binary";
        sopsFile = ../../secrets/protondrive/include.txt;
      };
      "backups/protondrive/exclude.txt" = {
        format = "binary";
        sopsFile = ../../secrets/protondrive/exclude.txt;
      };
      "tailscale_keys/valinor" = { };
    };
  };

  nixos_modules = {
    nh = {
      enable = true;
      settings.flake = "${config.users.users.datahearth.home}/.config/nix-config";
    };
  };
}
