{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant = {
      url = "github:abenz1267/elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
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
      catppuccin,
      sops-nix,
      home-manager,
      niri-flake,
      elephant,
      awww,
      nixos-hardware,
      zen-browser,
      nix-index-database,
      disko,
      lanzaboote,
      ...
    }:
    {
      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
          khazad-dum = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./hosts/khazad-dum/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              niri-flake.nixosModules.niri
              nixos-hardware.nixosModules.framework-16-7040-amd
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              {
                home-manager.sharedModules = [
                  catppuccin.homeModules.catppuccin
                  sops-nix.homeManagerModules.sops
                  elephant.homeManagerModules.default
                  zen-browser.homeModules.beta
                  nix-index-database.homeModules.nix-index
                ];
                home-manager.extraSpecialArgs = {
                  inherit awww;
                };
              }
            ];
          };

          Valinor = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./hosts/valinor/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              niri-flake.nixosModules.niri
              {
                home-manager.sharedModules = [
                  catppuccin.homeModules.catppuccin
                  sops-nix.homeManagerModules.sops
                  elephant.homeManagerModules.default
                  zen-browser.homeModules.beta
                  nix-index-database.homeModules.nix-index
                ];
                home-manager.extraSpecialArgs = {
                  inherit awww;
                };
              }
            ];
          };
        };
    };
}
