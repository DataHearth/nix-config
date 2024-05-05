{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hm.rofi-wayland;

  enable = mkEnableOption "rofi-wayland";
in {
  options.hm.rofi-wayland = { inherit enable; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.rofi-wayland ];

    home.file = {
      ".config/rofi/dmenu.rasi".source = ./dmenu.rasi;
      ".config/rofi/clipboard.rasi".source = ./clipboard.rasi;
      ".config/rofi/powermenu.rasi".source = ./powermenu.rasi;
      ".config/rofi/screenshot.rasi".source = ./screenshot.rasi;
      ".config/rofi/confirm.rasi".source = ./confirm.rasi;

      ".config/rofi/dmenu.sh".source = ./dmenu.sh;
      ".config/rofi/clipboard.sh".source = ./clipboard.sh;
      ".config/rofi/powermenu.sh".source = ./powermenu.sh;
      ".config/rofi/screenshot.sh".source = ./screenshot.sh;
    };
  };
}
