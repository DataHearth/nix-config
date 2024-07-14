{ pkgs, lib, inputs, ... }: {
  imports = let
    shared = ../shared;
    modules = ../../modules;
  in [
    "${modules}/neovim"

    "${shared}/i18n.nix"
    "${shared}/nix.nix"
    "${shared}/options.nix"
    "${shared}/services.nix"
    "${shared}/security.nix"

    ./hardware-configuration.nix
    ./services.nix
  ];
  system.stateVersion = "24.05";

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

  networking = {
    hostName = "antoine-framework";
    networkmanager = {
      enable = true;
      dns = "none";
    };
    nameservers = [
      "100.65.209.18"
      "fd7a:115c:a1e0::4641:d112"
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
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

  environment = {
    shells = with pkgs; [ zsh bash ];
    systemPackages = with pkgs; [
      pinentry
      home-manager
      docker
      looking-glass-client
      sbctl
    ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    corefonts
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users = { "datahearth" = import ./home-manager/home.nix; };
  };

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };

  custom = { neovim.enable = true; };
}
