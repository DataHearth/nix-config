{ pkgs, hyprlock, hypridle, mac-app-util, ... }: {
  imports = [
    ../../shared/hm.nix

    hyprlock.homeManagerModules.default
    hypridle.homeManagerModules.default
    mac-app-util.homeManagerModules.default
  ] ++ (import ../../../modules/home-manager);

  home.packages = with pkgs; [ pinentry_mac ];

  hm = {
    ssh.enable = true;

    git = {
      enable = true;
      signingKey = "FFC492C15320B05D0F8D7D58ABF6737C63396D35";
    };
  };

  programs = { bash.enable = true; };

  home.stateVersion = "24.05";
}
