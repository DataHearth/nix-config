{ config, pkgs, ... }: {
  imports = [ ../../modules/neovim ];

  home.username = "datahearth";
  home.homeDirectory = "/home/datahearth";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    neofetch
    awscli2
    difftastic
    gh
    git-lfs
    grype
    hyperfine
    nix-du
    nix-index
    syft
    tokei
    xh
    dust
    kubo

    # nixvim additional pkgs
    gofumpt
    golines
    ruff
    stylua
    nixfmt-classic
    taplo
    rustfmt
    prettierd
    nodePackages_latest.eslint

  ];
  custom.neovim.enable = true;
  custom.neovim.hm = true;

  home.file = { };

  home.sessionVariables = { };

  programs = {
    nixvim.defaultEditor = true;
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
      profileExtra = ''
        if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
      '';
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
      syntaxHighlighting.enable = true;
      oh-my-zsh.enable = true;
      profileExtra = ''
        if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
      '';
      initExtra = ''
        source <(kubectl completion zsh)
        source <(kubeadm completion zsh)
        source <(helm completion zsh)
        source <(cilium completion zsh)
        source <(docker completion zsh)
        source <(tailscale completion zsh)
        source <(hubble completion zsh)
      '';
      plugins = [{
        name = "zsh-autopair";
        src = pkgs.fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "376b586c9739b0a044192747b337f31339d548fd";
          hash = "sha256-mtDrt4Q5kbddydq/pT554ph0hAd5DGk9jci9auHx0z0=";
        };
      }];
      shellAliases = {
        cat = "bat";
        dc = "docker compose";
        cd = "z";
        td = "sudo tailscale down";
        tu = "sudo tailscale up";
        hm-switch =
          "home-manager switch --flake ${config.xdg.configHome}/nix-config#$HOST";
        hm-build =
          "home-manager build --flake ${config.xdg.configHome}/nix-config#$HOST";
        hm-cleanup =
          "sudo nix-collect-garbage -d; nix-collect-garbage -d; nix-store --optimise";
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-tty;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
