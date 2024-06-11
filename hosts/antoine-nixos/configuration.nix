{ pkgs, lib, ... }:
let hostname = "antoine-nixos";
in {
  imports = let
    modules = ../../modules;
    shared = ../shared;
  in [
    "${modules}/passthrough.nix"
    "${modules}/nvidia.nix"
    "${modules}/neovim"

    "${shared}/i18n.nix"
    "${shared}/nix.nix"
    "${shared}/options.nix"
    "${shared}/security.nix"
    "${shared}/services.nix"

    ./hardware-configuration.nix
    ./services.nix
  ];
  system.stateVersion = "24.05";

  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
    hostName = hostname;
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
    ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    corefonts
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { };
    users = { "datahearth" = import ./home-manager/home.nix; };
  };

  programs = {
    steam.enable = true;
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };

  custom = { neovim.enable = true; };

  systemd.tmpfiles.rules =
    [ "f /dev/shm/looking-glass 0660 datahearth libvirtd -" ];

  fileSystems = let
    # this line prevents hanging on network split
    automount_opts =
      "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    smb_secrets = "/home/datahearth/.config/nix-config/smb-secrets";
  in {
    "/mnt/cronos/medias" = lib.mkForce {
      device = "//10.0.0.2/medias";
      fsType = "cifs";
      options = [ automount_opts "credentials=${smb_secrets}/cronos" ];
    };
    "/mnt/cronos/isos" = lib.mkForce {
      device = "//10.0.0.2/isos";
      fsType = "cifs";
      options = [ "${automount_opts},credentials=${smb_secrets}/cronos" ];
    };
    "/mnt/linux-games" = lib.mkForce {
      device = "/dev/disk/by-uuid/a0bd2373-edc1-4c95-aac1-85aa6c5bacc0";
      fsType = "ext4";
      options = [ automount_opts ];
    };
  };
}
