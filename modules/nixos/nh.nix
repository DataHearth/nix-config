{ config, lib, ... }:
let
  cfg = config.nixos_modules.nh;

  enable = lib.mkEnableOption "nh";
  settings = lib.mkOption {
    type = lib.types.submodule {
      options = {
        inherit flake clean;
      };
    };
    description = "nh settings";
  };

  flake = lib.mkOption {
    type = lib.types.str;
    description = "Location of system/home-manager configuration";
  };
  clean = lib.mkOption {
    type = lib.types.bool;
    description = "Should a systemd timer prune old generations and gcroots";
    default = true;
  };
in
{
  options.nixos_modules.nh = {
    inherit enable settings;
  };

  config.programs.nh = lib.mkIf cfg.enable {
    enable = true;
    clean = lib.mkIf cfg.settings.clean {
      enable = true;
      # --keep-since covers gcroots, not just generations, and nix-direnv pins
      # each project's devShell through /nix/var/nix/gcroots/auto -> its
      # .direnv/flake-profile-*. A window shorter than the weekly timer
      # collects the devShell of every project left idle between two runs, so
      # the next `cd` into one pays a full `nix print-dev-env` and re-download.
      # 30d has to stay well above however long a project can go untouched.
      extraArgs = "--keep-since 30d --keep 2";
    };
    flake = cfg.settings.flake;
  };
}
