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
      signingKey = "A12925470298BFEE7EE092B3946E2D0C410C7B3D";
    };
  };

  programs = rec {
    bash.enable = true;
  };

  home.stateVersion = "23.11";
}
