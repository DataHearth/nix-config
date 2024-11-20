{ config, lib, ... }:
let
  cfg = config.hm.swaync;

  enable = lib.mkEnableOption "swaync";
in
{
  options.hm.swaync = {
    inherit enable;
  };

  config = lib.mkIf cfg.enable {
    services.swaync = {
      enable = true;
      style = ./style.css;
    };
  };
}
