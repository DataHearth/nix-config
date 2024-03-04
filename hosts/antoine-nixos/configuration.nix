{ pkgs, lib, nixvim, home-manager, ... }:
{
  imports = [
    home-manager.nixosModules.default
    nixvim.nixosModules.nixvim

    # Modules
    ../../modules/linux/passthrough.nix
    ../../modules/linux/nvidia.nix
    ../../modules/neovim

    # Host specific
    ./hardware-configuration.nix
    ./systemd.nix
    ./services.nix
  ];
  # Nix configuration
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05";

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    useOSProber = true;
  };

  # Networking
  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
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
  };

  # Hardware
  hardware = {
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport = true;
    };
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
  xdg = {
    portal = {
      enable = true;
    };
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.datahearth = {
      isNormalUser = true;
      description = "Antoine Langlois";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
    };
  };

  environment = {
    shells = with pkgs; [ zsh bash ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    variables = {
      KWIN_DRM_USE_MODIFIERS = "0";
      WLR_NO_HARDWARE_CURSORS = "1";
    };
    systemPackages = with pkgs; [
      networkmanagerapplet
      pinentry
      home-manager
      docker
      looking-glass-client
      playerctl
      xdg-desktop-portal-gtk
    ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = ["FiraCode"];
    })
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      "datahearth" = import ./home-manager/home.nix;
    };
  };
  
  programs = {
    steam.enable = true;

    # Enable DE in login page
    # Further customization inside home.nix
    hyprland.enable = true;

    # Enable shells globally to allow system usage
    # Further customization inside home.nix
    zsh.enable = true;
  };
  
  virtualisation.docker.enable = true;
  custom = {
    neovim.enable = true;
  };

  fileSystems = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      smb_secrets = "/home/datahearth/.config/nix-config/smb-secrets";
    in {
    "/mnt/cronos/medias" = lib.mkForce {
      device = "//10.0.0.2/medias";
      fsType = "cifs";
      options = ["${automount_opts},credentials=${smb_secrets}/cronos"];
    };
    "/mnt/cronos/isos" = lib.mkForce {
      device = "//10.0.0.2/isos";
      fsType = "cifs";
      options = ["${automount_opts},credentials=${smb_secrets}/cronos"];
    };
    "/home/datahearth/games" = lib.mkForce {
      device = "/dev/disk/by-uuid/62cb1cf1-fee4-480d-89fe-bb0613f4e830";
      fsType = "ext4";
      options = ["${automount_opts},uid=1000,gid=100"];
    };
  };
}
