{
  lib,
  config,
  ...
}:
let
  cfg = config.home_modules.direnv;
in
{
  options.home_modules.direnv = {
    enable = lib.mkEnableOption "direnv with nix-direnv integration";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      mise.enable = true;
    };
  };
}
