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
    restic
    docker-compose
    docker-buildx

    nerd-fonts.jetbrains-mono
    nerd-fonts.mononoki
    nerd-fonts.fira-code
    noto-fonts-cjk-serif # support for chinese/japanese characters
    noto-fonts-cjk-sans # support for chinese/japanese characters

    gnome-calculator
    protonmail-bridge-gui
    # signal-desktop deprecated its `commandLineArgs` override argument in
    # favour of a wrapper. Its desktop entry execs `signal-desktop` by name, so
    # shadowing the binary on PATH covers launcher starts too.
    (symlinkJoin {
      name = "signal-desktop-wrapped";
      paths = [ signal-desktop ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/signal-desktop \
          --add-flags --password-store=gnome-libsecret \
          --add-flags --use-tray-icon
      '';
      inherit (signal-desktop) meta;
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
    obsidian
  ];

  programs = {
    btop.enable = true;
    eza.enable = true;
    fzf = {
      enable = true;
      # Atuin owns Ctrl-R (history search); yield fzf's competing binding to it
      # while keeping fzf's Ctrl-T / Alt-C widgets. "" is the module's supported
      # way to disable the Ctrl-R widget.
      historyWidget.command = "";
    };
    gpg.enable = true;
    home-manager.enable = true;
    zoxide.enable = true;
    mise.enable = true;
    qmd.enable = true;

    nh = {
      enable = true;
      homeFlake = "${config.xdg.configHome}/nix-config";
      clean = {
        enable = true;
        dates = "monthly";
        extraArgs = "--keep 3 --keep-since 30d --optimise";
      };
    };
  };
}
