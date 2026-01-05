{ config, pkgs, ... }:
{
  home_modules = {
    ssh.enable = true;
    zellij.enable = true;
    yazi.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    hyprland = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.hyprland;
      display_manager = true;
      statusBar = "waybar";
      window_rules = [
        "workspace 1, class:Alacritty"
        "workspace 2, class:zen, initialTitle:Zen Browser"
        "workspace 3, class:dev.zed.Zed"
        "workspace 3, class:code, initialTitle: Visual Studio Code"
        "workspace 4, class:discord"
        "workspace 4, class:signal"
        "workspace 6, class:spotify"
      ];
      exec_once = [
        "signal-desktop --password-store=\"gnome-libsecret\""
        "discord"
        "zen-browser"
        "spotify"
      ];
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
