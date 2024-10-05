{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    nixvim.url = "github:DataHearth/nixvim-config";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      home-manager,
      nixvim,
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

            specialArgs = {
              pkgs-unstable = import nixpkgs-unstable {
                inherit system;
                config.allowUnfree = true;
              };
            };

            modules = [
              (
                { pkgs-unstable, ... }:
                {
                  environment.systemPackages = with pkgs-unstable; [
                    nixvim.packages.${system}.default
                    nixfmt-rfc-style
                    gofumpt
                    stylua
                    golines
                    prettierd
                    rustfmt
                    taplo
                    ruff
                    eslint_d
                    yazi
                  ];
                }
              )
              ./hosts/khazad-dum/configuration.nix
              home-manager.nixosModules.home-manager
              lanzaboote.nixosModules.lanzaboote
              sops-nix.nixosModules.sops
            ];
          };
        };
      homeConfigurations.valinor =
        let
          system = "x86_64-linux";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          modules = [
            (
              { pkgs, ... }:
              {
                home.packages = with pkgs; [
                  nixvim.packages.${system}.default
                  nixfmt-rfc-style
                  gofumpt
                  stylua
                  golines
                  prettierd
                  rustfmt
                  taplo
                  ruff
                  eslint_d
                  yazi
                ];
              }
            )
            ./hosts/valinor/home.nix
          ];
        };
    };
}
