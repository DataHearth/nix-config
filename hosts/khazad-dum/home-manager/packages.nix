{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
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
      gnome.eog
      gnome.nautilus
      insomnia
      nextcloud-client
      obs-studio
      protonmail-bridge
      qalculate-gtk
      signal-desktop
      vlc
      gimp
      satty
      dbeaver-bin
    ];
  };

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
      config = {
        theme = "catppuccin_macchiato";
      };
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
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = [
        {
          name = "zsh-autopair";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "376b586c9739b0a044192747b337f31339d548fd";
            hash = "sha256-mtDrt4Q5kbddydq/pT554ph0hAd5DGk9jci9auHx0z0=";
          };
        }
      ];
      shellAliases = {
        cat = "bat";
        dc = "docker compose";
        cd = "z";
        td = "sudo tailscale down";
        tu = "sudo tailscale up";
        nixos-switch = "sudo nixos-rebuild switch --flake $HOME/.config/nix-config#khazad-dum";
        nixos-test = "sudo nixos-rebuild test --flake $HOME/.config/nix-config#khazad-dum";
        nixos-cleanup = "sudo nix-collect-garbage -d; nix-collect-garbage -d; nix-store --optimise";
      };
      initExtra = ''
        url-sri() {
          nix-prefetch-url "$1" | xargs nix hash to-sri --type sha256
        }
        pr-review() {
          nix-shell -p nixpkgs-review --run "nixpkgs-review pr $1"
        }
        review-head() {
          nix-shell -p nixpkgs-review --run "nixpkgs-review rev HEAD"
        }
      '';
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
          hostname = "10.0.0.2";
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
