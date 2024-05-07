{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nixvim, ... }: {
    nixosConfigurations = {
      antoine-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/antoine-nixos/configuration.nix
          home-manager.nixosModules.home-manager
          nixvim.nixosModules.nixvim
        ];
      };
    };

    darwinConfigurations = {
      antoine-macbookpro = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/antoine-macbookpro/configuration.nix
          home-manager.darwinModules.home-manager
          nixvim.nixDarwinModules.nixvim
        ];
      };
    };
  };
}
