{ pkgs, lib, ... }:
{
  # Almost static information
  home.username = "datahearth";
  home.homeDirectory = "/home/datahearth";
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  imports = [
    # Reusable modules
    ../../../modules/home-manager/hyprland
    ../../../modules/home-manager/alacritty.nix
    ../../../modules/home-manager/zsh.nix
    ../../../modules/home-manager/git.nix
    ../../../modules/home-manager/waybar
    ../../../modules/home-manager/ssh.nix
    ../../../modules/home-manager/swaylock
    ../../../modules/home-manager/vscode.nix
    ../../../modules/home-manager/go.nix
    ../../../modules/home-manager/utils.nix
    ../../../modules/home-manager/tofi
    ../../../modules/home-manager/services/dunst.nix
    # ../../../modules/home-manager/services/espanso.nix
    ../../../modules/home-manager/services/gpg_ssh_agent.nix
    ../../../modules/home-manager/looking-glass

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
    nosql-workbench
    spacedrive
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
    vscode.package = (pkgs.vscode.override{ isInsiders = true; }).overrideAttrs (oldAttrs: rec {
      src = (builtins.fetchTarball {
        url = "https://vscode.download.prss.microsoft.com/dbazure/download/insider/00124e9e5830e3efc897db71c781899f8a676295/code-insider-x64-1708101203.tar.gz";
        sha256 = "0r78a5mqpijg7lvnvp5vpcq0avihpmsx6i0cq2b5qp0iyy9pwmjp";
      });
      version = "latest";
    });
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
