{
  pkgs,
  lib,
  config,
  zen-browser,
  ...
}:
let
  default_user = "datahearth";
  state_version = "24.11";
in
{
  imports =
    let
      modules = ../../modules;
    in
    [
      ./i18n.nix
      ./hardware-configuration.nix
      ./services.nix

      "${modules}/nh.nix"
      (import "${modules}/gnome.nix" {
        inherit
          default_user
          zen-browser
          lib
          config
          pkgs
          ;
      })
      "${modules}/hyprland"
    ];
  system.stateVersion = state_version;
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
      default_user
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

    users."${default_user}" = {
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
    extraSpecialArgs = {
      inherit default_user state_version;
      inherit zen-browser;
    };
    users."${default_user}" = import ./home-manager/home.nix;
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
    wireshark.enable = true;
    virt-manager.enable = true;

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
    nerd-fonts.fira-code
    nerd-fonts.mononoki
    nerd-fonts.jetbrains-mono

    corefonts
  ];

  nixos_modules = {
    nh.enable = true;

    hyprland = {
      enable = false; # Conflict with bluetooth modules with Gnome DE
      settings = {
        default_user = default_user;
        xwayland.enable = true;

        kanshi.enable = true;
        waybar.enable = true;
        hyprlock.enable = true;

        config = {
          env = [ "XCURSOR_SIZER,24" ];
          exec-once = [
            "wl-paste --type text --watch cliphist store; bin/wl-paste --type image --watch cliphist store"
            "waybar"
            "swaync"
            "signal-desktop"
            "Discord"
            "alacritty"
            "zen-beta"
            "spotify"
          ];
        };
      };
    };

    gnome = {
      enable = true;
      settings.gdm = true;
    };
  };
}
