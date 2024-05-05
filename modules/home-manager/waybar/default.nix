{ config, options, lib, ... }:
with lib;
let
  cfg = config.hm.waybar;

  enable = mkEnableOption "waybar";
in {
  options.hm.waybar = { inherit enable; };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      style = builtins.readFile ./style.css;
    };
    home.file = {
      ".config/waybar/config".source = ./waybar.json;
      ".config/waybar/modules.json".source = ./modules.json;
    };
  };
}
