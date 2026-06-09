{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./lanzaboote.nix
    ./users.nix
    ./locales.nix
    ./modules.nix
    ./network.nix
    ./packages.nix
    ./services.nix
    ./systemd.nix
  ]
  ++ (import ../../modules/nixos);

  # boot.kernelModules = [ "iptable_mangle" ];

  # Pinned to the 6.12 LTS series. F5's svpn (closed binary; EPI is enforced
  # so openconnect is not an option) sends rtnetlink route/rule attributes
  # that kernel 6.18.34's stricter netlink validation rejects — "netlink:
  # 'svpn': attribute type N has an invalid length" — so the VPN tunnel never
  # finishes connecting and loops endlessly (6.18.33 still accepts them,
  # confirmed by booting the .33 generation). The client version is irrelevant
  # (7261/7262 share the same svpn route code). 6.12 LTS predates the change
  # and is still maintained (auto security patches). Revisit once F5 ships a
  # client that builds valid netlink, or a newer series re-tolerates it.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # boot.kernelPatches = [
  #   {
  #     name = "enable-iptables-legacy-mangle";
  #     patch = null;
  #     structuredExtraConfig = with lib.kernel; {
  #       NETFILTER_XTABLES_LEGACY = yes;
  #       IP_NF_IPTABLES_LEGACY = module;
  #       IP_NF_MANGLE = module;
  #     };
  #   }
  # ];

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
      "claude-code/github-mcp" = {
        owner = config.users.users.datahearth.name;
      };
      "claude-code/context7-mcp" = {
        owner = config.users.users.datahearth.name;
      };
      "wifi/cirdan" = { };
    };
    templates."wifi-cirdan-env" = {
      content = "WIFI_CIRDAN_PSK=${config.sops.placeholder."wifi/cirdan"}";
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
}
