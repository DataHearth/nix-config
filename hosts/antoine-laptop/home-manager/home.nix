{ pkgs, ... }: {
  imports = let
    modules_base_path = ../../../modules;
    modules_hm_path = modules_base_path + "/home-manager";
  in [
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
      wl-clipboard
      iotop
      nix-du
      brightnessctl

      # Libraries
      libnotify
      libsForQt5.breeze-icons
    ];
  };

  # Custom modules (./modules/home-manager)
  hm = {
    alacritty.enable = true;
    ssh.enable = true;
    rofi-wayland.enable = true;
    swaync.enable = true;

    waybar = {
      enable = true;
      right = [
        "custom/leftend"
        "pulseaudio"
        "pulseaudio#microphone"
        "custom/spacer"
        "disk"
        "custom/spacer"
        "custom/notification"
        "custom/spacer"
        "battery"
        "custom/spacer"
        "backlight"
        "custom/spacer"
        "tray"
        "custom/rightend"
      ];
    };

    hypridle = {
      enable = false;
      enabledListeners.brightness = false;
    };

    hyprlock = {
      enable = true;
      lockBackgroundImage = "~/Pictures/wallpapers/lock2.png";
    };

    git = {
      enable = true;
      signingKey = "5B8735090A5721B8F2CA023DB6878D0CAD2B2A55";
    };

    zellij = {
      enable = false;
      copy_command = "wl-copy";
    };

    hyprland = {
      enable = true;
      workspaceSettings = [
        "1, monitor:eDP-1, default:true"
        "3, monitor:eDP-1"
        "5, monitor:eDP-1"
        "7, monitor:eDP-1"
        "9, monitor:eDP-1"
        "2, monitor:eDP-1"
        "4, monitor:eDP-1"
        "6, monitor:eDP-1"
        "8, monitor:eDP-1"
        "10, monitor:eDP-1"
      ];
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
