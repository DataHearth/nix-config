{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    # Modules
    ../../modules/linux/passthrough.nix
    ../../modules/linux/nvidia.nix
    inputs.home-manager.nixosModules.default

    # Normal configuration
    ./hardware-configuration.nix
    ./systemd.nix
    ./services.nix
  ];
  # Nix configuration
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    hostName = "antoine-nixos";
    nameservers = [
      "10.0.0.3"
      "fe80::5054:ff:fe61:6a2a"
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    wireless.enable = false;
    dhcpcd.extraConfig = "nohook resolv.conf";
    networkmanager.dns = "none";
  };

  # Hardware
  hardware.pulseaudio.enable = false;
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };
  
  # Time
  time.timeZone = "Europe/Paris";

  # International properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable sound with pipewire.
  sound.enable = true;
  security.rtkit.enable = true;
  security.pam.services.swaylock = {};
  xdg.portal.enable = true;

  # Define users account
  users.users.datahearth = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Antoine Langlois";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      "datahearth" = import ./home-manager/home.nix;
    };
  };

  # Environment
  environment.shells = with pkgs; [ zsh ];
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  environment.variables = {
    KWIN_DRM_USE_MODIFIERS = "0";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    pinentry
    home-manager
    docker
    looking-glass-client
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = ["FiraCode"];
    })
  ];

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
    steam.enable = true;
  };

  virtualisation.docker.enable = true;

  fileSystems = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      smb_secrets = "/etc/nixos/smb-secrets";
    in {
    "/mnt/cronos/medias" = {
      device = "//10.0.0.2/medias";
      fsType = "cifs";
      options = ["${automount_opts},credentials=${smb_secrets}/cronos"];
    };
    "/mnt/cronos/isos" = {
      device = "//10.0.0.2/isos";
      fsType = "cifs";
      options = ["${automount_opts},credentials=${smb_secrets}/cronos"];
    };
  };

  system.stateVersion = "23.11";
}
