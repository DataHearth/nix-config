{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    sops-nix.url = "github:Mic92/sops-nix";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    zjstatus.url = "github:dj95/zjstatus";

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
      zjstatus,
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
                  (self: super: {
                    jj-lsp = jj-lsp.packages.${system}.default;
                    zjstatus = zjstatus.packages.${system}.default;
                    # Official Anthropic Linux client, packaged locally from the
                    # upstream .deb (nixpkgs has no claude-desktop). The package
                    # forces Wayland/ozone itself — see packages/claude-desktop.nix.
                    claude-desktop = super.callPackage ./packages/claude-desktop.nix { };
                    claude-code = super.callPackage ./packages/claude-code.nix { };
                    spotify =
                      # Force Wayland (ozone). Spotify's own wrapper only adds these
                      # flags when NIXOS_OZONE_WL + WAYLAND_DISPLAY are set at launch,
                      # which doesn't take effect under Hyprland here — it stays on
                      # XWayland and bitmap-upscales to a blurry window on fractional
                      # scaling. Pass them unconditionally instead.
                      super.symlinkJoin {
                        name = "spotify-wayland";
                        paths = [ super.spotify ];
                        nativeBuildInputs = [ super.makeWrapper ];
                        postBuild = ''
                          wrapProgram $out/bin/spotify \
                            --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime=true"
                        '';
                        meta.mainProgram = "spotify";
                      };
                    # Temporary: afdko's otfautohint fails autohinting Cantarell's
                    # variable font (afdko#657), which breaks cantarell-fonts on all
                    # current nixos-unstable revs. It's uncached, and it's pulled into
                    # the system closure via fontconfig/nixos-help/steam, so its failure
                    # aborts the whole build. Skip the (optional) autohint step — the VF
                    # renders fine un-hinted. Drop once nixpkgs builds cantarell again.
                    cantarell-fonts = super.cantarell-fonts.overrideAttrs (old: {
                      postPatch = (old.postPatch or "") + ''
                        substituteInPlace scripts/make-variable-font.py \
                          --replace-fail 'subprocess.check_call(' 'print("cantarell: autohint skipped:",'
                      '';
                    });
                  })
                ];
              }
            ];
          };
        };
    };
}
