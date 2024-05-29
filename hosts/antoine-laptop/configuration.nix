{ pkgs, ... }: {
  imports = [
    # Modules
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
    device = "/dev/sda";
    useOSProber = true;
  };

  networking = {
    networkmanager = {
      enable = true;
      dns = "none";
    };
    hostName = "antoine-laptop";
    nameservers =
      [ "1.1.1.1" "1.0.0.1" "2606:4700:4700::1111" "2606:4700:4700::1001" ];
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
      swaylock = { };
      hyprlock = { };
    };
  };

  xdg = { portal = { enable = true; }; };

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
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };

  custom = { neovim.enable = true; };
}
