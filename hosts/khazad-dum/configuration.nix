{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./i18n.nix
    ./hardware-configuration.nix
    ./services.nix
  ];
  system.stateVersion = "24.05";
  xdg.portal.enable = true;
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "datahearth"
      ];
    };
    gc = {
      dates = "weekly";
      automatic = true;
      options = "--delete-older-than 2d";
    };
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
    # https://community.frame.work/t/solved-fw16-not-powering-down/52659/4
    kernelPackages = pkgs.linuxPackages_latest;
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
      ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs =
      {
      };
    users = {
      "datahearth" = import ./home-manager/home.nix;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.hyprlock.enableGnomeKeyring = true;
  };

  networking = {
    hostName = "khazad-dum";
    networkmanager = {
      enable = true;
    };
  };

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
    virt-manager.enable = true;
  };

  environment = {
    shells = with pkgs; [
      zsh
      bash
    ];
    systemPackages = with pkgs; [
      sbctl
      pinentry
      home-manager
      docker
      looking-glass-client
      ntfs3g
      libheif
      libheif.out
      dig
      pavucontrol
    ];
    pathsToLink = [
      "share/thumbnailers"
      "/share/zsh"
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
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
}
