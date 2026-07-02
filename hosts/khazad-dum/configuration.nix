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

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # MT7922 (mt7921e) Wi-Fi intermittently fails its D3cold→D0 PCIe link
  # transition on s2idle resume, hanging the machine (only a power-button
  # hard reset recovers). disable_aspm=1 made it worse — every sleep hung
  # (5 of the last 6 shutdowns were suspend hangs). Attack both halves:
  #  - forbid D3cold on the card so the fatal link transition never happens
  #    (it still reaches D3hot; costs a little battery while suspended)
  #  - unload the driver across sleep so it re-probes with fresh firmware
  #    state on resume; iwd/NM reconnect on their own afterwards
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x0616", ATTR{d3cold_allowed}="0"
  '';
  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/modprobe -r mt7921e
  '';
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe mt7921e
  '';

  # Emulate aarch64 (via binfmt/QEMU) so the laptop can build and run
  # aarch64-linux binaries — e.g. cross-building for an ARM target.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.binfmt.preferStaticEmulators = true;

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
