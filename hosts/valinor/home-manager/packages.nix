{ pkgs, ... }:
{
  home.packages = with pkgs; [
    sops
    argocd
    kubectl
    claude-code
    talosctl
    kustomize
    kubernetes-helm
    gh
  ];

  programs = {
    zoxide.enable = true;
    fzf.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    eza.enable = true;
    gpg.enable = true;

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

    zsh =
      let
        appdata_path = "/mnt/Erebor/War-goats/appdata";
      in
      {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        oh-my-zsh.enable = true;
        plugins = with pkgs; [
          {
            name = "zsh-autopair";
            src = zsh-autopair;
          }
        ];
        shellAliases = {
          cat = "bat";
          cd = "z";
          docker-restart-all = "docker compose -f ${appdata_path}/docker-compose.yml restart";
        };
        initContent = ''
          cd ${appdata_path}
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
