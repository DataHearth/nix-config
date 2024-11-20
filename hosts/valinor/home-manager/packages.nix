{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      neofetch
      gh
      glow
      just
    ];
  };

  programs = {
    zoxide.enable = true;
    fzf.enable = true;
    home-manager.enable = true;
    starship.enable = true;

    # TODO: Move to configuration.nix
    eza.enable = true;

    gpg = {
      enable = true;
      mutableKeys = true;
      mutableTrust = true;
    };

    # TODO: move to configuration.nix
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
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      plugins = [
        # TODO: Override the official nixpkgs pkg
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
        nixos-switch = "sudo nixos-rebuild switch --flake $HOME/.config/nix-config#valinor";
        nixos-test = "sudo nixos-rebuild test --flake $HOME/.config/nix-config#valinor";
        nixos-cleanup = "sudo nix-collect-garbage -d; nix-collect-garbage -d; nix-store --optimise";
      };
      initExtra = ''
        cd /mnt/Erebor/War-goats/appdata
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
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/${keyNamePrefix}";
          identitiesOnly = true;
        };
      };
  };
}
