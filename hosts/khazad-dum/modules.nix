{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland.package = config.lib.nixGL.wrap pkgs.hyprland;
  home_modules = {
    ssh.enable = true;
    zellij.enable = true;
    hyprland.enable = true;
    ashell.enable = true;

    hyprlock = {
      enable = false;
      lockBackgroundImage = "~/.local/share/backgrounds/2025-10-19-18-43-55-undefined\ -\ Imgur(1).jpg";
    };

    alacritty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.alacritty;
    };

    git = {
      enable = true;
      signingKey = "B3402BD69AEDB608F67D6E850DBAB694B466214F";
    };
  };
}
