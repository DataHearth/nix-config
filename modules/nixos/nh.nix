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
    description = "Should a systemd timer clean-up every 2 days generations";
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
      extraArgs = "--keep-since 2d --keep 2";
    };
    flake = cfg.settings.flake;
  };
}
