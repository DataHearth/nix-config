{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ../../modules/neovim
    ./i18n.nix
    ./hardware-configuration.nix
    ./services.nix
  ];
  system.stateVersion = "24.05";
  virtualisation.docker.enable = true;
  xdg.portal.enable = true;
  custom.neovim.enable = true;
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    nixPath = [
      "nixos-config=$HOME/.config/nix-config/hosts/${config.networking.hostName}/configuration.nix"
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
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
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.datahearth = {
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = { "datahearth" = import ./home-manager/home.nix; };
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
      insertNameservers = [
        "100.116.195.57"
        "fd7a:115c:a1e0::f201:c339"
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };
  };

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };

  environment = {
    shells = with pkgs; [ zsh bash ];
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
    ];
    pathsToLink = [ "share/thumbnailers" "/share/zsh" ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    corefonts
  ];
}
