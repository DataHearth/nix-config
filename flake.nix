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
    elephant = {
      url = "github:abenz1267/elephant";
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
      elephant,
      ...
    }:
    {
      homeConfigurations."Khazad-dum" =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs-unstable.legacyPackages.${system};
        in
        home-manager-unstable.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit nixGL;
          };

          modules = [
            { nixpkgs.config.allowUnfree = true; }
            elephant.homeManagerModules.default
            ./hosts/khazad-dum/home.nix
          ];
        };

      nixosConfigurations =
        let
          system = "x86_64-linux";
        in
        {
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
