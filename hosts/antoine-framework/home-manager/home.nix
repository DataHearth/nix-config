{ pkgs, ... }: {
  imports = let
    modules = ../../../modules/home-manager;
    shared = ../../shared/home-manager;
  in [
    "${shared}/gtk.nix"
    "${shared}/modules.nix"
    "${shared}/options.nix"
    "${shared}/packages.nix"
    "${shared}/services.nix"
  ] ++ (import modules);
  home = {
    username = "datahearth";
    homeDirectory = "/home/datahearth";
    stateVersion = "24.05";

    packages = with pkgs; [
      # GUI Applications
      gparted
      satty
      nosql-workbench
    ];
  };

  # Custom modules (./modules/home-manager)
  hm = {
    waybar = {
      right = [
        "pulseaudio#output"
        "pulseaudio#input"
        "custom/spacer"
        "backlight"
        "custom/spacer"
        "battery"
        "custom/spacer"
        "custom/notification"
        "custom/spacer"
        "tray"
      ];
    };

    hyprlock = {
      enable = true;
      lockBackgroundImage = "~/Pictures/assets/locks/1.png";
    };

    git = {
      enable = true;
      signingKey = "E8F90B80908E723D0EDF09165803CDA59C26A96A";
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
      wallpaper = "~/Pictures/assets/wallpapers/5.jpg";
    };

    zellij = {
      enable = false;
      copy_command = "wl-copy";
    };
  };
}
