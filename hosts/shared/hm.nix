{ pkgs, ... }: {
  home.packages = with pkgs; [
    asciinema
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
    neofetch
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
    zellij
    zip

    # GUI
    firefox
    discord
    spotify
    vlc
    insomnia
  ];
  home.sessionPath = [ "$(go env GOBIN)" "$HOME/.cargo/bin" ];

  programs = {
    zoxide.enable = true;
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;

    yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    bat = {
      enable = true;
      config = { theme = "catppuccin_macchiato"; };
      themes = {
        catppuccin_macchiato = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
            sha256 = "1g2r6j33f4zys853i1c5gnwcdbwb6xv5w6pazfdslxf69904lrg9";
          };
          file = "Catppuccin-macchiato.tmTheme";
        };
      };
    };

    go = {
      enable = true;
      goPath = "go/path";
      goBin = "go/bin";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting = { enable = true; };
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        custom = "$HOME/.oh-my-zsh/custom";
        plugins =
          [ "git" "npm" "golang" "docker" "docker-compose" "python" "node" ];
      };
      plugins = [ ];
      shellAliases = {
        cat = "bat";
        dc = "docker compose";
        pnpm-upgrade = "pnpm add -g pnpm";
        cd = "z";
      };
      initExtra = ''
        neofetch
      '';
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
