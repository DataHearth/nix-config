{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./i18n.nix
    ./hardware-configuration.nix
    ./services.nix
    ../../modules/nh.nix
  ];
  system.stateVersion = "24.11";
  nixpkgs.config.allowUnfree = true;
  systemd.services.NetworkManager-wait-online.enable = false;

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

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
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;

    users.datahearth = {
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "wireshark"
        "libvirtd"
        config.services.kubo.group
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { };
    users.datahearth = import ./home-manager/home.nix;
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.hyprlock.enableGnomeKeyring = true;
  };

  networking = {
    hostName = "Khazad-dum";
    firewall.extraCommands = ''
      iptables -I INPUT 1 -s 172.16.0.0/12 -p tcp -d 192.168.1.0/24 -j ACCEPT
      iptables -I INPUT 2 -s 172.16.0.0/12 -p udp -d 192.168.1.0/24 -j ACCEPT
    '';
    networkmanager.enable = true;
  };

  programs = {
    hyprland.enable = true;
    wireshark.enable = true;
    virt-manager.enable = true;
    localsend.enable = true;

    zsh = {
      enable = true;
      promptInit = ''
        source <(docker completion zsh)
        source <(ipfs commands completion zsh)
      '';
    };
  };

  environment = {
    shells = with pkgs; [
      zsh
      bashInteractive
    ];
    systemPackages = with pkgs; [
      sbctl
      pinentry
      ntfs3g
      libheif
      libheif.out
    ];
    pathsToLink = [
      # required for Nautilus thumbnails with HEIC -> https://github.com/NixOS/nixpkgs/issues/164021#issuecomment-2078013231
      "/share/thumbnailers"

      # required by home-manager -> zsh.enableCompletion
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enableCompletion
      "/share/zsh"

      # required by home-manager -> xdg.portal
      # https://nix-community.github.io/home-manager/options.xhtml#opt-xdg.portal.enable
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "Mononoki"
        "JetBrainsMono"
      ];
    })
    corefonts
  ];

  nixos_modules.nh.enable = true;
}
