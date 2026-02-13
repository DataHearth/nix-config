{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    dust
    fd
    gh
    hyperfine
    jq
    libnotify
    ripgrep
    sd
    unzip
    wget
    xh
    zip
    git-filter-repo
    nixpkgs-review
    claude-code
    nixfmt
    nixd
    playerctl
    brightnessctl
    wl-clipboard
    proton-vpn-cli
    sops
    rclone
    gpclient

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.mononoki
    nerd-fonts.fira-code
    noto-fonts-cjk-serif # support for chinese/japanese characters
    noto-fonts-cjk-sans # support for chinese/japanese characters

    # GUI
    obs-studio
    signal-desktop
    discord
    vlc
    obsidian
    spotify
    rquickshare
    qbittorrent
    virt-manager
    spice-gtk
    proton-authenticator
    docker-compose
    docker-buildx
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf.enable = true;
    gpg.enable = true;
    home-manager.enable = true;
    starship.enable = true;
    zoxide.enable = true;

    nh = {
      enable = true;
      homeFlake = "${config.xdg.configHome}/nix-config";
      clean = {
        enable = true;
        dates = "monthly";
        extraArgs = "--keep 3 --keep-since 72h --optimise";
      };
    };
  };
}
