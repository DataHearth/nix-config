{ inputs, pkgs, ... }: {
  imports = [
    ./services.nix
    inputs.home-manager.darwinModules.default
  ];

  # Nix
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "x86_64-darwin";
  nixpkgs.config.allowUnfree = true;

  # System
  system.stateVersion = 4;
  system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

  environment.systemPackages = with pkgs; [];
  environment.shells = with pkgs; [ zsh ];

  users.users.antoine = {
    name = "antoine";
    home = "/Users/antoine";
    shell = pkgs.zsh;
  };
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      "antoine" = import ./home-manager/home.nix;
    };
  };

  programs = {
    zsh.enable = true;
  };
}