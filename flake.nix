{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    zjstatus.url = "github:dj95/zjstatus";

    nixvim = {
      url = "github:datahearth/nixvim-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
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
    nixos-hardware.url = "github:NixOS/nixos-hardware";
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
      sops-nix,
      home-manager,
      nixvim,
      nixGL,
      niri-flake,
      dms,
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
      homeConfigurations."Khazad-dum" =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ nixGL.overlay ];
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit awww;
          };

          modules = [
            { nixpkgs.config.allowUnfree = true; }
            sops-nix.homeManagerModules.sops
            elephant.homeManagerModules.default
            niri-flake.homeModules.niri
            dms.homeModules.dank-material-shell
            zen-browser.homeModules.beta
            nix-index-database.hmModules.nix-index
            ./hosts/khazad-dum/home-manager/home.nix
          ];
        };

      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
          Khazad-dum = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./hosts/khazad-dum/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              nixvim.nixosModules.default
              niri-flake.nixosModules.niri
              nixos-hardware.nixosModules.framework-16-7040-amd
              {
                home-manager.sharedModules = [
                  sops-nix.homeManagerModules.sops
                  elephant.homeManagerModules.default
                  dms.homeModules.dank-material-shell
                  zen-browser.homeModules.beta
                  nix-index-database.hmModules.nix-index
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
              nixvim.nixosModules.default
              niri-flake.nixosModules.niri
              {
                home-manager.sharedModules = [
                  sops-nix.homeManagerModules.sops
                  elephant.homeManagerModules.default
                  dms.homeModules.dank-material-shell
                  zen-browser.homeModules.beta
                  nix-index-database.hmModules.nix-index
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
