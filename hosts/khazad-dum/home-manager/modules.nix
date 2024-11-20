{
  hm = {
    alacritty.enable = true;
    ghostty.enable = true;
    ssh.enable = true;
    rofi-wayland.enable = true;
    swaync.enable = true;
    hyprland.enable = true;

    waybar = {
      enable = true;
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
      defaultDisplay = "eDP-1";
    };

    git = {
      enable = true;
      signingKey = "E8F90B80908E723D0EDF09165803CDA59C26A96A";
    };
  };
}
