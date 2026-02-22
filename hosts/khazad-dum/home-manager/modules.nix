{ pkgs, ... }:
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
      marketplaces.superpowers-marketplace = {
        source = {
          source = "github";
          repo = "obra/superpowers-marketplace";
        };
      };
      plugins = {
        "superpowers@superpowers-marketplace" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "pyright-lsp@claude-plugins-official" = true;
        "github@claude-plugins-official" = true;
        "context7@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "stripe@claude-plugins-official" = true;
        "playwright@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "claude-code-setup@claude-plugins-official" = true;
      };
      skillsDir =
        let
          src = pkgs.fetchgit {
            url = "https://github.com/anthropics/skills.git";
            rev = "1ed29a03dc852d30fa6ef2ca53a67dc2c2c2c563";
            hash = "sha256-RlORhdCeodVB6m8eRlvpV/E0L47zbWeIhDv2mBuCEaQ=";
            sparseCheckout = [ "skills/canvas-design" ];
          };
        in
        "${src}/skills";
      rules = {
        nix-conventions = ''
          When working with Nix files in this repository:
          - Use SRI hashes: `hash = "sha256-..."` or explicit `sha256 = "hex..."`. Never use bare hex with `hash =`.
          - Desktop files: use `install -Dm444` for proper permissions, not `cp` + `mkdir -p`.
          - Build with `nh os build` (or `nh os switch`), never raw `nix build` expressions.
        '';
        commit-conventions = ''
          When creating git commits:
          - Use conventional commit prefixes: feat:, fix:, refactor:, chore:, docs:
          - Keep subject line under 72 characters.
          - Focus on "why" not "what".
        '';
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
