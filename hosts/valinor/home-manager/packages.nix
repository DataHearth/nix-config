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
  };
}
