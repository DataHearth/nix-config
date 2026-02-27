{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zen-browser.enable = true;
  programs.zen-browser.suppressXdgMigrationWarning = true;

  home_modules = {
    alacritty.enable = true;
    atuin.enable = true;
    bat.enable = true;
    direnv.enable = true;
    # niri.enable = true; # TODO: debug niri build failure
    nushell.enable = true;
    theme.enable = true;
    vscode.enable = true;
    yazi.enable = true;
    zed-editor.enable = true;
    zellij.enable = true;
    claude-code = {
      enable = true;
      plugins = {
        "feature-dev@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "claude-code-setup@claude-plugins-official" = true;
      };
      mcpServers = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = "Bearer \${GITHUB_TOKEN}";
          };
        };
        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
          };
        };
      };
    };

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
      envExtra =
        lib.optionalString config.home_modules.direnv.enable ''
          if [[ -n "$CLAUDECODE" ]]; then
            eval "$(${config.programs.direnv.package}/bin/direnv hook zsh)"
          fi
        ''
        + lib.optionalString config.home_modules.claude-code.enable ''
          if [[ -r /run/secrets/claude-code/github-mcp ]]; then
            export GITHUB_TOKEN="$(${pkgs.coreutils}/bin/cat /run/secrets/claude-code/github-mcp)"
          fi
          if [[ -r /run/secrets/claude-code/context7-mcp ]]; then
            export CONTEXT7_API_KEY="$(${pkgs.coreutils}/bin/cat /run/secrets/claude-code/context7-mcp)"
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
        "workspace 2, match:class zen-beta, match:initial_title Zen Browser"
        "workspace 3, match:class dev.zed.Zed"
        "workspace 3, match:class code, match:initial_title Visual Studio Code"
        "workspace 4, match:class discord"
        "workspace 4, match:class signal"
        "workspace 6, match:initial_title Spotify Premium"
        "workspace 9, match:class F5 VPN"
      ];
      exec_once = [
        "signal-desktop --password-store=\"gnome-libsecret\""
        "discord --ozone-platform=wayland"
        "zen-beta"
        "spotify --ozone-platform=wayland"
      ];

      awww.randomize = {
        enable = true;
        directory = "/run/media/datahearth/proton/medias/wallpapers";
      };
    };
  };
}
