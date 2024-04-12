{ pkgs, lib, hyprlock, hypridle, ... }: 
{
  imports = [
    ../../shared/hm.nix

    hyprlock.homeManagerModules.default
    hypridle.homeManagerModules.default
  ] ++ (import ../../../modules/home-manager);

  home.packages = with pkgs; [
    pinentry_mac
  ];

  hm = {
    ssh.enable = true;

    git = {
      enable = true;
      signingKey = "FFC492C15320B05D0F8D7D58ABF6737C63396D35";
    };
  };

  programs = rec {
    bash.enable = true;
  };

  home.stateVersion = "23.11";
}
