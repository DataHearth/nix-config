{ config, pkgs, ... }:
{
  home_modules = {
    ssh.enable = true;
    zellij.enable = true;
    ashell.enable = true;

    hyprland = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.hyprland;
      display_manager = true;
      window_rules = [
        "workspace 1, class:Alacritty"
        "workspace 2, class:zen, initialTitle:Zen Browser"
        "workspace 3, class:dev.zed.Zed-Dev"
        "workspace 3, class:code, initialTitle: Visual Studio Code"
        "workspace 4, class:discord"
        "workspace 4, class:signal"
        "workspace 6, class:spotify"
      ];
      exec_once = [
        "signal-desktop"
        "discord"
        "zen"
        "spotify"
      ];
    };

    hyprlock = {
      enable = true;
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
