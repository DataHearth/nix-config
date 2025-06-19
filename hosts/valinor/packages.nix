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
      pwru
      smartmontools
    ];
  };

  programs = {
    gnupg.agent.enable = true;

    zsh = {
      enable = true;
      promptInit = ''
        source <(docker completion zsh)
        source <(ipfs commands completion zsh)
        source ${pkgs.rclone}/share/zsh/site-functions/_rclone
      '';
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.mononoki
    nerd-fonts.jetbrains-mono
  ];
}
