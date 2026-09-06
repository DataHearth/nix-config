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
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately not following our nixpkgs: qmd vendors its node_modules as a
    # fixed-output derivation whose hash was computed with the bun from its own
    # pin. A different bun rewrites that tree and the build fails on a hash
    # mismatch we cannot fix from here.
    qmd.url = "github:tobi/qmd";
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
      qmd,
      devshell,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = devshell.legacyPackages.${system}.mkShell {
        name = "nix-config";

        packages = with pkgs; [
          nh
          nvd
          nix-output-monitor
          nix-tree
          nixfmt-tree
          statix
          deadnix
          sops
          ssh-to-age
          age
          jujutsu
          jj-lsp.packages.${system}.default
          fd
          shellcheck
          shfmt
        ];

        commands = [
          {
            name = "fmt";
            category = "checks";
            help = "Format the Nix files in the repo (nixfmt via treefmt)";
            command = ''treefmt "$@"'';
          }
          {
            name = "lint";
            category = "checks";
            help = "Run statix, deadnix and shellcheck over the repo";
            command = ''
              # Relative targets, not "$PRJ_ROOT": statix matches -i globs
              # against the paths its walker yields, so an absolute target makes
              # `.direnv` stop matching and it parses every input source behind
              # .direnv/flake-inputs -- 267k files of nixpkgs, 19s instead of
              # 0.15s. deadnix and fd skip .direnv on their own (hidden dir).
              cd "$PRJ_ROOT"
              statix check -i .direnv .
              deadnix --fail .
              # -s bash: update.sh runs under a `#!/usr/bin/env nix` shebang and
              # the claude-code hooks are nix-embedded fragments with none at
              # all, so shellcheck cannot infer the dialect from the file.
              fd -e sh . -X shellcheck -s bash
            '';
          }
          {
            name = "check";
            category = "checks";
            help = "Dry-run build of the khazad-dum system closure";
            command = ''
              nix build --dry-run \
                "$PRJ_ROOT#nixosConfigurations.khazad-dum.config.system.build.toplevel" "$@"
            '';
          }
          {
            name = "update-packages";
            category = "packages";
            help = "Refresh the locally packaged apps under packages/";
            command = ''"$PRJ_ROOT/packages/update.sh" "''${@:-all}"'';
          }
        ];
      };

      nixosConfigurations = {
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
                qmd.homeModules.default
              ];
            }
            {
              nixpkgs.overlays = [
                (_self: super: {
                  # hyprlock 0.9.6 never exits after a successful password
                  # unlock when it was started into a suspend and resumed
                  # (hyprwm/hyprlock#1055): CPam::terminate() joins a PAM
                  # thread still blocked in pam_authenticate(). The process
                  # lives on rendering nothing, hyprlock.service stays active,
                  # lock.target with it, and every later lock request is a
                  # no-op. Fixed upstream by #1059 (2026-08-07), unreleased.
                  # Drop once nixpkgs ships a hyprlock newer than 0.9.6 --
                  # the patch will refuse to apply at that point.
                  hyprlock = super.hyprlock.overrideAttrs (old: {
                    patches = (old.patches or [ ]) ++ [
                      (super.fetchpatch {
                        name = "hyprlock-pam-fix-deadlock-on-terminate.patch";
                        url = "https://github.com/hyprwm/hyprlock/commit/1f337a4713e981e75ad4912cbbb5c3dccb7b6717.patch";
                        hash = "sha256-i/vawI+dIjGGl2nWfSMBYSulaY3YOYq3j/dtrQWbqKU=";
                      })
                    ];
                  });
                  jj-lsp = jj-lsp.packages.${system}.default;
                  # qmd's wrapper hard-`--set`s LD_LIBRARY_PATH, so the Vulkan
                  # loader and the NixOS driver path are invisible to the
                  # prebuilt node-llama-cpp Vulkan addon (`libvulkan.so.1 =>
                  # not found`) and llama.cpp silently falls back to CPU.
                  # Prepending both is enough — qmd's own `auto` probe then
                  # picks the 780M, cutting a full vault embed from ~2m15s to
                  # ~50s. An outer wrapper cannot fix this: the inner wrapper
                  # would overwrite the variable again.
                  qmd = qmd.packages.${system}.default.overrideAttrs (old: {
                    postFixup = (old.postFixup or "") + ''
                      substituteInPlace $out/bin/qmd \
                        --replace-fail "export LD_LIBRARY_PATH='" \
                          "export LD_LIBRARY_PATH='${
                            super.lib.makeLibraryPath [
                              super.vulkan-loader
                              "/run/opengl-driver"
                            ]
                          }:"
                    '';
                  });
                  # Official Anthropic Linux client, packaged locally from the
                  # upstream .deb (nixpkgs has no claude-desktop). The package
                  # forces Wayland/ozone itself — see packages/claude-desktop.nix.
                  claude-desktop = super.callPackage ./packages/claude-desktop.nix { };
                  # Track claude-code releases independently of the nixpkgs
                  # channel: the derivation reads version + per-platform
                  # checksums from a manifest, so pointing it at a local copy
                  # (refreshed by ./packages/update.sh claude-code) bumps the
                  # package without waiting on a channel roll.
                  claude-code = super.claude-code.override {
                    manifest = super.lib.importJSON ./packages/claude-code-manifest.json;
                  };
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
                  # fw-fanctrl polls `ectool temps all` once a second (the
                  # sleep(1) in FanController.run; fanSpeedUpdateFrequency only
                  # gates the duty write, not the read). ectool prints a
                  # "Sensor N disabled" line per disabled sensor on stderr, and
                  # this is the one ectool call that does not redirect it --
                  # is_on_ac right below it passes stderr=DEVNULL. The daemon's
                  # own --silent does not reach a subprocess's inherited stderr,
                  # so journald logs one line per second under the unit: 67% of
                  # this machine's journal. Still unfixed on upstream main,
                  # where the same asymmetry survived the port to framework_tool.
                  fw-fanctrl = super.fw-fanctrl.overrideAttrs (old: {
                    postPatch = (old.postPatch or "") + ''
                      substituteInPlace src/fw_fanctrl/hardwareController/EctoolHardwareController.py \
                        --replace-fail '"ectool temps all",' '"ectool temps all", stderr=subprocess.DEVNULL,'
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
