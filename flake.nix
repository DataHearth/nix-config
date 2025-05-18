{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    zjstatus.url = "github:dj95/zjstatus";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:datahearth/nixvim-config";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      home-manager,
      nixvim,
      lanzaboote,
      zen-browser,
      zjstatus,
      ...
    }:
    {
      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
          Valinor = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              pkgs-unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };

            modules = [
              ./hosts/valinor/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              nixvim.nixosModules.default
            ];
          };

          Khazad-dum = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit zen-browser;

              pkgs-unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };

            modules = [
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    zjstatus = zjstatus.packages.${prev.system}.default;
                  })
                ];
              }
              ./hosts/khazad-dum/configuration.nix
              home-manager.nixosModules.home-manager
              lanzaboote.nixosModules.lanzaboote
              sops-nix.nixosModules.sops
              nixvim.nixosModules.default
            ];
          };
        };
    };
}
