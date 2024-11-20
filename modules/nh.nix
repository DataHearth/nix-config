{ config, lib, ... }:
let
  cfg = config.nixos_modules.nh;

  enable = lib.mkEnableOption "nh";
  flake = lib.mkOption {
    type = lib.types.str;
    description = "Location of system/home-manager configuration";
    default = "${config.users.users.datahearth.home}/.config/nix-config";
  };
  clean = lib.mkOption {
    type = lib.types.bool;
    description = "Should a systemd timer clean-up every 2 days generations";
    default = true;
  };
in
{
  options.nixos_modules.nh = {
    inherit enable flake clean;
  };

  config.programs.nh = lib.mkIf cfg.enable {
    enable = true;
    clean = lib.mkIf cfg.clean {
      enable = true;
      extraArgs = "--keep-since 2d --keep 2";
    };
    flake = cfg.flake;
  };
}
