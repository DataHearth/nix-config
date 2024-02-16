{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  {
    nixosConfigurations = {
      antoine-nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-linux";
        modules = [ 
          ./hosts/antoine-nixos/configuration.nix
          home-manager.nixosModules.default
          ({ ... }: { nixpkgs.overlays = [ (import ./packages) ]; })
        ];
      };
    };
    darwinConfigurations.antoine-macbookpro = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        system = "x86_64-darwin";
        modules = [
          ./hosts/antoine-macbookpro/configuration.nix
          home-manager.darwinModules.default
        ];
      };
  };
}
