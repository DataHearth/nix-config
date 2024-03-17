{ pkgs, lib, ... }: 
{
  imports = [
    ../../shared/hm.nix
  ] ++ (import ../../../modules/home-manager);

  home.packages = with pkgs; [
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
