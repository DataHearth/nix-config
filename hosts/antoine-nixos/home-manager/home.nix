{ pkgs, lib, ... }:
{
  imports = let 
    modules_base_path = ../../../modules;
    modules_hm_path = modules_base_path + "/home-manager"; 
  in [
    "${modules_hm_path}/swaylock"
    "${modules_hm_path}/looking-glass"
    "${modules_hm_path}/vscode"
    "${modules_hm_path}/tofi"

    ../../shared/hm.nix
    ./services.nix
  ] ++ (import ../../../modules/home-manager);

  # Almost static information
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.05";

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
      hoppscotch
      nosql-workbench

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
    dunst.enable = true;
    waybar.enable = true;
    ssh.enable = true;
    
    git = {
      enable = true;
      signingKey = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
    };

    hyprland = {
      enable = true;
      hyprlock.enable = false;
      workspaceSettings = [
        "DP-2,1"
        "DP-2,3"
        "DP-2,5"
        "DP-2,7"
        "DP-2,9"
        "HDMI-A-1,2"
        "HDMI-A-1,4"
        "HDMI-A-1,6"
        "HDMI-A-1,8"
        "HDMI-A-1,10"
      ];
      monitorSettings = [
        "DP-2,preferred,0x0,2"
        "HDMI-A-1,preferred,1920x0,1"
      ];
      nvidia = true;
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
}
