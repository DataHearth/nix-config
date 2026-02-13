{ ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./disko.nix
      # Uncomment after first boot + sbctl create-keys (see lanzaboote post-install steps)
      # ./lanzaboote.nix
      ./users.nix
      ./locales.nix
      ./modules.nix
      ./packages.nix
      ./services.nix
      ./systemd.nix
    ]
    ++ (import ../../modules/nixos);

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
    # LUKS device is managed by disko
  };

  security.pki.certificateFiles = [
    /mnt/development/cert1.pem
  ];

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
}
