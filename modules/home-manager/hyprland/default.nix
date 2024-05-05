{ config, lib, pkgs, ... }:
with lib;
let
  hyprlandSettings = builtins.fromJSON (builtins.readFile ./hyprland.json);
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
    default = [ ];
  };
  monitorSettings = mkOption {
    type = types.listOf types.nonEmptyStr;
    description = "Monitors definition";
    default = [ ];
  };
  envVariables = mkOption {
    type = types.listOf types.nonEmptyStr;
    description = "Environment variables";
    default = [ "XCURSOR_SIZER,24" ];
  };
  nvidia = mkEnableOption "nvidia";
in {
  options.hm.hyprland = {
    inherit enable enableXWayland workspaceSettings monitorSettings nvidia
      envVariables;
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = cfg.enableXWayland;
      settings = hyprlandSettings // {
        env = hyprlandSettings.env ++ (if cfg.nvidia then [
          "WLR_NO_HARDWARE_CURSORS,1"
          "LIBVA_DRIVER_NAME,nvidia"
          "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        ] else
          [ ]) ++ cfg.envVariables;
        exec-once = hyprlandSettings.exec-once ++ [
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];
        monitor = mkIf (cfg.monitorSettings != [ ]) cfg.monitorSettings;
        workspace = mkIf (cfg.workspaceSettings != [ ]) cfg.workspaceSettings;
      };
    };
  };
}
