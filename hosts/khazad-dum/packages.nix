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
    nixfmt
    nixd
    playerctl
    brightnessctl
    wl-clipboard
    proton-vpn-cli
    sops

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.mononoki
    nerd-fonts.fira-code
    noto-fonts-cjk-serif # support for chinese/japanese characters
    noto-fonts-cjk-sans # support for chinese/japanese characters

    # GUI
    obs-studio
    signal-desktop
    discord
    vlc
    obsidian
    spotify
    rquickshare
    qbittorrent
    walker
    virt-manager
    proton-authenticator
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    gpg.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    zoxide.enable = true;
    mise.enable = true;

    nh = {
      enable = true;
      homeFlake = "${config.xdg.configHome}/nix-config";
      clean = {
        enable = true;
        dates = "monthly";
        extraArgs = "--keep 3 --keep-since 72h --optimise";
      };
    };

    difftastic = {
      enable = true;
      git.enable = config.home_modules.git.enable;
    };

    delta = {
      enable = true;
      enableJujutsuIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        signing = {
          behavior = "own";
          backend = "gpg";
          key = "dev@antoine-langlois.net";
        };
        git.sign-on-push = true;
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

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = with pkgs; [
        {
          name = "zsh-autopair";
          src = zsh-autopair;
          file = "share/zsh/zsh-autopair/autopair.zsh";
        }
        {
          name = "zsh-completion-sync";
          src = zsh-completion-sync;
          file = "share/zsh-completion-sync/zsh-completion-sync.plugin.zsh";
        }
      ];
      envExtra = ''
        if [[ -n "$CLAUDECODE" ]]; then
          eval "$(direnv hook zsh)"
        fi
      '';

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

        # VMs
        "deeps" = {
          hostname = "192.168.122.101";
          user = "datahearth";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
      };
  };
}
