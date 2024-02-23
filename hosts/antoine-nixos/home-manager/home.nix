{ pkgs, lib, ... }:
{
  # Almost static information
  home.username = "datahearth";
  home.homeDirectory = "/home/datahearth";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  imports = [
    # Reusable modules
    ../../../modules/home-manager/alacritty.nix
    ../../../modules/home-manager/zsh.nix
    ../../../modules/home-manager/git.nix
    ../../../modules/home-manager/ssh.nix
    ../../../modules/home-manager/go.nix
    ../../../modules/home-manager/utils.nix
    ../../../modules/home-manager/services/dunst.nix
    # ../../../modules/home-manager/services/espanso.nix
    ../../../modules/home-manager/services/gpg_ssh_agent.nix

    ../../../modules/home-manager/hyprland
    ../../../modules/home-manager/waybar
    ../../../modules/home-manager/swaylock
    ../../../modules/home-manager/looking-glass
    ../../../modules/home-manager/vscode
    ../../../modules/home-manager/tofi

    # Shared home-manager configuration between systems
    ../../shared/hm.nix

    # Host specific
    ./services.nix
  ];

  home.packages = with pkgs; [
    # GUI Applications
    firefox
    discord
    spotify
    gparted
    satty
    nextcloud-client
    signal-desktop
    vlc

    # CLI tools
    cliphist
    gnupg
    grim
    hyprshot
    pciutils
    python3
    slurp
    swaynotificationcenter
    swww
    tofi
    waybar
    wl-clipboard
    iotop

    # Libraries
    libnotify

    # Overlay
    pr-nosql.nosql-workbench
    pr-hoppscotch.hoppscotch
  ];

  home.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  programs = {
    cava.enable = true;

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };

    git.signing.key = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";

    vscode = {
      extensions = with pkgs.vscode-extensions; [
        ms-vsliveshare.vsliveshare
        ms-vscode.cpptools
      ];
    };

    bash = {
      enable = true;
      enableCompletion = true;
    };
  };

  wayland.windowManager = {
    hyprland = {
      settings = {
        monitor = lib.mkForce [
          "DP-1,preferred,0x0,2"
          "HDMI-A-1,preferred,1920x0,1"
        ];
        workspace = [
          "DP-1,1"
          "HDMI-A-1,2"
        ];
        env = [
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          # "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ];
      };
    };
  };
}
