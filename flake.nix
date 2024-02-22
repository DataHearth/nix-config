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
    flake-utils.url = "github:numtide/flake-utils";

    # Pending PRs
    pr-nosql-workbench.url = "github:datahearth/nixpkgs/8d4967078aca101d396e651ac894c63d0a3bee48";
    pr-hoppscotch.url = "github:datahearth/nixpkgs/4375e546f4de4652970e9af54625dad44515aed0";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, flake-utils, ... }:
  let
    overlay = _: prev: {
      pr-nosql = import inputs.pr-nosql-workbench {
        system = prev.system;
        config.allowUnfree = true;
      };
      pr-hoppscotch = import inputs.pr-hoppscotch {
        system = prev.system;
      };
    };
  in
  {
    nixosConfigurations = {
      antoine-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs overlay; };
        modules = [
          ./hosts/antoine-nixos/configuration.nix
          home-manager.nixosModules.default
          {
            nixpkgs.overlays = [ overlay ];
          }
        ];
      };
    };
  
    darwinConfigurations = {
      antoine-macbookpro = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/antoine-macbookpro/configuration.nix
            home-manager.darwinModules.default
            {
              nixpkgs.overlays = [ overlay ];
            }
          ];
        };
    };
  };
}
