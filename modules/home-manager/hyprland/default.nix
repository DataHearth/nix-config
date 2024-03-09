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
  workspaceSettings = mkOption {
    type = types.listOf types.nonEmptyStr;
    description = "Workspace definition";
    default = [];
  };
  monitorSettings = mkOption {
    type = types.listOf types.nonEmptyStr;
    description = "Monitors definition";
    default = [];
  };
  envVariables = mkOption {
    type = types.listOf types.nonEmptyStr;
    description = "Environment variables";
    default = [ "XCURSOR_SIZER,24" ];
  };
  nvidia = mkEnableOption "nvidia";

  hyprlock = {
    enable = mkEnableOption "hyprlock";
  };
in
{
  options.hm.hyprland = {
    inherit enable hyprlock enableXWayland workspaceSettings monitorSettings nvidia envVariables;
  };

  config = mkIf cfg.enable {
    home.packages = mkIf cfg.hyprlock.enable [ pkgs.hyprlock ];

    home.file.".config/hypr/hyprlock.conf" = mkIf cfg.hyprlock.enable {
      source = ./hyprlock.conf;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = cfg.enableXWayland;
      settings = builtins.fromJSON (builtins.readFile ./hyprland.json) // {
        env = if cfg.nvidia then [
          "WLR_NO_HARDWARE_CURSORS,1"
          "LIBVA_DRIVER_NAME,nvidia"
          "XDG_SESSION_TYPE,wayland"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ] ++ cfg.envVariables else cfg.envVariables; 
        monitor = mkIf (cfg.monitorSettings != []) cfg.monitorSettings;
        workspace = mkIf (cfg.workspaceSettings != []) cfg.workspaceSettings;
      };
    };
  };
}
