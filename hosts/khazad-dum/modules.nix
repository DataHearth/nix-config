{ config, pkgs, ... }:
{
  home_modules = {
    ssh.enable = true;
    zellij.enable = true;

    alacritty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.alacritty;
    };

    git = {
      enable = true;
      signingKey = "B3402BD69AEDB608F67D6E850DBAB694B466214F";
    };
  };
}
