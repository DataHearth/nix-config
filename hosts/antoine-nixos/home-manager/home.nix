{ pkgs, ... }: {
  imports = let
    modules_base_path = ../../../modules;
    modules_hm_path = modules_base_path + "/home-manager";
  in [
    "${modules_hm_path}/looking-glass"
    "${modules_hm_path}/vscode"

    ../../shared/hm.nix
    ./services.nix
  ] ++ (import ../../../modules/home-manager);

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

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
      nosql-workbench
      qalculate-gtk
      insomnia
      obs-studio
      kdePackages.dolphin

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
      nix-du

      # Libraries
      libnotify
      libsForQt5.breeze-icons
    ];
  };

  # Custom modules (./modules/home-manager)
  hm = {
    alacritty.enable = true;
    dunst.enable = true;
    waybar.enable = true;
    ssh.enable = true;
    rofi-wayland.enable = true;

    hypridle = {
      enable = false;
      enabledListeners.brightness = false;
    };

    hyprlock = {
      enable = true;
      lockBackgroundImage = "~/Pictures/wallpapers/lock2.png";
      defaultDisplay = "DP-2";
    };

    git = {
      enable = true;
      signingKey = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
    };

    zellij = {
      enable = false;
      copy_command = "wl-copy";
    };

    hyprland = {
      enable = true;
      workspaceSettings = [
        "1, monitor:DP-2, default:true"
        "3, monitor:DP-2"
        "5, monitor:DP-2"
        "7, monitor:DP-2"
        "9, monitor:DP-2"
        "2, monitor:HDMI-A-1, default:true"
        "4, monitor:HDMI-A-1"
        "6, monitor:HDMI-A-1"
        "8, monitor:HDMI-A-1"
        "10, monitor:HDMI-A-1"
      ];
      monitorSettings =
        [ "DP-2,preferred,0x0,2" "HDMI-A-1,preferred,1920x0,1" ];
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
