{ pkgs, ... }:
{
  environment = {
    pathsToLink = [ "/share/zsh" ];
    shells = with pkgs; [
      zsh
      bashInteractive
    ];
    systemPackages = with pkgs; [
      age
      btop
      difftastic
      dig
      dogdns
      dust
      fd
      jq
      rclone
      restic
      ripgrep
      sd
      unzip
      xh
      zip
    ];
  };

  programs = {
    zsh.enable = true;
    gnupg.agent.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "Mononoki"
        "JetBrainsMono"
      ];
    })
  ];
}
