{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = builtins.fromJSON (builtins.readFile ./hyprland.json);
  };
}
