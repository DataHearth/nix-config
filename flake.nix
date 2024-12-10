{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    nixvim = {
      url = "github:DataHearth/nixvim-config";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
      rust-overlay,
      zen-browser,
      ...
    }:
    {
      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
          valinor = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              pkgs-unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };

            modules = [
              (
                { pkgs, ... }:
                {
                  nixpkgs.overlays = [ rust-overlay.overlays.default ];
                  environment.systemPackages = [
                    pkgs.rust-bin.stable.latest.default
                  ];
                }
              )
              ./hosts/valinor/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              nixvim.nixosModules.default
            ];
          };
          khazad-dum = nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              pkgs-unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };

            modules = [
              (
                { pkgs, ... }:
                {
                  nixpkgs.overlays = [
                    rust-overlay.overlays.default
                  ];
                  environment.systemPackages = [
                    pkgs.rust-bin.stable.latest.default
                    zen-browser.packages."${system}".default
                  ];
                }
              )
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
