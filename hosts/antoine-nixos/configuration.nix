{ pkgs, lib, hyprlock, hypridle, ... }:
{
  imports = [
    # Modules
    ../../modules/linux/passthrough.nix
    ../../modules/linux/nvidia.nix
    ../../modules/neovim

    # Host specific
    ./hardware-configuration.nix
    ./services.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.05";
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  sound.enable = true;
  virtualisation.docker.enable = true;

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
    hostName = "antoine-nixos";
    nameservers = [
      "10.0.0.2"
      "fe80::1ac0:4dff:fe8f:ad21"
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
    wireless.enable = false;
  };

  hardware = {
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport = true;
    };
  };
  
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };
  
  security = {
    rtkit.enable = true;
    polkit.enable = true;

    pam.services = {
      swaylock = {};
      hyprlock = {};
    };
  };

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
      extraGroups = [ "networkmanager" "wheel" "docker" "wireshark" ];
    };
  };

  environment = {
    shells = with pkgs; [ zsh bash ];
    # variables = {
    #   KWIN_DRM_USE_MODIFIERS = "0";
    # };
    systemPackages = with pkgs; [
      networkmanagerapplet
      pinentry
      home-manager
      docker
      looking-glass-client
      playerctl
      kdePackages.okular
      wireshark

      # Libraries
      kdePackages.qtwayland
      libsForQt5.qt5.qtwayland
    ];
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = ["FiraCode" "Mononoki"];
    })
    corefonts
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit hyprlock hypridle; };
    users = {
      "datahearth" = import ./home-manager/home.nix;
    };
  };
  
  programs = {
    steam.enable = true;
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };
  
  custom = {
    neovim.enable = true;
  };

  systemd.tmpfiles.rules = [
    "f /dev/shm/looking-glass 0660 datahearth libvirtd -"
  ];

  fileSystems = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
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
