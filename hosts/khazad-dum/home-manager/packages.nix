{ pkgs, ... }:
{
  home.packages = with pkgs; [
    asciinema
    neofetch
    awscli2
    corepack
    difftastic
    fd
    gh
    git-chglog
    git-lfs
    gitoxide
    glow
    goreleaser
    grype
    hyperfine
    iftop
    jq
    just
    nix-du
    nix-index
    nodejs
    python3
    rclone
    restic
    ripgrep
    rustup
    sd
    syft
    tokei
    unzip
    wget
    xh
    yq-go
    zip
    libnotify
    kanshi
    dogdns
    dust

    # GUI
    discord
    firefox
    eog
    nautilus
    insomnia
    nextcloud-client
    obs-studio
    protonmail-bridge
    signal-desktop
    vlc
    gimp
    satty
    dbeaver-bin
    spotify
    gnome-calculator
  ];

  programs = {
    zoxide.enable = true;
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    home-manager.enable = true;

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
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

    go = {
      enable = true;
      goPath = "go/path";
      goBin = "go/bin";
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = [
        {
          name = "zsh-autopair";
          src = pkgs.zsh-autopair;
        }
      ];
      initExtra = ''
        url-sri() {
          nix-prefetch-url "$1" | xargs nix hash to-sri --type sha256
        }
        pr-review() {
          nix-shell -p nixpkgs-review --run "nixpkgs-review pr $1"
        }
        head-review() {
          nix-shell -p nixpkgs-review --run "nixpkgs-review rev HEAD"
        }
      '';

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

        # BAP
        "bap-dev" = {
          hostname = "dev.app.bienaporter.com";
          user = "service_deploy";
          identityFile = "~/.ssh/${keyNamePrefix}_bap-dev";
          identitiesOnly = true;
          port = 5022;
        };
        "bap-prod" = {
          hostname = "prod.app.bienaporter.com";
          user = "service_deploy";
          identityFile = "~/.ssh/${keyNamePrefix}_bap-prod";
          identitiesOnly = true;
          port = 5022;
        };
        "bap-runner" = {
          hostname = "51.91.11.36";
          user = "gitlab-runner";
          identityFile = "~/.ssh/${keyNamePrefix}_bap-runner";
          identitiesOnly = true;
        };
      };
  };
}
