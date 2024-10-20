{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    nixvim.url = "github:DataHearth/nixvim-config";
    rust-overlay.url = "github:oxalica/rust-overlay";

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
    {
      nixpkgs,
      nixpkgs-unstable,
      sops-nix,
      home-manager,
      nixvim,
      lanzaboote,
      rust-overlay,
      ...
    }:
    let
      nixvim-extra =
        { system, pkgs }:
        with pkgs;
        [
          nixvim.packages.${system}.default

          # conform-nvim - Golang tools
          gofumpt
          golines
          go-tools

          # conform-nvim - Lua tools
          stylua

          # conform-nvim - Nix tools
          nixfmt-rfc-style

          # conform-nvim - JS/TS/HTML/CSS tools
          nodePackages.prettier
          eslint_d

          # conform-nvim - TOML tools
          taplo

          # conform-nvim - Python tools
          ruff
        ];
    in
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
                { pkgs-unstable, pkgs, ... }:
                {
                  nixpkgs.overlays = [ rust-overlay.overlays.default ];
                  environment.systemPackages =
                    (nixvim-extra {
                      inherit system;
                      pkgs = pkgs-unstable;
                    })
                    ++ [ pkgs.rust-bin.stable.latest.default ];
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
                nixpkgs.overlays = [ rust-overlay.overlays.default ];
                home.packages = nixvim-extra { inherit system pkgs; };
              }
            )
            ./hosts/valinor/home.nix
          ];
        };
    };
}
