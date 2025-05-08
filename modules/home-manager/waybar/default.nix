{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hm.waybar;

  enable = lib.mkEnableOption "waybar";
  right = lib.mkOption {
    description = "List of modules to include in the right part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [
      "pulseaudio#output"
      "pulseaudio#input"
      "backlight"
      "custom/notification"
      "battery"
      "tray"
    ];
  };
  left = lib.mkOption {
    description = "List of modules to include in the left part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [
      "hyprland/workspaces"
      "cpu"
      "memory"
      "disk"
      "network#speed"
    ];
  };
  center = lib.mkOption {
    description = "List of modules to include in the center part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [ "clock" ];
  };
in
{
  options.hm.waybar = {
    inherit
      enable
      right
      left
      center
      ;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ pavucontrol ];
    programs.waybar = {
      enable = true;
      style = builtins.readFile ./style.css;
      settings = {
        default = {
          include = "${config.xdg.configHome}/waybar/modules.json";
          position = "top";
          css = "~/.config/waybar/style.css";
          modules-left = cfg.left;
          modules-center = cfg.center;
          modules-right = cfg.right;
        };
      };
    };
    xdg.configFile = {
      "waybar/modules.json".source = ./modules.json;
      "waybar/styles" = {
        source = ./styles;
        recursive = true;
      };
    };
  };
}
