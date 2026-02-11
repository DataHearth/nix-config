{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    zjstatus.url = "github:dj95/zjstatus";

    nixvim = {
      url = "github:datahearth/nixvim-config";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixGL = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    elephant = {
      url = "github:abenz1267/elephant";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      nixpkgs-unstable,
      sops-nix,
      home-manager-unstable,
      nixvim,
      nixGL,
      niri-flake,
      dms,
      elephant,
      awww,
      nixos-hardware,
      zen-browser,
      ...
    }:
    {
      homeConfigurations."Khazad-dum" =
        let
          pkgs = import nixpkgs-unstable {
            system = "x86_64-linux";
            overlays = [ nixGL.overlay ];
          };
        in
        home-manager-unstable.lib.homeManagerConfiguration {
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
            ./hosts/khazad-dum/home-manager/home.nix
          ];
        };

      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
          Khazad-dum = nixpkgs-unstable.lib.nixosSystem {
            inherit system;

            modules = [
              ./hosts/khazad-dum/configuration.nix
              home-manager-unstable.nixosModules.home-manager
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
                ];
                home-manager.extraSpecialArgs = {
                  inherit awww;
                };
              }
            ];
          };

          Valinor = nixpkgs-unstable.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit elephant;
            };

            modules = [
              ./hosts/valinor/configuration.nix
              home-manager-unstable.nixosModules.home-manager
              sops-nix.nixosModules.sops
              nixvim.nixosModules.default
            ];
          };
        };
    };
}
