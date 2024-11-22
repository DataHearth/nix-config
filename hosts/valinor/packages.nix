{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    difftastic
    dig
    dogdns
    dust
    fd
    hyperfine
    jq
    nix-du
    nix-index
    rclone
    restic
    ripgrep
    sd
    unzip
    xh
    yq-go
    zip
    btop
    dua
    age
  ];

  programs = {
    zsh.enable = true;
    bash.completion.enable = true;

    git = {
      enable = true;
      lfs.enable = true;
    };
    gnupg.agent = {
      enable = true;
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "Mononoki"
        "FiraCode"
      ];
    })
  ];
}
