{ pkgs, ... }:
{
  programs.zen-browser.enable = true;

  home_modules = {
    alacritty.enable = true;
    bat.enable = true;
    direnv.enable = true;
    niri.enable = true;
    nushell.enable = true;
    theme.enable = true;
    vscode.enable = true;
    yazi.enable = true;
    zed-editor.enable = true;
    zellij.enable = true;

    ssh = {
      enable = true;
      matchBlocks =
        let
          keyNamePrefix = "id_ed25519";
        in
        {
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}_git";
            identitiesOnly = true;
          };
          "gitlab.com" = {
            hostname = "gitlab.com";
            user = "git";
            identityFile = "~/.ssh/${keyNamePrefix}_git";
            identitiesOnly = true;
          };
          "valinor" = {
            hostname = "valinor";
            user = "datahearth";
            identityFile = "~/.ssh/${keyNamePrefix}";
            identitiesOnly = true;
          };
          "deeps" = {
            hostname = "192.168.122.101";
            user = "datahearth";
            identityFile = "~/.ssh/${keyNamePrefix}";
            identitiesOnly = true;
          };
        };
    };

    zsh = {
      enable = true;
      extraPlugins = [
        {
          name = "zsh-completion-sync";
          src = pkgs.zsh-completion-sync;
          file = "share/zsh-completion-sync/zsh-completion-sync.plugin.zsh";
        }
      ];
      extraAliases = {
        open = "xdg-open";
      };
      envExtra = ''
        if [[ -n "$CLAUDECODE" ]]; then
          eval "$(direnv hook zsh)"
        fi
      '';
    };

    neovim = {
      enable = true;
      defaultEditor = true;
    };

    git = {
      enable = true;
      signingKey = "dev@antoine-langlois.net";
      difftastic.enable = true;
    };

    jujutsu = {
      enable = true;
      signingKey = "dev@antoine-langlois.net";
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
  };
}
