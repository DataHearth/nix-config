{ pkgs, config, ... }: {
  imports = let modules = ../shared;
  in [
    "${modules}/i18n.nix"
    "${modules}/neovim"

    ./hardware-configuration.nix
    ./services.nix
  ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  sound.enable = true;
  virtualisation.docker.enable = true;

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    nixPath = [
      "nixos-config=${config.users.users.datahearth.home}/.config/nix-config/hosts/antoine-framework/configuration.nix"
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    wireless.enable = false;
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
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;

    pam.services = { hyprlock = { enableGnomeKeyring = true; }; };
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
    hyprland.enable = true;
    zsh.enable = true;
    wireshark.enable = true;
  };

  custom = { neovim.enable = true; };
}
