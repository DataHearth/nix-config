{ config, lib, ... }:
let
  cfg = config.home_modules.swaync;

  enable = lib.mkEnableOption "swaync";
in
{
  options.home_modules.swaync = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    services.swaync = {
      enable = true;
      style = ./style.css;
    };
  };
}
