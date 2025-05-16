{ config, lib, ... }:
let
  cfg = config.home_modules.zellij;

  enable = lib.mkEnableOption "zellij";
in
{
  options.home_modules.zellij = {
    inherit cfg enable;
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile = {
      "zellij/layouts/base.kdl".source = ./base_layout.kdl;
      "zellij/config.kdl".source = ./config.kdl;
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
