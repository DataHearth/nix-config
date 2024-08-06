{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixpkgs-unstable, sops-nix, home-manager, nixvim
    , lanzaboote, ... }: {
      nixosConfigurations = let
        system = "x86_64-linux";
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        overlay-unstable = _: _: {
          xdg-desktop-portal-hyprland = unstable.xdg-desktop-portal-hyprland;
        };
      in {
        antoine-nixos = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs; };
          modules = [
            ({ ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            ./hosts/antoine-nixos/configuration.nix
            home-manager.nixosModules.home-manager
            nixvim.nixosModules.nixvim
            sops-nix.nixosModules.sops
          ];
        };
        antoine-framework = nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = { inherit inputs; };
          modules = [
            ({ ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            ./hosts/antoine-framework/configuration.nix
            home-manager.nixosModules.home-manager
            nixvim.nixosModules.nixvim
            lanzaboote.nixosModules.lanzaboote
            sops-nix.nixosModules.sops
          ];
        };
      };
    };
}
