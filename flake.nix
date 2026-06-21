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
    claude-desktop = {
      # Temporary: PR #730 fixes the readRegistryValues() startup hang (#729) that
      # makes 1.13576.0/1.14271.0 wedge before showing a window. Pins app 1.14271.0.
      # Revert to "github:aaddrick/claude-desktop-debian" once #730 merges (then the
      # #718 patchedSrc block below can also be dropped — that fix is already upstream).
      url = "github:colonelpanic8/claude-desktop-debian/7dbe93b317f568d1eb97f9eb0c6d6d81437425d7";
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
                  (self: super: {
                    jj-lsp = jj-lsp.packages.${system}.default;
                    zjstatus = zjstatus.packages.${system}.default;
                    claude-desktop =
                      let
                        # Upstream bug aaddrick/claude-desktop-debian#718: the build-time
                        # asar patch (scripts/patches/config.sh) asserts the Claude app
                        # emits the --add-dir dispatch exactly once, but app v1.12603.1
                        # emits it twice, so the build aborts with
                        # "FATAL: --add-dir pattern matches 2 times (expected 1)".
                        # Patch the script to drop the count assertion (1 -> 1e9) and
                        # replace all occurrences (.replace -> .split/.join), then rebuild
                        # the flake's package from the patched source (its ./.. sourceRoot
                        # resolves to patchedSrc). Drop this once #718 lands upstream.
                        patchedSrc = super.runCommand "claude-desktop-debian-718-src" { } ''
                          cp -r ${claude-desktop} $out
                          chmod -R u+w $out
                          ${super.perl}/bin/perl -i -pe \
                            's/allMatches\.length > 1\)/allMatches.length > 1e9)/; s/code = code\.replace\(match\[0\], filtered\)/code = code.split(match[0]).join(filtered)/' \
                            $out/scripts/patches/config.sh
                        '';
                        node-pty = super.callPackage "${patchedSrc}/nix/node-pty.nix" { };
                        cdUnwrapped = super.callPackage "${patchedSrc}/nix/claude-desktop.nix" {
                          inherit node-pty;
                        };
                        cd = super.callPackage "${patchedSrc}/nix/fhs.nix" {
                          claude-desktop = cdUnwrapped;
                        };
                      in
                      # Force Wayland (ozone). The launcher's auto-detect leaves it on
                      # XWayland under Hyprland, which bitmap-upscales to a blurry window
                      # on fractional scaling. CLAUDE_USE_WAYLAND=1 makes it pass
                      # --ozone-platform=wayland (inherited into the FHS sandbox).
                      super.symlinkJoin {
                        name = "claude-desktop-wayland";
                        paths = [ cd ];
                        nativeBuildInputs = [ super.makeWrapper ];
                        postBuild = ''
                          wrapProgram $out/bin/claude-desktop \
                            --set CLAUDE_USE_WAYLAND 1
                        '';
                      };
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
                  })
                ];
              }
            ];
          };
        };
    };
}
