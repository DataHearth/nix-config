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
    playerctl
    brightnessctl
    wl-clipboard
    sops
    rclone
    restic
    docker-compose
    docker-buildx

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.mononoki
    nerd-fonts.fira-code
    noto-fonts-cjk-serif # support for chinese/japanese characters
    noto-fonts-cjk-sans # support for chinese/japanese characters

    # GUI
    gnome-calculator
    protonmail-bridge-gui
    (signal-desktop.override {
      commandLineArgs = ''--password-store="gnome-libsecret" --use-tray-icon'';
    })
    (discord.override { commandLineArgs = "--ozone-platform=wayland"; })
    vlc
    rquickshare
    proton-authenticator
    audacity
    spotify
    bruno
    claude-desktop
    thunderbird
    opencloud-desktop
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
