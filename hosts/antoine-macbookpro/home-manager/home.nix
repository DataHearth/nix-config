{ pkgs, lib, ... }: 
{
  imports = [
    # Reusable modules
    ../../../modules/home-manager/zsh.nix
    ../../../modules/home-manager/ssh.nix
    ../../../modules/home-manager/go.nix
    ../../../modules/home-manager/utils.nix
    ../../../modules/home-manager/vscode

    # Shared home-manager configuration between systems
    ../../shared/hm.nix
  ] ++ (import ../../../modules/home-manager { });

  home.packages = with pkgs; [
  ];

  # Custom modules (./modules/home-manager)
  hm = {
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
