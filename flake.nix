{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, nixvim, ... }: {
    nixosConfigurations = {
      antoine-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { };
        modules = [
          ./hosts/antoine-nixos/configuration.nix
          home-manager.nixosModules.home-manager
          nixvim.nixosModules.nixvim
        ];
      };
      antoine-laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { };
        modules = [
          ./hosts/antoine-laptop/configuration.nix
          home-manager.nixosModules.home-manager
          nixvim.nixosModules.nixvim
        ];
      };
      antoine-framework = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/antoine-framework/configuration.nix
          home-manager.nixosModules.home-manager
          nixvim.nixosModules.nixvim
        ];
      };
    };
  };
}
