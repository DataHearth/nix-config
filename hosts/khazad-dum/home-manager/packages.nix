{
  pkgs,
  zen-browser,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    difftastic
    dogdns
    dust
    fd
    gh
    hyperfine
    jq
    libnotify
    ripgrep
    sd
    unzip
    wget
    xh
    zip
    git-filter-repo
    nixpkgs-review
    lazygit
    rclone

    # GUI
    discord
    insomnia
    nextcloud-client
    obs-studio
    signal-desktop
    spotify
    vlc
    vscode

    zen-browser.packages."${system}".default
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    gpg.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    zoxide.enable = true;

    bat = {
      enable = true;
      config.theme = "catppuccin_macchiato";

      themes.catppuccin_macchiato = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
          sha256 = "1g2r6j33f4zys853i1c5gnwcdbwb6xv5w6pazfdslxf69904lrg9";
        };
        file = "Catppuccin-macchiato.tmTheme";
      };
    };

    yazi = {
      enable = true;
      settings = {
        manager = {
          show_hidden = true;
          sort_dir_first = true;
          show_symlink = true;
        };
      };
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = with pkgs; [
        {
          name = "zsh-autopair";
          src = zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
      ];
      initContent =
        let
          normal = lib.mkOrder 1000 ''
            url-sri() {
              nix-prefetch-url "$1" | xargs nix hash to-sri --type sha256
            }
          '';
          # Because some Nix implementation have a very high order (e.g zoxide), end finally lines need to be with an absurdly high number
          # Default Zellij ZSH setup doesn't provide a way to add a default layout to start with, I took it and added one
          end = lib.mkOrder 10000 ''
            if [[ -z "$ZELLIJ" ]]; then
              if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
                  zellij attach -c
              else
                  zellij --layout welcome
              fi

              if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
                  exit
              fi
            fi
          '';
        in
        lib.mkMerge [
          normal
          end
        ];

      shellAliases = {
        cat = "bat";
        cd = "z";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    ssh.matchBlocks =
      let
        keyNamePrefix = "id_ed25519";
      in
      {
        # Git servers
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

        # Servers
        "valinor" = {
          hostname = "valinor";
          user = "datahearth";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
      };
  };
}
