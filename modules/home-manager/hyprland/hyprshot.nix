{
  config,
  lib,
  ...
}:
let
  cfg = config.home_modules.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprshot = {
      enable = true;
      saveLocation = "${config.home.homeDirectory}/Pictures/Screenshots";
    };
  };
}
