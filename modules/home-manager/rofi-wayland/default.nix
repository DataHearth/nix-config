{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home_modules.rofi-wayland;

  enable = lib.mkEnableOption "rofi-wayland";
in
{
  options.home_modules.rofi-wayland = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rofi-wayland
      grim
      slurp
      satty
      hyprshot
      playerctl
    ];

    xdg.configFile = {
      "rofi/dmenu.rasi".source = ./dmenu.rasi;
      "rofi/clipboard.rasi".source = ./clipboard.rasi;
      "rofi/powermenu.rasi".source = ./powermenu.rasi;
      "rofi/screenshot.rasi".source = ./screenshot.rasi;
      "rofi/confirm.rasi".source = ./confirm.rasi;

      "rofi/dmenu.sh" = {
        source = ./dmenu.sh;
        executable = true;
      };
      "rofi/clipboard.sh" = {
        source = ./clipboard.sh;
        executable = true;
      };
      "rofi/powermenu.sh" = {
        source = ./powermenu.sh;
        executable = true;
      };
      "rofi/screenshot.sh" = {
        source = ./screenshot.sh;
        executable = true;
      };
    };
  };
}
