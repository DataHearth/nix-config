{ pkgs, lib, inputs, ... }: {
  imports = [ ./services.nix ../../modules/neovim ];

  # Nix
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "x86_64-darwin";
  nixpkgs.config.allowUnfree = true;

  # System
  system.stateVersion = 4;
  system.configurationRevision = inputs.rev or inputs.dirtyRev or null;

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
    users = { "antoine" = import ./home-manager/home.nix; };
  };

  custom = { neovim.enable = true; };

  programs = {
    zsh.enable = true;
    # HTMX lsp doesn't build on macos
    nixvim.plugins.lsp.servers.htmx.enable = lib.mkForce false;
  };

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "Mononoki" ]; })
    corefonts
  ];
}
