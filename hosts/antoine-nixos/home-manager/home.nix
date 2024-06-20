{ pkgs, ... }: {
  imports = let
    modules = ../../../modules/home-manager;
    shared = ../../shared/home-manager;
  in [
    "${modules}/looking-glass"

    "${shared}/gtk.nix"
    "${shared}/modules.nix"
    "${shared}/options.nix"
    "${shared}/packages.nix"
    "${shared}/services.nix"

    ./services.nix
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
      unetbootin
      woeusb
      prismlauncher
    ];
  };

  # Custom modules (./modules/home-manager)
  hm = {
    hyprlock = {
      enable = true;
      lockBackgroundImage = "~/Pictures/wallpapers/lock2.png";
      defaultDisplay = "DP-2";
    };

    git = {
      enable = true;
      signingKey = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
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
      wallpaper = "~/Pictures/wallpapers/wallpaper3.jpg";
    };
  };
}
