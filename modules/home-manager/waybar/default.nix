{ config, lib, ... }:
let
  cfg = config.hm.waybar;

  enable = lib.mkEnableOption "waybar";
  right = lib.mkOption {
    description = "List of modules to include in the right part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [
      "pulseaudio#output"
      "pulseaudio#input"
      "custom/spacer"
      "custom/notification"
      "custom/spacer"
      "tray"
    ];
  };
  left = lib.mkOption {
    description = "List of modules to include in the left part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [
      "hyprland/workspaces"
      "custom/spacer"
      "cpu"
      "custom/spacer"
      "memory"
      "custom/spacer"
      "disk"
      "custom/spacer"
      "network#speed"
    ];
  };
  center = lib.mkOption {
    description = "List of modules to include in the center part of waybar";
    type = lib.types.listOf lib.types.str;
    default = [ "clock" ];
  };
in {
  options.hm.waybar = { inherit enable right left center; };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      style = builtins.readFile ./style.css;
    };
    xdg.configFile = {
      "waybar/config".text = builtins.toJSON {
        include = "~/.config/waybar/modules.json";
        layer = "top";
        position = "top";
        modules-left = cfg.left;
        modules-center = cfg.center;
        modules-right = cfg.right;
      };
      "waybar/modules.json".source = ./modules.json;
    };
  };
}
