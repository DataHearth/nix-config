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
      signingKey = "099D31E860471ABE8425358243C0623D204EE13D";
    };
  };

  programs = rec {
    bash.enable = true;
  };

  home.stateVersion = "23.11";
}
