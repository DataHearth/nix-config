{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CLI
    awscli2
    corepack
    difftastic
    fd
    gh
    iftop
    jq
    neofetch
    nix-index
    nodejs
    python3
    ripgrep
    ruff
    rustup
    sd
    unzip
    wget
    xh
    yq-go
    zip
    zoxide
    gitoxide
  ];
  home.sessionPath = [
    "$(go env GOBIN)"
    "$HOME/.cargo/bin"
  ];

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };
}
