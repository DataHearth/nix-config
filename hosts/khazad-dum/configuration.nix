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

  # Emulate aarch64 (via binfmt/QEMU) so the laptop can build and run
  # aarch64-linux binaries — e.g. cross-building for an ARM target.
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
      "claude-code/github-mcp" = {
        owner = config.users.users.datahearth.name;
      };
      "claude-code/context7-mcp" = {
        owner = config.users.users.datahearth.name;
      };
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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
