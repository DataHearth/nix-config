{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting = {
      enable = true;
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      custom = "$HOME/.oh-my-zsh/custom";
      plugins = ["git" "npm" "golang" "docker" "docker-compose" "python" "node"];
    };
    plugins = [];
    shellAliases = {
      cat = "bat";
      dc = "docker compose";
      pnpm-upgrade = "pnpm add -g pnpm";
    };
    initExtra = ''
      neofetch
      eval "$(zoxide init zsh)"
    '';
  };
}
