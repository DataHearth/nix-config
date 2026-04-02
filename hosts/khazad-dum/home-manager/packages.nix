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
    (signal-desktop.override { commandLineArgs = ''--password-store="gnome-libsecret" --use-tray-icon''; })
    (discord.override { commandLineArgs = "--ozone-platform=wayland"; })
    vlc
    obsidian
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
    mise.enable = true;

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
