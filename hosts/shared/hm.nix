{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # GUI
    hoppscotch
    nosql-workbench

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
    gitoxide
  ];
  home.sessionPath = [
    "$(go env GOBIN)"
    "$HOME/.cargo/bin"
  ];

  programs = {
    zoxide.enable = true;

    bash = {
      enable = true;
      enableCompletion = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
  };
}
