{ ... }:
{
  programs.zen-browser.enable = true;

  home_modules = {
    ssh.enable = true;
    zellij.enable = true;
    yazi.enable = true;
    nushell.enable = true;
    vscode.enable = true;
    zed-editor.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    hyprland = {
      enable = true;
      display_manager = true;
      status_bar = "waybar";
      window_rules = [
        "workspace 1, match:class Alacritty"
        "workspace 2, match:class zen, match:initial_title Zen Browser"
        "workspace 3, match:class dev.zed.Zed"
        "workspace 3, match:class code, match:initial_title Visual Studio Code"
        "workspace 4, match:class discord"
        "workspace 4, match:class signal"
        "workspace 6, match:class spotify"
      ];
      exec_once = [
        "signal-desktop --password-store=\"gnome-libsecret\""
        "discord"
        "zen-browser"
        "spotify"
      ];

      awww.randomize = {
        enable = true;
        directory = "/run/media/datahearth/proton/medias/wallpapers";
      };
    };

    niri.enable = true;
    theme.enable = true;

    alacritty.enable = true;

    git = {
      enable = true;
      signingKey = "B3402BD69AEDB608F67D6E850DBAB694B466214F";
    };
  };
}
