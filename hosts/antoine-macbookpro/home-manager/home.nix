{ pkgs, ... }: 
{
  imports = [
    # Reusable modules
    ../../../modules/home-manager/zsh.nix
    ../../../modules/home-manager/git.nix
    ../../../modules/home-manager/ssh.nix
    ../../../modules/home-manager/go.nix
    ../../../modules/home-manager/utils.nix

    # Shared home-manager configuration between systems
    ../../shared/hm.nix
  ];

  home.packages = with pkgs; [];

  programs = {
    bash.enable = true;
    git.signing.key = "099D31E860471ABE8425358243C0623D204EE13D";
  };

  home.stateVersion = "23.11";
}