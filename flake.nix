{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    nixvim.url = "github:DataHearth/nixvim-config";
    rust-overlay.url = "github:oxalica/rust-overlay";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";

    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      home-manager-unstable,
      nixvim,
      lanzaboote,
      rust-overlay,
      zen-browser,
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

          # conform-nvim - SHish tools
          shfmt
          shellcheck
        ];
    in
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
                { pkgs-unstable, pkgs, ... }:
                {
                  nixpkgs.overlays = [ rust-overlay.overlays.default ];
                  environment.systemPackages =
                    (nixvim-extra {
                      inherit system;
                      pkgs = pkgs-unstable;
                    })
                    ++ [
                      pkgs.rust-bin.stable.latest.default
                    ];
                }
              )
              ./hosts/valinor/configuration.nix
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
            ];
          };
          khazad-dum = nixpkgs-unstable.lib.nixosSystem {
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
                    ++ [
                      pkgs.rust-bin.stable.latest.default
                      zen-browser.packages."${system}".default
                    ];
                }
              )
              ./hosts/khazad-dum/configuration.nix
              home-manager-unstable.nixosModules.home-manager
              lanzaboote.nixosModules.lanzaboote
              sops-nix.nixosModules.sops
            ];
          };
        };
    };
}
