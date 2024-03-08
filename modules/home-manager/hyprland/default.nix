{ config, options, lib, pkgs, ... }:
with lib;
let
  cfg = config.hm.hyprland;

  enable = mkEnableOption "hyprland";
  enableXWayland = mkOption {
    type = types.bool;
    default = true;
    description = "Should the XWayland option be enabled";
    example = true;
  };
  additionalSettings = mkOption {
    type = with lib.types;
      let
        valueType = nullOr (oneOf [
          bool
          int
          float
          str
          path
          (attrsOf valueType)
          (listOf valueType)
        ]) // {
          description = "Hyprland configuration value";
        };
      in valueType;
    default = {};
    description = "Additional settings for Hyprland";
  };

  hyprlock = {
    enable = mkEnableOption "hyprlock";
  };
in
{
  options.hm.hyprland = {
    inherit enable hyprlock additionalSettings enableXWayland;
  };

  config = mkIf cfg.enable {
    home.packages = mkIf cfg.hyprlock.enable [ pkgs.hyprlock ];

    home.file.".config/hypr/hyprlock.conf" = mkIf cfg.hyprlock.enable {
      source = ./hyprlock.conf;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = cfg.enableXWayland;
      settings = builtins.fromJSON (builtins.readFile ./hyprland.json) // cfg.additionalSettings;
    };
  };
}
