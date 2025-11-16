{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
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
    claude-code
    nixfmt-rfc-style
    nixd
    playerctl
    brightnessctl
    wl-clipboard

    # GUI
    (config.lib.nixGL.wrap obs-studio)
    signal-desktop
    discord
    vlc
    obsidian
    spotify
    libreoffice
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    gpg.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    zoxide.enable = true;

    nh = {
      enable = true;
      homeFlake = "${config.xdg.configHome}/nix-config";
      clean = {
        enable = true;
        dates = "daily";
      };
    };

    difftastic = {
      enable = true;
      git.enable = config.home_modules.git.enable;
    };

    jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "DataHearth";
          email = "dev@antoine-langlois.net";
        };
      };
    };

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
        mgr = {
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

      shellAliases = {
        cat = "bat";
        cd = "z";
        open = "xdg-open";
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
