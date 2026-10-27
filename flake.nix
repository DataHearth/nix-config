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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
    inputs@{
      flake-parts,
      nixpkgs,
      catppuccin,
      sops-nix,
      home-manager,
      nixos-hardware,
      zen-browser,
      nix-index-database,
      disko,
      lanzaboote,
      qmd,
      devshell,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        systems = [ "x86_64-linux" ];
        imports = [ devshell.flakeModule ];

        perSystem = { pkgs, inputs', ... }: {
          devshells.default = {
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
              inputs'.jj-lsp.packages.default
              fd
              jq
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
                name = "test-hooks";
                category = "checks";
                help = "Run the table tests for the Claude Code PreToolUse guards";
                command = ''bash "$PRJ_ROOT/modules/home-manager/claude-code/nix-run-guard-test.sh"'';
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
        };

        flake.nixosConfigurations = {
          khazad-dum = withSystem "x86_64-linux" (
            { inputs', ... }:
            nixpkgs.lib.nixosSystem {
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
                      jj-lsp = inputs'.jj-lsp.packages.default;
                      # qmd's wrapper hard-`--set`s LD_LIBRARY_PATH, so the Vulkan
                      # loader and the NixOS driver path are invisible to the
                      # prebuilt node-llama-cpp Vulkan addon (`libvulkan.so.1 =>
                      # not found`) and llama.cpp silently falls back to CPU.
                      # Prepending both is enough — qmd's own `auto` probe then
                      # picks the 780M, cutting a full vault embed from ~2m15s to
                      # ~50s. An outer wrapper cannot fix this: the inner wrapper
                      # would overwrite the variable again. The assert fails once
                      # upstream's wrapper adds vulkan itself; then delete this.
                      qmd = inputs'.qmd.packages.default.overrideAttrs (
                        old:
                        assert !super.lib.hasInfix "vulkan" old.installPhase;
                        {
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
                        }
                      );
                      # Official Anthropic Linux client, packaged locally from the
                      # upstream .deb (nixpkgs has no claude-desktop). The package
                      # forces Wayland/ozone itself — see packages/claude-desktop.nix.
                      claude-desktop = super.callPackage ./packages/claude-desktop.nix { };
                      # Track claude-code releases independently of the nixpkgs
                      # channel: the derivation reads version + per-platform
                      # checksums from a manifest, so pointing it at a local copy
                      # (refreshed by ./packages/update.sh claude-code) bumps the
                      # package without waiting on a channel roll.
                      #
                      # The wrapper's `--prefix LD_LIBRARY_PATH : alsa-lib` (for the
                      # embedded voice-mode audio-capture.node) leaks into every Bash
                      # tool call, so devshells on an older glibc can't start
                      # ffmpeg/chromium (`GLIBC_2.43' not found). Strip it and accept
                      # that voice mode can't load libasound (unused here).
                      # Don't swap in an RPATH instead (NixOS/nixpkgs#569098's
                      # approach): from 2.1.302 any `patchelf --add-rpath` on the Bun
                      # binary makes it segfault on start; only --set-interpreter is
                      # safe. The assert fails once upstream drops the prefix.
                      claude-code =
                        (super.claude-code.override {
                          manifest = super.lib.importJSON ./packages/claude-code-manifest.json;
                        }).overrideAttrs
                          (
                            old:
                            let
                              ldPrefix = "--prefix LD_LIBRARY_PATH : ${super.lib.makeLibraryPath [ super.alsa-lib ]} \\\n";
                              installPhase = super.lib.replaceStrings [ ldPrefix ] [ "" ] old.installPhase;
                            in
                            assert installPhase != old.installPhase;
                            {
                              inherit installPhase;
                            }
                          );
                      spotify =
                        # Force Wayland (ozone). Spotify's own wrapper passes no ozone
                        # flags (it only unsets DISPLAY under NIXOS_OZONE_WL=1), so
                        # it stays on XWayland and bitmap-upscales to a blurry window
                        # on fractional scaling. Pass them unconditionally instead.
                        # The assert fails once nixpkgs' wrapper passes them itself;
                        # then delete this.
                        assert !super.lib.hasInfix "ozone-platform" super.spotify.fixupPhase;
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
                      # The replacement can't detect an upstream fix that puts
                      # stderr= on its own line: the pattern would still match and
                      # inject a duplicate keyword, a SyntaxError only at daemon
                      # start. So the build refuses once the call carries stderr.
                      fw-fanctrl = super.fw-fanctrl.overrideAttrs (old: {
                        postPatch = (old.postPatch or "") + ''
                          f=src/fw_fanctrl/hardwareController/EctoolHardwareController.py
                          if sed -n '/"ectool temps all",/,/)/p' "$f" | grep -q stderr; then
                            echo "fw-fanctrl: upstream now redirects stderr of ectool temps; drop the override" >&2
                            exit 1
                          fi
                          substituteInPlace "$f" \
                            --replace-fail '"ectool temps all",' '"ectool temps all", stderr=subprocess.DEVNULL,'
                        '';
                      });
                    })
                  ];
                }
              ];
            }
          );
        };
      }
    );
}
