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
    ../../../modules/home-manager/alacritty
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
    ripgrep
    jq
    yq-go
    gnupg
    iotop
    iftop
    zip
    unzip
    difftastic
    wget
    fd
    waybar
    swaynotificationcenter
    playerctl
    nodejs
    python3
    xh
    nix-index
    corepack
    neofetch
    swww
    tofi
    grim
    slurp
    hyprshot
    wl-clipboard
    satty
    cliphist
    pciutils
    awscli2
    rustup
    gh
    php83
    php83Packages.composer
    zoxide
    ruff

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
  home.sessionPath = [
    "$(go env GOBIN)"
    "$HOME/.cargo/bin"
  ];

  programs = {
    cava.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };

    # Add GPG key outside of reusable module
    git.signing.key = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
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
          "GBM_BACKEND,nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ];
      };
    };
  };
}
