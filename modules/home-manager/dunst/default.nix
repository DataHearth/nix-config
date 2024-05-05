{ config, options, lib, pkgs, ... }:
with lib;
let
  cfg = config.hm.dunst;

  enable = mkEnableOption "dunst";
in {
  options.hm.dunst = { inherit enable; };

  config = mkIf cfg.enable {
    services.dunst = {
      enable = true;
      iconTheme = {
        package = pkgs.papirus-icon-theme;
        name = "Papirus";
      };
      settings = import ./config.nix { pkgs = pkgs; };
    };
  };
}
