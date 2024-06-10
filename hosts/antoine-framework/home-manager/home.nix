{ pkgs, ... }: {
  imports =
    [ ../../../modules/home-manager/vscode ../../shared/hm.nix ./services.nix ]
    ++ (import ../../../modules/home-manager);
  xdg.enable = true;

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
    theme = {
      name = "Adwaita";
      package = pkgs.gnome.gnome-themes-extra;
    };
  };

  # Almost static information
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.05";

    packages = with pkgs; [
      # GUI Applications
      gparted
      satty
      nextcloud-client
      signal-desktop
      protonmail-bridge
      nosql-workbench
      qalculate-gtk
      obs-studio
      gnome.nautilus

      # CLI tools
      gnupg
      pciutils
      tofi
      iotop
      nix-du

      # Libraries
      libnotify
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

    hyprlock = {
      enable = true;
      lockBackgroundImage = "~/Pictures/wallpapers/lock.png";
    };

    git = {
      enable = true;
      signingKey = "E8F90B80908E723D0EDF09165803CDA59C26A96A";
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
      wallpaper = "~/Pictures/wallpaper.jpg";
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
