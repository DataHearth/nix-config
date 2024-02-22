{ pkgs, lib, ... }: 
{
  imports = [
    # Reusable modules
    ../../../modules/home-manager/zsh.nix
    ../../../modules/home-manager/git.nix
    ../../../modules/home-manager/ssh.nix
    ../../../modules/home-manager/go.nix
    ../../../modules/home-manager/utils.nix
    ../../../modules/home-manager/vscode

    # Shared home-manager configuration between systems
    ../../shared/hm.nix
  ];

  home.packages = with pkgs; [
  ];

  programs = rec {
    bash.enable = true;
    git.signing.key = "099D31E860471ABE8425358243C0623D204EE13D";
    # vscode.extensions = lib.lists.remove "ms-vsliveshare-vsliveshare" vscode.extensions;
  };

  home.stateVersion = "23.11";
}
