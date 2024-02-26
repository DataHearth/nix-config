{ pkgs, lib, ... }:
{
  imports = let 
    modules_base_path = ../../../modules;
    modules_hm_path = modules_base_path + "/home-manager"; 
  in [
    # Reusable modules
    "${modules_hm_path}/zsh.nix"
    "${modules_hm_path}/ssh.nix"
    "${modules_hm_path}/go.nix"
    "${modules_hm_path}/utils.nix"
    "${modules_hm_path}/services/dunst.nix"
    "${modules_hm_path}/services/gpg_ssh_agent.nix"

    "${modules_hm_path}/hyprland"
    "${modules_hm_path}/waybar"
    "${modules_hm_path}/swaylock"
    "${modules_hm_path}/looking-glass"
    "${modules_hm_path}/vscode"
    "${modules_hm_path}/tofi"

    # Shared home-manager configuration between systems
    ../../shared/hm.nix

    # Host specific
    ./services.nix
  ] ++ (import ../../../modules/home-manager { });

  # Almost static information
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "23.11";

    sessionVariables = {
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };

    packages = with pkgs; [
      # GUI Applications
      firefox
      discord
      spotify
      gparted
      satty
      nextcloud-client
      signal-desktop
      vlc
      protonmail-bridge

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
    ];
  };

  # Custom modules (./modules/home-manager)
  hm = {
    alacritty.enable = true;
    
    git = {
      enable = true;
      signingKey = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
    };
  };
  programs = {
    home-manager.enable = true;
    cava.enable = true;

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };

    vscode = {
      extensions = with pkgs.vscode-extensions; [
        ms-vsliveshare.vsliveshare
        ms-vscode.cpptools
      ];
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
          "DP-1,3"
          "DP-1,5"
          "DP-1,7"
          "DP-1,9"
          "HDMI-A-1,2"
          "HDMI-A-1,4"
          "HDMI-A-1,6"
          "HDMI-A-1,8"
          "HDMI-A-1,0"
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
