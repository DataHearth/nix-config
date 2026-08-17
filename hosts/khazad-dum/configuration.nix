{
  config,
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

  # For cross-building and running ARM targets on this x86 laptop.
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  hardware.enableAllFirmware = true;
  hardware.enableAllHardware = true;

  sops = {
    defaultSopsFile = ../../secrets/secrets.yml;
    age.keyFile = "${config.users.users.datahearth.home}/.config/sops/age/keys.txt";
    secrets = {
      "wifi/cirdan" = { };
      "wifi/la-maison-du-bonheur" = { };
    };
    templates = {
      "wifi-cirdan-env".content = "WIFI_CIRDAN_PSK=${config.sops.placeholder."wifi/cirdan"}";
      "la-maison-du-bonheur-env".content = "WIFI_LA_MAISON_DU_BONHEUR_PSK=${
        config.sops.placeholder."wifi/la-maison-du-bonheur"
      }";
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
    # Tracks mainline rather than the nixpkgs default. This follows the newest
    # series, so `nix flake update` can cross a major bump (6.18 -> 7.1) with no
    # warning; framework-laptop-kmod is out-of-tree and has to build against
    # whatever lands, so check it after an update before switching.
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
