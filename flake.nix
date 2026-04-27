{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
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
    jj-lsp = {
      url = "github:nilskch/jj-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      catppuccin,
      sops-nix,
      home-manager,
      nixos-hardware,
      zen-browser,
      nix-index-database,
      disko,
      lanzaboote,
      jj-lsp,
      claude-desktop,
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
              nixos-hardware.nixosModules.framework-16-7040-amd
              disko.nixosModules.disko
              lanzaboote.nixosModules.lanzaboote
              {
                home-manager.sharedModules = [
                  catppuccin.homeModules.catppuccin
                  sops-nix.homeManagerModules.sops
                  zen-browser.homeModules.beta
                  nix-index-database.homeModules.nix-index
                ];
              }
              {
                nixpkgs.overlays = [
                  claude-desktop.overlays.default
                  (self: super: {
                    jj-lsp = jj-lsp.packages.${system}.default;
                    # claude-code = super.callPackage ./packages/claude-code.nix { };
                  })
                ];
              }
            ];
          };
        };
    };
}
